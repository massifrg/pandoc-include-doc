--- A Pandoc filter to recursively include sub-documents.

---@module "pandoc-types-annotations"

local PANDOC_STATE              = PANDOC_STATE
local PANDOC_WRITER_OPTIONS     = PANDOC_WRITER_OPTIONS or {}
local VARIABLES                 = PANDOC_WRITER_OPTIONS.variables or {}
local pandoc                    = pandoc
local pandoc_path               = pandoc.path
local string_len                = string.len
local string_match              = string.match
local string_gsub               = string.gsub
local string_sub                = string.sub
local table_concat              = table.concat
local table_insert              = table.insert
local table_sort                = table.sort

local script_dir                = pandoc_path.directory(PANDOC_SCRIPT_FILE)
package.path                    = package.path
    .. ";" .. script_dir .. '/?.lua;'
    .. script_dir .. '/?/init.lua'
local log_info                  = pandoc.log.info
local log_warn                  = pandoc.log.warn

local common                    = require("include-common")

local FILTER_VERSION            = common.FILTER_VERSION
local INCLUDE_DOC_CLASS         = common.INCLUDE_DOC_CLASS
local INCLUDE_FORMAT_ATTR       = common.INCLUDE_FORMAT_ATTR
local INCLUDE_SRC_ATTR          = common.INCLUDE_SRC_ATTR
local INCLUDE_FILTERS_ATTR      = common.INCLUDE_FILTERS_ATTR
local INCLUDE_DOC_META_CLASS    = common.INCLUDE_DOC_META_CLASS
local INCLUDE_INCLUDED_CLASS    = common.INCLUDE_INCLUDED_CLASS
local INCLUDE_SHA1_ATTR         = common.INCLUDE_SHA1_ATTR
local INCLUDE_DOC_SUB_META_FLAG = common.INCLUDE_DOC_SUB_META_FLAG
local INCLUDE_DOC_SUB_META_VAR  = common.INCLUDE_DOC_SUB_META_VAR
local INCLUDE_DOC_SUB_META_KEY  = common.INCLUDE_DOC_SUB_META_KEY
local ROOT_ID_META_KEY          = common.ROOT_ID_META_KEY
local ROOT_FORMAT_META_KEY      = common.ROOT_FORMAT_META_KEY
local ROOT_SRC_META_KEY         = common.ROOT_SRC_META_KEY
local ROOT_SHA1_META_KEY        = common.ROOT_SHA1_META_KEY
local INCLUDE_ID_ATTR           = common.INCLUDE_ID_ATTR
local INCLUDE_ID_PREFIX         = common.INCLUDE_ID_PREFIX
local customFormats             = common.customFormats
local hasClass                  = common.hasClass
local isInclusionDiv            = common.isInclusionDiv
local filtersFromAttribute      = common.filtersFromAttribute

local SRC_STDIN                 = '__STDIN__'

---Compute the id of a document from its source, removing protocol, path and extension.
---@param src? string
---@return string|nil
local function idFromSrc(src)
  if src then
    local filename = pandoc_path.filename(src)
    local id = pandoc_path.split_extension(filename)
    return id
  end
end

--- The current source being parsed for documents inclusion.
local current_src = PANDOC_STATE.input_files[1]
if current_src == '-' then
  current_src = nil
end

---@class IncludeDoc
---@field id string|nil The document id.
---@field index integer The index in the `includes` array.
---@field src string The document source (URI or path).
---@field subs integer[] The indexes in the `includes` array of its included sub-documents.
---@field meta table|nil The `Meta` object of the included document.

--- An array of tables representing the included sources (documents).
---@type IncludeDoc[]
local includes         = {}

-- the id of the root document
local root_id          = idFromSrc(current_src) or "root"
-- the src of the root document
local root_src         = current_src or SRC_STDIN
-- the format of the root document
local root_format      = current_src and pandoc.format.from_path(current_src) or ''
-- the SHA1 of the root document contents
local root_sha1

--- When it's `true`, the included documents' metadata are imported
-- under the main document's metadata at the key specified by @{INCLUDE_DOC_SUB_META}
local include_all_meta = VARIABLES[INCLUDE_DOC_SUB_META_VAR] or false

