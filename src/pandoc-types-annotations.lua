---@class List A Pandoc List.

---@class EmptyList An empty List.

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
---@field content List<Block>

---@class Para: Block A Pandoc `Para`.
---@field content List<Inline>

---@class LineBlock: Block A Pandoc `LineBlock`
---@field content List<List<Inline>>

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
---@field items List<List<Block>>
---@field listAttributes ListAttributes|nil

---@class BulletList: Block A Pandoc `BulletList`
---@field content List<List<Block>>

---@class DefinitionListItem
---@field term List<Inline>
---@field data List<List<Block>>

---@class DefinitionList: Block A Pandoc `DefinitionList`
---@field content List<DefinitionListItem>

---@class Header: Block,WithAttr A Pandoc `Header`
---@field level integer
---@field content List<Inline>

---@class Caption A Pandoc `Table` or `Figure` caption
---@field long List<Block>
---@field short List<Inline>|nil

---@alias Alignment "AlignLeft"|"AlignRight"|"AlignCenter"|"AlignDefault"

---@class Cell: WithAttr A Pandoc `Table` cell
---@field alignment Alignment
---@field contents List<Block>
---@field col_span integer
---@field row_span integer

---@class Row: WithAttr A Pandoc `Table` row
---@field cells List<Cell>

---@class TableHead: WithAttr A Pandoc `Table` head
---@field rows List<Row>

---@class TableFoot: WithAttr A Pandoc `Table` foot
---@field rows List<Row>

---@class TableBody: WithAttr A Pandoc `Table` body
---@field body List<Row> table body rows.
---@field head List<Row> intermediate head.
---@field row_head_columns integer number of columns taken up by the row head of each row.

---@alias ColSpec table A pair of cell alignment and relative width.

---@class Table: Block,WithAttr A Pandoc `Table`
---@field caption Caption
---@field colspecs List<ColSpec>
---@field head TableHead
---@field bodies List<TableBody>
---@field foot TableFoot

---@alias SimpleCell List<Block>

---@class SimpleTable: Block,WithAttr A Pandoc `SimpleTable` (tables in pre pandoc 2.10)
---@field caption Caption Table caption.
---@field aligns List<Alignment> Alignments of every column.
---@field widths number[] Column widths.
---@field headers List<SimpleCell> Table header row.
---@field rows List<List<SimpleCell>> Table body.

---@class Figure: Block,WithAttr A Pandoc `Figure`.
---@field content List<Block>
---@field caption Caption

---@class Div: Block,WithAttr A Pandoc `Div`.
---@field content List<Block>

---@class Str: Inline A Pandoc `Str`.
---@field text string

---@class Emph: Inline A Pandoc `Emph`.
---@field content List<Inline>

---@class Underline: Inline A Pandoc `Underline`.
---@field content List<Inline>

---@class Strong: Inline A Pandoc `Strong`.
---@field content List<Inline>

---@class Strikeout: Inline A Pandoc `Strikeout`.
---@field content List<Inline>

---@class Superscript: Inline A Pandoc `Superscript`.
---@field content List<Inline>

---@class Subscript: Inline A Pandoc `Subscript`.
---@field content List<Inline>

---@class SmallCaps: Inline A Pandoc `SmallCaps`.
---@field content List<Inline>

---@alias QuoteType "SingleQuote"|"DoubleQuote"

---@class Quoted: Inline A Pandoc `Quoted`.
---@field quotetype QuoteType
---@field content List<Inline>

---@alias CitationMode "AuthorInText"|"SuppressAuthor"|"NormalCitation"

---@class Citation
---@field id string
---@field mode CitationMode
---@field prefix List<Inline>
---@field suffix List<Inline>
---@field note_num integer
---@field hash integer

---@class Cite: Inline A Pandoc `Cite`.
---@field content List<Inline>
---@field citations List<Citation>

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
---@field content List<Inline>
---@field target string
---@field title string

---@class Image: Inline,WithAttr A Pandoc `Image`.
---@field caption List<Inline>
---@field src string
---@field title string

---@class Note: Inline A Pandoc `Note`.
---@field content List<Block>

---@class Span: Inline,WithAttr A Pandoc `Span`.
---@field content List<Inline>

---@class Meta

---@class Doc
---@field blocks List<Block>
---@field meta Meta

---@alias InlineFilterResult nil|Inline|List<Inline>|EmptyList
---@alias BlockFilterResult nil|Block|List<Block>|EmptyList

---@class Filter
---@field traverse       nil|"topdown"|"typewise" Traversal order of this filter (default: `typewise`).
---@field Pandoc         nil|fun(doc: Doc): Doc|nil `nil` = leave untouched.
---@field Blocks         nil|fun(blocks: List): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Inlines        nil|fun(inlines: List): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Plain          nil|fun(plain: Plain): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Para           nil|fun(para: Para): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field LineBlock      nil|fun(lineblock: LineBlock): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field RawBlock       nil|fun(rawblock: RawBlock): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field OrderedList    nil|fun(orderedlist: OrderedList): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field BulletList     nil|fun(bulletlist: BulletList): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field DefinitionList nil|fun(definitionlist: DefinitionList): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Header         nil|fun(header: Header): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete. `nil` = leave untouched, `EmptyList` = delete.
---@field HorizontalRule nil|fun(): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Table          nil|fun(): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Figure         nil|fun(): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Div            nil|fun(div: Div): BlockFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Str            nil|fun(str: Str): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Emph           nil|fun(emph: Emph): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Underline      nil|fun(underline: Underline): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Strong         nil|fun(strong: Strong): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Strikeout      nil|fun(strikeout: Strikeout): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Superscript    nil|fun(superscript: Superscript): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Subscript      nil|fun(subscript: Subscript): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field SmallCaps      nil|fun(smallcaps: SmallCaps): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Quoted         nil|fun(quoted: Quoted): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Cite           nil|fun(cite: Cite): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Code           nil|fun(code: Code): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Space          nil|fun(): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field SoftBreak      nil|fun(): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field LineBreak      nil|fun(): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Math           nil|fun(): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field RawInline      nil|fun(rawinline: RawInline): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Link           nil|fun(link: Link): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Image          nil|fun(image: Image): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Note           nil|fun(note: Note): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
---@field Span           nil|fun(span: Span): InlineFilterResult `nil` = leave untouched, `EmptyList` = delete.
