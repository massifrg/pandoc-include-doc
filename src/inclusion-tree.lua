--- A Pandoc filter to recursively include sub-documents.

--- This filter's version
local FILTER_VERSION = "0.4"

--- The class for `Div` elements to see their contents replaced by the ones
-- of the sources specified with @{INCLUDE_SRC_ATTR} and @{INCLUDE_FORMAT_ATTR}.
local INCLUDE_DOC_CLASS = "include-doc"
--- The class to add to `Div` elements that specify a sub-document inclusion,
-- when the inclusion succeeds.
local INCLUDE_INCLUDED_CLASS = "included"
--- The attribute for inclusion `Div`s that specifies the format of the document to be included.
local INCLUDE_FORMAT_ATTR = "include-format"
--- The attribute for inclusion `Div`s that specifies the source of the document to be included.
local INCLUDE_SRC_ATTR = "include-src"
--- The attribute that carries the SHA-1 of the imported contents, when the inclusion succeeds.
local INCLUDE_SHA1_ATTR = "include-sha1"
--- The attribute with the identifier that this filter assigns to an imported document.
-- It's equal to the sub-key of @{INCLUDE_DOC_SUB_META_KEY} that contains the sub-document metadata
-- in the resulting document.
local INCLUDE_ID_ATTR = "included-id"
--- The metadata key (in the resulting doc) that stores the id of the root document contents
local ROOT_ID_META_KEY = "root_id"
--- The metadata key (in the resulting doc) that stores the format of the root document contents
local ROOT_FORMAT_META_KEY = "root_format"
--- The metadata key (in the resulting doc) that stores the source of the root document contents
local ROOT_SRC_META_KEY = "root_src"
--- The metadata key (in the resulting doc) that stores the SHA1 of the root document contents
local ROOT_SHA1_META_KEY = "root_sha1"

---@diagnostic disable-next-line: undefined-global
local PANDOC_STATE = PANDOC_STATE
---@diagnostic disable-next-line: undefined-global
local pandoc = pandoc
local table_insert = table.insert

local function logging_info(...)
end
local function logging_warning(...)
end
local function logging_error(...)
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

--- The filter that does the actual inclusion through `Div` elements with a particular class.
local inclusion_tree_filter = {
  traverse = 'topdown',

  Blocks = function(blocks)
    local incdivs = {}
    local block
    for i = 1, #blocks do
      block = blocks[i]
      if block.tag == "Div" and isInclusionDiv(block) then
        table_insert(incdivs, block)
      end
    end
    return incdivs
  end
}

local function divs2table(divs)
  local t = {}
  for i = 1, #divs do
    local div = divs[i]
    local attrs = div.attributes
    local id = div.identifier
    if string.len(id) == 0 then
      id = attrs[INCLUDE_ID_ATTR]
    end
    local obj = {
      id = id,
      src = attrs[INCLUDE_SRC_ATTR],
      format = attrs[INCLUDE_FORMAT_ATTR],
      sha1 = attrs[INCLUDE_SHA1_ATTR],
      included = hasClass(div, INCLUDE_INCLUDED_CLASS),
    }
    if div.content then
      local children = divs2table(div.content)
      if #children > 0 then
        obj.children = children
      end
    end
    table_insert(t, obj)
  end
  return t
end

function Writer(doc, opts)
  local divs = doc:walk(inclusion_tree_filter)
  local meta = doc.meta
  local tree = {
    id = tostring(meta[ROOT_ID_META_KEY]),
    src = tostring(meta[ROOT_SRC_META_KEY]),
    format = tostring(meta[ROOT_FORMAT_META_KEY]),
    sha1 = tostring(meta[ROOT_SHA1_META_KEY]),
    children = divs2table(divs.blocks)
  }
  return pandoc.json.encode(tree)
end

function Template()
  local t = pandoc.template.default 'plain'
  return t
end

return { inclusion_tree_filter }
