--- A Pandoc filter to recursively include sub-documents.

--- This filter's version
local FILTER_VERSION            = "0.4.1"

--- The class for `Div` elements to see their contents replaced by the ones
-- of the sources specified with @{INCLUDE_SRC_ATTR} and @{INCLUDE_FORMAT_ATTR}.
local INCLUDE_DOC_CLASS         = "include-doc"
--- The attribute for inclusion `Div`s that specifies the format of the document to be included.
local INCLUDE_FORMAT_ATTR       = "include-format"
--- The attribute for inclusion `Div`s that specifies the source of the document to be included.
local INCLUDE_SRC_ATTR          = "include-src"
--- The class for `Div` elements (that already have the @{INCLUDE_DOC_CLASS})
-- to make the filter store also the metadata of the included documents.
local INCLUDE_DOC_META_CLASS    = "include-meta"
--- The class to add to `Div` elements that specify a sub-document inclusion,
-- when the inclusion succeeds.
local INCLUDE_INCLUDED_CLASS    = "included"
--- The attribute that carries the SHA-1 of the imported contents, when the inclusion succeeds.
local INCLUDE_SHA1_ATTR         = "include-sha1"
--- The metadata key in the main document to tell the filter to store every imported document's
-- metadata among the metadata of the resulting document.
local INCLUDE_DOC_SUB_META_FLAG = "include-sub-meta"
--- the variable to use in the CLI to tell the filter to include sub-docs metadata
local INCLUDE_DOC_SUB_META_VAR  = "include_sub_meta"
--- The metadata key of the resulting document, carrying the metadata of imported documents.
local INCLUDE_DOC_SUB_META_KEY  = "included-sub-meta"
--- The metadata key (in the resulting doc) that stores the id of the root document contents
local ROOT_ID_META_KEY          = "root_id"
--- The metadata key (in the resulting doc) that stores the format of the root document contents
local ROOT_FORMAT_META_KEY      = "root_format"
--- The metadata key (in the resulting doc) that stores the source of the root document contents
local ROOT_SRC_META_KEY         = "root_src"
--- The metadata key (in the resulting doc) that stores the SHA1 of the root document contents
local ROOT_SHA1_META_KEY        = "root_sha1"
--- The attribute with the identifier that this filter assigns to an imported document.
-- It's equal to the sub-key of @{INCLUDE_DOC_SUB_META_KEY} that contains the sub-document metadata
-- in the resulting document.
local INCLUDE_ID_ATTR           = "included-id"
--- The prefix used for the values of the @{INCLUDE_ID_ATTR} attribute.
local INCLUDE_ID_PREFIX         = "included_"

---@diagnostic disable-next-line: undefined-global
local PANDOC_STATE              = PANDOC_STATE
---@diagnostic disable-next-line: undefined-global
local PANDOC_WRITER_OPTIONS     = PANDOC_WRITER_OPTIONS
local VARIABLES                 = PANDOC_WRITER_OPTIONS.variables
---@diagnostic disable-next-line: undefined-global
local pandoc                    = pandoc
local pandoc_path               = pandoc.path
local string_match              = string.match
local string_gsub               = string.gsub
local table_insert              = table.insert
local table_concat              = table.concat

--- The current source being parsed for documents inclusion.
local current_src               = PANDOC_STATE.input_files[1] or '__MAIN__'
--- An array of tables representing the included sources (documents).
--
-- Every element of @{includes} has these fields:
--@field id the id of the imported document
--@field index the index in the @{includes} array
--@field src the source (its URI or path)
--@field subs the indices (in @{includes}) of the sources included by this source
local includes                  = {}

-- the id of the root document
local root_id                   = "root"
-- the src of the root document
local root_src                  = current_src
-- the format of the root document
local root_format               = current_src and pandoc.format.from_path(current_src) or ''
-- the SHA1 of the root document contents
local root_sha1

--- When it's `true`, the included documents' metadata are imported
-- under the main document's metadata at the key specified by @{INCLUDE_DOC_SUB_META}
local include_all_meta          = VARIABLES[INCLUDE_DOC_SUB_META_VAR] or false

