---@class List A Pandoc `List`.

---@class Attr A Pandoc `Attr` data structure.
---@field identifier string
---@field classes    string[]
---@field attributes table<string,string>

---@class WithTag
---@field tag string The elements's tag.
---@field t   string The elements's tag.

---@class WithAttr: Attr
---@field attr Attr

---@class Block: WithTag A Pandoc `Block`.
---@field content List The content of the Block.

---@class Inline: WithTag A Pandoc `Inline`.
---@field content List The content of the Inline.

---@class Plain: Block A Pandoc `Plain`.
---@field content Block[]

---@class Para: Block A Pandoc `Para`.
---@field content Inline[]

---@class LineBlock: Block A Pandoc `LineBlock`
---@field content Inline[][]

---@class CodeBlock: Block,WithAttr A Pandoc `CodeBlock`
---@field text string

---@class RawBlock: Block A Pandoc `RawBlock`
---@field format string
---@field text string

---@alias ListNumberStyle "DefaultStyle"|"Example"|"Decimal"|"LowerRoman"|"UpperRoman"|"LowerAlpha"|"UpperAlpha"
---@alias ListNumberDelim "DefaultDelim"|"Period"|"OneParen"|"TwoParens"

---@class ListAttributes
---@field start integer Number of the first list item.
---@field style ListNumberStyle Style of list numbers.
---@field delimiter ListNumberDelim Delimiter of list numbers.

---@class OrderedList: Block,ListAttributes A Pandoc `OrderedList`
---@field items Block[][]
---@field listAttributes ListAttributes|nil

---@class BulletList: Block A Pandoc `BulletList`
---@field content Block[][]

---@class DefinitionListItem
---@field term Inline[]
---@field data Block[][]

---@class DefinitionList: Block A Pandoc `DefinitionList`
---@field content DefinitionListItem[]

---@class Header: Block,WithAttr A Pandoc `Header`
---@field level integer
---@field content Inline[]

---@class Caption A Pandoc `Table` or `Figure` caption
---@field long Block[]
---@field short Inline[]|nil

---@alias Alignment "AlignLeft"|"AlignRight"|"AlignCenter"|"AlignDefault"

---@class Cell: WithAttr A Pandoc `Table` cell
---@field alignment Alignment
---@field contents Block[]
---@field col_span integer
---@field row_span integer

---@class Row: WithAttr A Pandoc `Table` row
---@field cells Cell[]

---@class TableHead: WithAttr A Pandoc `Table` head
---@field rows Row[]

---@class TableFoot: WithAttr A Pandoc `Table` foot
---@field rows Row[]

---@class TableBody: WithAttr A Pandoc `Table` body
---@field body Row[] table body rows.
---@field head Row[] intermediate head.
---@field row_head_columns integer number of columns taken up by the row head of each row.

---@alias ColSpec table A pair of cell alignment and relative width.

---@class Table: Block,WithAttr A Pandoc `Table`
---@field caption Caption
---@field colspecs ColSpec[]
---@field head TableHead
---@field bodies TableBody[]
---@field foot TableFoot

---@alias SimpleCell Block[]

---@class SimpleTable: Block,WithAttr A Pandoc `SimpleTable` (tables in pre pandoc 2.10)
---@field caption Caption Table caption.
---@field aligns Alignment[] Alignments of every column.
---@field widths number[] Column widths.
---@field headers SimpleCell[] Table header row.
---@field rows SimpleCell[][] Table body.

---@class Figure: Block,WithAttr A Pandoc `Figure`.
---@field content Block[]
---@field caption Caption

---@class Div: Block,WithAttr A Pandoc `Div`.
---@field content Block[]

---@class Str: Inline A Pandoc `Str`.
---@field text string

---@class Emph: Inline A Pandoc `Emph`.
---@field content Inline[]

---@class Underline: Inline A Pandoc `Underline`.
---@field content Inline[]

---@class Strong: Inline A Pandoc `Strong`.
---@field content Inline[]

---@class Strikeout: Inline A Pandoc `Strikeout`.
---@field content Inline[]

