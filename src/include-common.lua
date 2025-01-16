--- This filter's version
local FILTER_VERSION            = "0.5"

local log_info                  = pandoc.log.info
local log_warn                  = pandoc.log.warn

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

---Check whether a Pandoc item with an `Attr` has a class.
---@param elem WithAttr The `Block` or `Inline` with an `Attr`.
---@param class string The class to look for among the ones in `Attr`'s classes.
---@return boolean
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

---Check whether a `Div` is meant to include contents from an external source
---@param div Div The `Div` block to check.
---@return boolean is_inclusion_div
---@return string|nil source # The source (URI or path) of the included document.
---@return string|nil format # The format of the included document, when specified.
---@return boolean|nil # `true` when INCLUDE_DOC_CLASS is found.
local function isInclusionDiv(div, log)
  if not div.tag == "Div" then
    return false
  end
  local src = div.attributes[INCLUDE_SRC_ATTR]
  local has_include_doc_class = hasClass(div, INCLUDE_DOC_CLASS)
  if src then
    if log then
      log_info('Div has a "' .. INCLUDE_SRC_ATTR .. '" attribute, but no "' .. INCLUDE_DOC_CLASS .. '" class')
    end
    local format = div.attributes[INCLUDE_FORMAT_ATTR] or pandoc.format.from_path(src)
    if format then
      return true, src, format, has_include_doc_class
    elseif log then
      log_warn('format not found for source "' .. src .. '"')
    end
  elseif log and has_include_doc_class then
    log_warn('Div has "' .. INCLUDE_DOC_CLASS .. '" class, but no valid "' .. INCLUDE_SRC_ATTR .. '" attribute')
  end
  return false
end


return {
  FILTER_VERSION            = FILTER_VERSION,
  INCLUDE_DOC_CLASS         = INCLUDE_DOC_CLASS,
  INCLUDE_FORMAT_ATTR       = INCLUDE_FORMAT_ATTR,
  INCLUDE_SRC_ATTR          = INCLUDE_SRC_ATTR,
  INCLUDE_DOC_META_CLASS    = INCLUDE_DOC_META_CLASS,
  INCLUDE_INCLUDED_CLASS    = INCLUDE_INCLUDED_CLASS,
  INCLUDE_SHA1_ATTR         = INCLUDE_SHA1_ATTR,
  INCLUDE_DOC_SUB_META_FLAG = INCLUDE_DOC_SUB_META_FLAG,
  INCLUDE_DOC_SUB_META_VAR  = INCLUDE_DOC_SUB_META_VAR,
  INCLUDE_DOC_SUB_META_KEY  = INCLUDE_DOC_SUB_META_KEY,
  ROOT_ID_META_KEY          = ROOT_ID_META_KEY,
  ROOT_FORMAT_META_KEY      = ROOT_FORMAT_META_KEY,
  ROOT_SRC_META_KEY         = ROOT_SRC_META_KEY,
  ROOT_SHA1_META_KEY        = ROOT_SHA1_META_KEY,
  INCLUDE_ID_ATTR           = INCLUDE_ID_ATTR,
  INCLUDE_ID_PREFIX         = INCLUDE_ID_PREFIX,
  hasClass                  = hasClass,
  isInclusionDiv            = isInclusionDiv
}
