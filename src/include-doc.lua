local INCLUDE_DOC_CLASS = "include-doc"
local INCLUDE_INCLUDED_CLASS = "included"
local INCLUDE_FORMAT_ATTR = "include-format"
local INCLUDE_SRC_ATTR = "include-src"
local INCLUDE_SHA1_ATTR = "include-sha1"

---@diagnostic disable-next-line: undefined-global
local PANDOC_STATE = PANDOC_STATE
---@diagnostic disable-next-line: undefined-global
local pandoc = pandoc

local function logging_info(...)
end
local logging

if pcall(require, "logging") then
  logging = require("logging")
end
if logging then
  logging_info = logging.info
end

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

local function srcToMarkup(src)
  local mime, content = pandoc.mediabag.fetch(src)
  -- logging_info(mime)
  -- logging_info(content)
  return content
end

local current_src = PANDOC_STATE.input_files[1] or '__MAIN__'
local includes = {}

local function indexOfIncluded(src)
  for j = 1, #includes do
    if includes[j].src == src then
      return j
    end
  end
  local index = #includes + 1
  table.insert(includes, { index = index, src = src, subs = {} })
  return index
end

local function includesToString()
  local log_includes = {}
  for i = 1, #includes do
    local inc = includes[i]
    table.insert(log_includes, inc.index .. ':' .. inc.src .. '(' .. table.concat(inc.subs, ',') .. ')')
  end
  return 'includes: ' .. table.concat(log_includes, ', ')
end

local function cycleToString(cycle)
  local str_cycle = {}
  if #cycle > 1 then
    for i = 1, #cycle do
      table.insert(str_cycle, includes[cycle[i]].src)
    end
    table.insert(str_cycle, includes[cycle[1]].src)
  end
  return table.concat(str_cycle, ' => ')
end

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
    table.insert(includes[parent_src_index].subs, child_src_index)
  end
  -- logging_info('addToInclusions, '..includesToString())
end

local function isInChain(chain, elem)
  for j = 1, #chain do
    if chain[j] == elem then
      return true, j
    end
  end
  return false, 0
end

local function longerChain(chain, elem)
  local newChain = {}
  for i = 1, #chain do
    table.insert(newChain, chain[i])
  end
  table.insert(newChain, elem)
  return newChain
end

local function isCyclic(chain, depth)
  local chain = chain or { 1 }
  local depth = depth or 1
  local subs = includes[chain[#chain]].subs or {}
  -- local prefix = "isCyclic(depth=" .. depth .. ")"
  -- logging_info(prefix .. ", " .. includesToString())
  -- logging_info(prefix .. ", chain: " .. table.concat(chain, ' => '))
  -- logging_info("subs of " .. chain[#chain] .. ": " .. table.concat(subs, ", "))
  if #subs > 0 then
    for j = 1, #subs do
      local in_chain, index_in_chain = isInChain(chain, subs[j])
      if in_chain then
        local cycle = {}
        for k = index_in_chain, #chain do
          table.insert(cycle, chain[k])
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

local find_inclusions_filter = {
  Div = function(div)
    if hasClass(div, INCLUDE_DOC_CLASS) then
      local format = div.attributes[INCLUDE_FORMAT_ATTR]
      local src = div.attributes[INCLUDE_SRC_ATTR]
      if format and src then
        -- logging_info('find_inclusions_filter, found "' .. src .. '"')
        addToInclusions(current_src, src)
      end
    end
  end,
}

local include_doc_filter = {
  traverse = 'topdown',

  Div = function(div)
    if hasClass(div, INCLUDE_DOC_CLASS) then
      local format = div.attributes[INCLUDE_FORMAT_ATTR]
      local src = div.attributes[INCLUDE_SRC_ATTR]
      if format and src then
        -- logging_info('INCLUDING ' .. src .. ', FORMAT=' .. format)
        local markup = srcToMarkup(src)
        local doc = pandoc.read(markup, format, { standalone = true })
        local meta, blocks = doc.meta, doc.blocks
        if blocks then
          local identifier = div.identifier
          local classes = div.classes
          table.insert(classes, INCLUDE_INCLUDED_CLASS)
          local attributes = div.attributes
          attributes[INCLUDE_SHA1_ATTR] = pandoc.utils.sha1(tostring(blocks))
          local newDiv = pandoc.Div(blocks, pandoc.Attr(identifier, classes, attributes))
          current_src = src
          pandoc.walk_block(newDiv, find_inclusions_filter)
          local is_cyclic, cycle = isCyclic()
          if is_cyclic then
            logging.error('ERROR, circular reference: ' .. cycleToString(cycle))
            return
          end
          return newDiv
        end
      end
    end
  end
}

return { find_inclusions_filter, include_doc_filter }