local function logging_info(...)
end
local function logging_warning(w)
  io.stderr:write('(W) include-doc: ' .. w .. '\n')
end
local function logging_error(e)
  io.stderr:write('(E) include-doc: ' .. e .. '\n')
end
local logging
if pcall(require, "logging") then
  logging = require("logging")
end
if logging then
  logging_info = logging.info
  logging_warning = logging.warning
  logging_error = logging.error
end

if include_all_meta then
  logging_warning('including metadata of included sub documents')
end

--- Check whether a Pandoc item with an Attr has a class.
--@param elem the Block or Inline with an Attr
--@param class the class to look for among the ones in Attr's classes
local function hasClass(elem, class)
  if elem and elem.attr and elem.attr.classes then
    local classes = elem.attr.classes
    for i = 1, #classes do
      if classes[i] == class then
        return true
      end
    end
  end
  return false
end

--- Fetch the contents of a source as a Pandoc document.
--@param src the source to fetch
--@returns the fetched document
--See [pandoc.mediabag.fetch](https://pandoc.org/lua-filters.html#pandoc.mediabag.fetch).
local function srcToMarkup(src)
  local status, mime, content = xpcall(pandoc.mediabag.fetch, function(err)
    logging_warning('source "' .. src .. '" not included: ' .. tostring(err))
  end, src)
  return content
end

--- Looks for a source in the @{includes} array and appends it if it's not there yet.
--@param src the source to look for
--@returns the index of the source in the @{includes} array and the element in the same array
local function indexOfIncluded(src)
  for j = 1, #includes do
    if includes[j].src == src then
      return j
    end
  end
  local index = #includes + 1
  local incl =
  {
    index = index,
    src = src,
    subs = {},
  }
  table_insert(includes, incl)
  return index, incl
end

--- Normalize an id (lowercase, no special chars, at least one letter, don't start with a number)
local function normalizeId(id)
  if id then
    local nid = string.lower(id)
    nid = string_gsub(nid, "[^_0-9a-z-]+", "_")
    if string_match(nid, "^[0-9]") then
      nid = "_" .. nid
    end
    if not string_match(nid, "[_a-z]") then
      return nil
    end
    nid = string_gsub(nid, "_$", "")
    return nid
  end
end

--- Looks for the internal id of an imported source.
--@param src the source to look for.
--@returns the id and the element in the @{includes} array (see also @{indexOfIncluded}).
local function idOfIncluded(src)
  local index = indexOfIncluded(src)
  local incl = includes[index]
  local id = incl.id
  if not id then
    if incl.src then
      local base = pandoc_path.split_extension(incl.src)
      id = normalizeId(pandoc_path.filename(base))
    end
    if id then
      -- check whether the id is already used with a different src
      for i = 1, index - 1 do
        if includes[i].id == id and includes[i].src ~= incl.src then
          id = id .. "_" .. tostring(index)
          break
        end
      end
    end
    incl.id = id or INCLUDE_ID_PREFIX .. tostring(index)
  end
  return incl.id, incl
end

--- A textual representation of the array that stores references to all the included sources.
local function includesToString()
  local log_includes = {}
  for i = 1, #includes do
    local inc = includes[i]
    table_insert(log_includes, inc.index .. ':' .. inc.src .. '(' .. table_concat(inc.subs, ',') .. ')')
  end
  return 'includes: ' .. table_concat(log_includes, ', ')
end

--- A textual representation of a closed loop of documents' inclusions.
--@param cycle an array of the indices of the sources thaf form the closed loop
local function cycleToString(cycle)
  local str_cycle = {}
  if #cycle > 1 then
    for i = 1, #cycle do
      table_insert(str_cycle, includes[cycle[i]].src)
    end
    table_insert(str_cycle, includes[cycle[1]].src)
  end
  return table_concat(str_cycle, ' => ')
end

--- Record in the @{includes} array the fact that a source includes another one.
--@param parent_src the source including another one
--@param child_src the source included in `parent_src`
local function addToInclusions(parent_src, child_src)
  local parent_src_index = indexOfIncluded(parent_src)
  local child_src_index = indexOfIncluded(child_src)
  local subs = includes[parent_src_index].subs
  local found = false
  for i = 1, #subs do
    if subs[i] == child_src_index then
      found = true
      break
    end
  end
  if not found then
    table_insert(includes[parent_src_index].subs, child_src_index)
  end
  -- logging_info('addToInclusions, '..includesToString())
end

--- Checks whether the index of a source is already in a chain of documents' inclusions.
-- This function is used to test possibile circular references in the sources' inclusions.
--@param chain a list of indices of the sources in the @{includes} array
--@param elem the index of a source
--@returns true if elem is present in chain and its first index
local function isInChain(chain, elem)
  for j = 1, #chain do
    if chain[j] == elem then
      return true, j
    end
  end
  return false, 0
end

--- A clone of a chain (an array of indices) with an appended index.
--@param chain a chain (array) of the indices of included sources in the @{includes} array.
--@param elem the index to append to the chain
--@returns a copy of the chain with elem appended.
local function longerChain(chain, elem)
  local newChain = {}
  for i = 1, #chain do
    table_insert(newChain, chain[i])
  end
  table_insert(newChain, elem)
  return newChain
end

--- Checks whether a chain of included documents is cyclic (has circular references that
-- would create a closed, infinite loop of inclusions).
--@param chain a list of indices of included documents in the @{includes} array.
--@param depth since this function is recursive, this argument tracks the depth of recursion (it's only for debugging purposes)
--@returns `false` or `true` and the cycle it found (it's a list of indices in the @{includes} array).
local function isCyclic(chain, depth)
  ---@diagnostic disable-next-line: redefined-local
  local chain, depth = chain or { 1 }, depth or 1
  local subs = includes[chain[#chain]].subs or {}
  -- local prefix = "isCyclic(depth=" .. depth .. ")"
  -- logging_info(prefix .. ", " .. includesToString())
  -- logging_info(prefix .. ", chain: " .. table_concat(chain, ' => '))
  -- logging_info("subs of " .. chain[#chain] .. ": " .. table_concat(subs, ", "))
  if #subs > 0 then
    for j = 1, #subs do
      local in_chain, index_in_chain = isInChain(chain, subs[j])
      if in_chain then
        local cycle = {}
        for k = index_in_chain, #chain do
          table_insert(cycle, chain[k])
        end
        return true, cycle
      else
        local longer = longerChain(chain, subs[j])
        local is_cyclic, cycle = isCyclic(longer, depth + 1)
        if is_cyclic then
          return true, cycle
        end
      end
    end
  end
  return false
end

--- Checks whether a `Div` is meant to include contents from an external source
--@param div the `Div` block to check
--@returns `false` or `true`, the source, its format and a boolean that is true when INCLUDE_DOC_CLASS is found
local function isInclusionDiv(div, log)
  if not div.tag == "Div" then
    return false
  end
  local src = div.attributes[INCLUDE_SRC_ATTR]
  local has_include_doc_class = hasClass(div, INCLUDE_DOC_CLASS)
  if src then
    if log then
      logging_info('Div has a "' .. INCLUDE_SRC_ATTR .. '" attribute, but no "' .. INCLUDE_DOC_CLASS .. '" class')
    end
    local format = div.attributes[INCLUDE_FORMAT_ATTR] or pandoc.format.from_path(src)
    if format then
      return true, src, format, has_include_doc_class
    elseif log then
      logging_warning('format not found for source "' .. src .. '"')
    end
  elseif log and has_include_doc_class then
    logging_warning('Div has "' .. INCLUDE_DOC_CLASS .. '" class, but no valid "' .. INCLUDE_SRC_ATTR .. '" attribute')
  end
  return false
end

--- A Pandoc filter to record all the inclusions of other sources (sub-documents).
-- Div blocks are checked to see whether they are meant to include sub-documents.
local find_inclusions_filter = {

  Pandoc = function(doc)
    root_sha1 = pandoc.utils.sha1(tostring(doc.blocks))
  end,

  Div = function(div)
    local is_inclusion_div, src, format = isInclusionDiv(div, true)
    if is_inclusion_div then
      if format and src then
        -- logging_info('find_inclusions_filter, found "' .. src .. '"')
        addToInclusions(current_src, src)
      end
    end
  end,
}

--- The filter that does the actual inclusion through `Div` elements with a particular class.
local include_doc_filter = {
  traverse = 'topdown',

  Pandoc = function(doc)
    logging_info("pandoc include-doc.lua filter, version " .. FILTER_VERSION)
  end,

  Meta = function(meta)
    if meta[INCLUDE_DOC_SUB_META_FLAG] then
      logging_info(
        '"'
        .. INCLUDE_DOC_SUB_META_FLAG
        .. "\" set to true in main document's metadata => all the included documents' metadata will be stored under the key \""
        .. INCLUDE_DOC_SUB_META_KEY
        .. '"'
      )
      include_all_meta = true
    end
  end,

  Div = function(div)
    local is_inclusion_div, src, format, has_include_doc_class = isInclusionDiv(div)
    if is_inclusion_div then
      if format and src then
        -- logging_info('INCLUDING ' .. src .. ', FORMAT=' .. format)
        local markup = srcToMarkup(src)
        if markup then
          local doc = pandoc.read(markup, format, { standalone = true })
          local meta, blocks = doc.meta, doc.blocks
          if blocks then
            local included_id, incl = idOfIncluded(src)
            local do_include_src_meta = include_all_meta or hasClass(div, INCLUDE_DOC_META_CLASS)
            if do_include_src_meta and meta then
              meta.src = src
              incl.meta = meta
              logging_info(
                '"'
                .. INCLUDE_DOC_META_CLASS
                .. "\" class found importing \"" .. src .. "\" => its metadata will be stored under the key \""
                .. INCLUDE_DOC_SUB_META_KEY .. '/' .. incl.id .. '"'
              )
            end
            local identifier = div.identifier
            local classes = div.classes
            table_insert(classes, INCLUDE_INCLUDED_CLASS)
            if not has_include_doc_class then
              table_insert(classes, INCLUDE_DOC_CLASS)
            end
            classes:sort()
            local attributes = div.attributes
            attributes[INCLUDE_SHA1_ATTR] = pandoc.utils.sha1(tostring(blocks))
            attributes[INCLUDE_ID_ATTR] = included_id
            local newDiv = pandoc.Div(blocks, pandoc.Attr(identifier, classes, attributes))
            current_src = src
            pandoc.walk_block(newDiv, find_inclusions_filter)
            local is_cyclic, cycle = isCyclic()
            if is_cyclic then
              logging_error('ERROR, circular reference: ' .. cycleToString(cycle))
              return
            end
            return newDiv
          end
        end
      end
    end
  end
}

--- A filter to store the metadata of the imported documents in the resulting doc.
local store_included_metas = {
  Meta = function(meta)
    local sub_meta = pandoc.MetaList({})
    for i = 1, #includes do
      local id = includes[i].id
      local incl_meta = includes[i].meta
      if incl_meta then
        sub_meta:insert({ [id] = pandoc.MetaMap(incl_meta) })
      end
    end
    if #sub_meta > 0 then
      meta[INCLUDE_DOC_SUB_META_KEY] = sub_meta
    end
    meta[ROOT_ID_META_KEY] = pandoc.MetaString(root_id)
    meta[ROOT_FORMAT_META_KEY] = pandoc.MetaString(root_format)
    meta[ROOT_SRC_META_KEY] = pandoc.MetaString(root_src)
    meta[ROOT_SHA1_META_KEY] = pandoc.MetaString(root_sha1)
    return meta
  end
}

return { find_inclusions_filter, include_doc_filter, store_included_metas }