---@class Superscript: Inline A Pandoc `Superscript`.
---@field content Inline[]

---@class Subscript: Inline A Pandoc `Subscript`.
---@field content Inline[]

---@class SmallCaps: Inline A Pandoc `SmallCaps`.
---@field content Inline[]

---@alias QuoteType "SingleQuote"|"DoubleQuote"

---@class Quoted: Inline A Pandoc `Quoted`.
---@field quotetype QuoteType
---@field content Inline[]

---@alias CitationMode "AuthorInText"|"SuppressAuthor"|"NormalCitation"

---@class Citation
---@field id string
---@field mode CitationMode
---@field prefix Inline[]
---@field suffix Inline[]
---@field note_num integer
---@field hash integer

---@class Cite: Inline A Pandoc `Cite`.
---@field content Inline[]
---@field citations Citation[]

---@class Code: Inline,WithAttr A Pandoc `Code`.

---@class Space: Inline A Pandoc `Space`.

---@class SoftBreak: Inline A Pandoc `SoftBreak`.

---@class LineBreak: Inline A Pandoc `LineBreak`.

---@alias MathType "DisplayMath"|"InlineMath"

---@class Math: Inline A Pandoc `Math`.
---@field mathtype MathType
---@field text string

---@class RawInline: Inline A Pandoc `RawInline`.
---@field format string
---@field text string

---@class Link: Inline,WithAttr A Pandoc `Link`.
---@field content Inline[]
---@field target string
---@field title string

---@class Image: Inline,WithAttr A Pandoc `Image`.
---@field caption Inline[]
---@field src string
---@field title string

---@class Note: Inline A Pandoc `Note`.
---@field content Block[]

---@class Span: Inline,WithAttr A Pandoc `Span`.
---@field content Inline[]

---@class Meta

---@class Doc
---@field blocks Block[]
---@field meta Meta

---@class Filter
---@field Pandoc         nil|fun(doc: Doc): Doc|nil
---@field Blocks         nil|fun(blocks: List): List|nil
---@field Inlines        nil|fun(inlines: List): List|nil
---@field Plain          nil|fun(plain: Plain): List|nil
---@field Para           nil|fun(para: Para): List|nil
---@field LineBlock      nil|fun(lineblock: LineBlock): List|nil
---@field RawBlock       nil|fun(rawblock: RawBlock): List|nil
---@field OrderedList    nil|fun(orderedlist: OrderedList): List|nil
---@field BulletList     nil|fun(bulletlist: BulletList): List|nil
---@field DefinitionList nil|fun(definitionlist: DefinitionList): List|nil
---@field Header         nil|fun(header: Header): List|nil
---@field HorizontalRule nil|fun(): List|nil
---@field Table          nil|fun(): List|nil
---@field Figure         nil|fun(): List|nil
---@field Div            nil|fun(div: Div): List|nil
---@field Str            nil|fun(str: Str): List|nil
---@field Emph           nil|fun(emph: Emph): List|nil
---@field Underline      nil|fun(underline: Underline): List|nil
---@field Strong         nil|fun(strong: Strong): List|nil
---@field Strikeout      nil|fun(strikeout: Strikeout): List|nil
---@field Superscript    nil|fun(superscript: Superscript): List|nil
---@field Subscript      nil|fun(subscript: Subscript): List|nil
---@field SmallCaps      nil|fun(smallcaps: SmallCaps): List|nil
---@field Quoted         nil|fun(quoted: Quoted): List|nil
---@field Cite           nil|fun(cite: Cite): List|nil
---@field Code           nil|fun(code: Code): List|nil
---@field Space          nil|fun(): List|nil
---@field SoftBreak      nil|fun(): List|nil
---@field LineBreak      nil|fun(): List|nil
---@field Math           nil|fun(): List|nil
---@field RawInline      nil|fun(rawinline: RawInline): List|nil
---@field Link           nil|fun(link: Link): List|nil
---@field Image          nil|fun(image: Image): List|nil
---@field Note           nil|fun(note: Note): List|nil
---@field Span           nil|fun(span: Span): List|nil