if include_all_meta then
  log_warn('including metadata of included sub documents')
end

---Fetch the contents of a source as a Pandoc document.
---See [pandoc.mediabag.fetch](https://pandoc.org/lua-filters.html#pandoc.mediabag.fetch).
---@param src string The source to fetch.
---@return string|nil content # The file contents or nil when not successful.
local function srcToMarkup(src)
  local status, mime, content = xpcall(pandoc.mediabag.fetch, function(err)
    log_warn('source "' .. src .. '" not included: ' .. tostring(err))
  end, src)
  return content
end

---Looks for a source in the @{includes} array and appends it if it's not there yet.
---@param src string The source (URI or path) to look for.
---@return integer index # The index of the source in the @{includes} array and the element in the same array.
---@return IncludeDoc|nil # A new included document with that source when it is not found.
local function indexOfIncluded(src)
  for j = 1, #includes do
    if includes[j].src == src then
      return j
    end
  end
  local index = #includes + 1
  ---@type IncludeDoc
  local incl =
  {
    index = index,
    src = src,
    subs = {},
  }
  table_insert(includes, incl)
  return index, incl
end

---Normalize an id (lowercase, no special chars, at least one letter, don't start with a number)
---@param id string The string to be normalized as an identifier.
---@return string|nil # The normalized identifier or nil when it's not normalizeable.
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
---@param src string The source (URI or path) to look for.
---@return string id # The identifier
---@return IncludeDoc included # The element in the `includes`.
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

---A textual representation of the array that stores references to all the included sources.
---@return string
local function includesToString()
  local log_includes = {}
  for i = 1, #includes do
    local inc = includes[i]
    table_insert(log_includes, inc.index .. ':' .. inc.src .. '(' .. table_concat(inc.subs, ',') .. ')')
  end
  return 'includes: ' .. table_concat(log_includes, ', ')
end

---A textual representation of a closed loop of documents' inclusions.
---@param cycle integer[] An array of the indices of the sources that form the closed loop.
---@return string
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

---Store in the `includes` array the informatino that a source includes another one.
---@param parent_src? string The source (URI or path) including another one.
---@param child_src string The source included in `parent_src`
local function addToInclusions(parent_src, child_src)
  local parent = parent_src or SRC_STDIN
  local parent_src_index = indexOfIncluded(parent)
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
  -- log_info('addToInclusions, '..includesToString())
end

---Check whether the index of a source is already in a chain of documents' inclusions.
---This function is used to test possibile circular references in the sources' inclusions.
---@param chain integer[] A list of indices of the sources in the `includes` array.
---@param inclIndex integer The index of a source in the `includes` array.
---@return boolean # `true` if elem is present in `chain`.
---@return integer # The first index of the source in the `chain`.
local function isInChain(chain, inclIndex)
  for j = 1, #chain do
    if chain[j] == inclIndex then
      return true, j
    end
  end
  return false, 0
end

---Clone a chain (an array of indices) and append an index.
---@param chain integer[] A chain (array) of the indices of included sources in the `includes` array.
---@param inclIndex integer The index (in the `includes` array) to be appended to the chain.
---@return integer[] # A copy of the chain with `inclIndex` appended.
local function longerChain(chain, inclIndex)
  local newChain = {}
  for i = 1, #chain do
    table_insert(newChain, chain[i])
  end
  table_insert(newChain, inclIndex)
  return newChain
end

---Check whether a chain of included documents is cyclic (has circular references that
---would create a closed, infinite loop of inclusions).
---@param chain integer[]|nil A list of indices of included documents in the `includes` array.
---@param depth integer|nil Since this function is recursive, this argument tracks the depth of recursion (it's only for debugging purposes).
---@return boolean is_cyclic
---@return integer[]|nil # If `is_cyclic` is true, the found cycle (it's a list of indices in the `includes` array).
local function isCyclic(chain, depth)
  ---@diagnostic disable-next-line: redefined-local
  local chain, depth = chain or { 1 }, depth or 1
  local subs = includes[chain[#chain]].subs or {}
  -- local prefix = "isCyclic(depth=" .. depth .. ")"
  -- log_info(prefix .. ", " .. includesToString())
  -- log_info(prefix .. ", chain: " .. table_concat(chain, ' => '))
  -- log_info("subs of " .. chain[#chain] .. ": " .. table_concat(subs, ", "))
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

---Load a subdocument.
---@param src string
---@param format_name string
---@param readerOptions? ReaderOptions
---@param filtersAttrValue? string
---@return Pandoc|nil
local function loadDocument(src, format_name, readerOptions, filtersAttrValue)
  local doc
  local markup = srcToMarkup(src)
  if not markup then
    return
  end
  local format, options, filters
  local custom = customFormats[format_name]
  if custom then
    format = custom.reader
    options = custom.options or readerOptions
    filters = custom.filters or filtersFromAttribute(filtersAttrValue)
  else
    format = format_name
    options = readerOptions
    filters = filtersFromAttribute(filtersAttrValue)
  end
  -- format or custom reader?
  if string_sub(format, string_len(format) - 3) == '.lua' then
    local custom_reader = loadfile(format)
    if custom_reader then
      -- Create a separate environment
      local newEnv = setmetatable({}, { __index = _G })
      -- Set the new environment for the function using the debug library
      debug.setupvalue(custom_reader, 1, newEnv)
      -- Execute the function
      custom_reader()
      local reader = newEnv.Reader ---@type Reader
      ---@diagnostic disable-next-line: param-type-mismatch
      doc = reader(markup, options)
    else
      log_warn("Can't load the custom reader \"" .. format .. "\"")
    end
  else
    local success, doc_or_error = pcall(function()
      return pandoc.read(markup, format, options)
    end)
    if success then
      doc = doc_or_error
    else
      log_warn(doc_or_error)
    end
  end
  -- apply optional filters
  if doc and filters then
    for i = 1, #filters do
      local filter = filters[i]
      -- TODO: load and apply filters
    end
  end
  return doc
end

--- A Pandoc filter to record all the inclusions of other sources (sub-documents).
-- Div blocks are checked to see whether they are meant to include sub-documents.
---@type Filter
local find_inclusions_filter = {

  Pandoc = function(doc)
    root_sha1 = pandoc.utils.sha1(tostring(doc.blocks))
  end,

  Div = function(div)
    local is_inclusion_div, src, format = isInclusionDiv(div, true)
    if is_inclusion_div then
      if format and src then
        -- log_info('find_inclusions_filter, found "' .. src .. '"')
        addToInclusions(current_src, src)
      end
    end
  end,
}

---The filter that does the actual inclusion through `Div` elements with a particular class.
---@type Filter
local include_doc_filter = {
  traverse = 'topdown',

  Pandoc = function(doc)
    log_info("pandoc include-doc.lua filter, version " .. FILTER_VERSION)
  end,

  Meta = function(meta)
    if meta[INCLUDE_DOC_SUB_META_FLAG] then
      log_info(
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
        -- log_info('INCLUDING ' .. src .. ', FORMAT=' .. format)
        local doc = loadDocument(
          src,
          format,
          { standalone = true },
          div.attributes[INCLUDE_FILTERS_ATTR]
        )
        if doc then
          local meta = doc.meta ---@type table
          local blocks = doc.blocks
          if blocks then
            local included_id, incl = idOfIncluded(src)
            local do_include_src_meta = include_all_meta or hasClass(div, INCLUDE_DOC_META_CLASS)
            if do_include_src_meta and meta then
              meta.src = src
              incl.meta = meta
              log_info(
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
            table_sort(classes)
            local attributes = div.attributes
            attributes[INCLUDE_SHA1_ATTR] = pandoc.utils.sha1(tostring(blocks))
            attributes[INCLUDE_ID_ATTR] = included_id
            local newDiv = pandoc.Div(blocks, pandoc.Attr(identifier, classes, attributes)) ---@type Div
            current_src = src
            pandoc.walk_block(newDiv, find_inclusions_filter)
            local is_cyclic, cycle = isCyclic()
            if is_cyclic then
              ---@diagnostic disable-next-line: param-type-mismatch
              log_warn('ERROR, circular reference: ' .. cycleToString(cycle))
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
---@type Filter
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
