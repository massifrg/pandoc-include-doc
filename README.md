# A filter for Pandoc to include other documents

`include-doc.lua` is a Lua filter for Pandoc to include the contents
of some external documents inside a main document.

## An example

Consider the file `master.html`, that you can find in the `test` directory:

```html
<html>
  <head>
    <title>Assembled document</title>
  </head>
  <body>
    <h1>Title</h1>
    <p>
      This is a master document that includes some parts from other documents.
    </p>
    <div class="include-doc" data-include-format="html" data-include-src="chap1.html">
      <p>This text will be replaced by the contents of "chap1.html".</p>
    </div>
    <div class="include-doc" data-include-format="json" data-include-src="chap2.json">
      <p>This text will be replaced by the contents of "chap2.json".</p>
    </div>
    <div class="include-doc" data-include-format="markdown" data-include-src="chap3.md">
      <p>This text will be replaced by the contents of "chap3.md".</p>
    </div>
    <div class="include-doc" data-include-format="markdown" data-include-src="chap4.md">
      <p>This text will be replaced by the contents of "chap4.md".</p>
    </div>
    <div class="include-doc" data-include-format="markdown" data-include-src="chap5.md">
      <p>This text will be replaced by the contents of "chap5.md".</p>
    </div>
  </body>
</html>
```

and convert it into markdown filtering it with `include-doc.lua` this way:

```sh
pandoc -f html -t markdown -s -L include-doc.lua master.html
```

(if you run it from the `test` directory you may need to write `-L ../src/include-doc.lua`
instead of `-L include-doc.lua`)

The resulting document will embed the contents of `chap1.html`, `chap2.json`, 
`chap3.md`, `chap4.md` (with its `chap4s1.html` and `chap4s2.json` sub-documents) 
and `chap5.md`.

`include-doc.lua` looks for Pandoc `Div` elements with an `include-doc` class.

When it finds such elements, it fetches the contents of the source specified in the
`data-include-src` attribute and calls [pandoc.read](https://pandoc.org/lua-filters.html#pandoc.read)
to read its contents with the format specified by the `data-include-format` attribute.

Then it replaces the contents of the `Div` element with the contents of the external source
(in Pandoc terms, the `Div` blocks are replaced by the blocks of the imported document).

For the replacement to succeed, _these elements are mandatory_:

- the `include-doc` class

- the `include-format` attribute (it's `data-include-format` in HTML)

- the `include-src` attribute (it's `data-include-src` in HTML)

If something goes wrong -- i.e. the source can't be found or the format is invalid -- the
replacement does not happen and the `Div` element retains its contents.

## How to specify inclusions

You can specify inclusions in every format that lets you define a Pandoc 
[Div](https://hackage.haskell.org/package/pandoc-types-1.23/docs/Text-Pandoc-Definition.html#t:Block)
with the `include-doc` class and the `include-format` and `include-src` attributes.
So the including documents are restricted to those formats.

The documents that can be included, on the other hand, are all the ones that can
be imported in Pandoc.

## What changes

The including `Div` block is kept, only its contents are replaced.

After a successful replacement, 

- the `included` class is added to the `Div`'s classes

- the `include-sha1` attribute is added to the `Div`'s attributes
  (_that attribute is not used now_; future versions may use its value to detect 
  changes in the imported document; by the way, the attribute value is the SHA-1
  of the imported document contents)

## Recursion and infinite loops

The filter is recursive, so the whole document structure can have an arbitrary depth.

It should also detect closed loops in the document structure: i.e. _document1_ includes
_document2_, _document2_ includes _document3_ and _document3_ includes _document1_;
that would determine an infinite loop of inclusions (_circular references_), but once
the filter detects a closed loop, it stops.
Until then the inclusion process is done anyway.

The filter does not mind if you _include the same document more than once_, as long as
there are no closed loops.

## Assembling and filtering

Pandoc lets you apply more than one filter, so you may first apply the `include-doc` filter
to assemble the whole document and then pass it to another filter.

The command:

```sh
pandoc -f html -t markdown -s -L include-doc.lua -L other-filter.lua -o whole-filtered-doc.md master.html
```

produces a `whole-filtered-doc.md` markdown document; `master.html` is the master document that specifies
inclusions, and `other-filter.lua` is the filter to apply to the document once its assembled.

## Including sub-documents' metadata

You can also include the sub-documents' metadata. There are two ways:

- adding the class `include-meta` to the `Div` elements used to include sub-documents

- adding `include-sub-meta: true` to the main document's metadata

The first method lets you import metadata selectively for each sub-document.

The second one makes the filter store every sub-document's metadata in the resulting doc.

All the sub-document's metadata are stored under the `included-sub-meta` key.

You need to specify the `-s` option of `pandoc`, otherwise you won't get any metadata
(but this is not specific to this filter).

Here's an example (see `master-include-all-meta.md` in the `test` directory):

```markdown
---
include-sub-meta: true
included-sub-meta:
- included_2:
    src: chap1.html
    title: Chapter 1
- included_3:
    src: chap2.json
    title: Chapter 2
- included_4:
    src: chap3.md
    title: Chapter 3
- included_5:
    src: chap4.md
    title: Fourth chapter
- included_6:
    src: chap5.md
    title: Chapter 5
- included_7:
    src: chap4s1.html
    title: Fourth chapter, section one
- included_8:
    src: chap4s2.json
    title: Fourth chapter, section two
title: Assembled document
---

# Title

This is a master document that includes some parts from other documents.

::: {.include-doc .included include-format="html" include-src="chap1.html" include-sha1="011822fbb02463dc05c2f35d8d7066f3ee320c5a" included-id="included_2"}
## Chapter 1

This is the first chapter.
:::
```

(the output is cut to show only the first part of the document)

As you can see, every sub-document's metadata is under a sub-key of `included-sub-meta`.

The sub-key is an identifier assigned by the filter to each imported document.
The same value is stored in the `included-id` attribute of the `Div`, whose
contents have been replaced by the sub-document.

The sub-document metadata are complemented with a `src` field reporting its source.

## Aknowledgements

This software

- is a filter for [Pandoc](https://pandoc.org);

- and makes use of William Lupton's [logging.lua](https://github.com/pandoc-ext/logging) module.