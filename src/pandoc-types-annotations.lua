---@class List A Pandoc `List`.

---@class Attr A Pandoc `Attr` data structure.
---@field identifier string
---@field classes    string[]
---@field attributes table<string,string>

---@class Block A Pandoc `Block`.
---@field tag string The block's tag.
---@field content List The content of the Block.
---@field attr    Attr|nil

---@class Inline A Pandoc `Inline`.
---@field tag string The inline's tag.
---@field content List The content of the Inline.
---@field attr    Attr|nil

---@class Div: Block A Pandoc `Div`.
---@field attr Attr
---@field identifier string
---@field classes string[]
---@field attributes {[string]: string}
---@field content Block[]

---@class Meta
