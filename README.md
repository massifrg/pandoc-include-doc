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

- ~~the `include-doc` class~~ (see [less clutter](#less-clutter) below)

- ~~the `include-format` attribute (it's `data-include-format` in HTML)~~  (see [less clutter](#less-clutter) below)

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

## Metadata added by the filter

This filter adds these metadata (they are all `MetaString`):

- `root_id`: the identifier of the root document

- `root_format`: the format of the root document

- `root_src`: the source of the root document

- `root_sha1`: the SHA1 of the the root document's contents

## Including sub-documents' metadata

You can also include the sub-documents' metadata. There are two ways:

- adding the class `include-meta` to the `Div` elements used to include sub-documents

- adding `include-sub-meta: true` to the main document's metadata

- setting the `include_sub_meta` variable with `--variable include_sub_meta`
  in pandoc command line

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
- chap1:
    src: chap1.html
    title: Chapter 1
- chap2:
    src: chap2.json
    title: Chapter 2
- chap3:
    src: chap3.md
    title: Chapter 3
- chap4:
    src: chap4.md
    title: Fourth chapter
- chap5:
    src: chap5.md
    title: Chapter 5
- chap4s1:
    src: chap4s1.html
    title: Fourth chapter, section one
- chap4s2:
    src: chap4s2.json
    title: Fourth chapter, section two
title: Assembled document
---

# Title

This is a master document that includes some parts from other documents.

::: {.include-doc .included include-format="html" include-src="chap1.html" include-sha1="011822fbb02463dc05c2f35d8d7066f3ee320c5a" included-id="chap1"}
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

## Less clutter

Since version 0.3, you can specify only the `include-src` attribute, and the `Div` will be
considered an "inclusion Div", as if it had the `include-doc` class and the `include-format`
attribute.

Unless you specify it, the source format will be guessed from its path
calling [from_path](https://pandoc.org/lua-filters.html#pandoc.format.from_path) (available
since version 3.1.2 of Pandoc).

If the format is not identified, the source contents will not be included in the output.

The `include-doc` class will be added, if not present.

## Extracting the structure of inclusions with `inclusion-tree.lua`

`inclusion-tree.lua` is a custom writer and it's used to retrieve the tree structure
of a document as JSON.

It's tipically used in conjunction with `include-doc.lua`, e.g.:

```sh
pandoc -f markdown -t inclusion-tree.lua -L include-doc.lua document-including-other-docs.md
```

It ouputs a JSON object like this:

```json
{
    "children": [
      ...
    ],
    "format": "html",
    "id": "root",
    "sha1": "64b297779956f64503df8dccca191f76403462f0",
    "src": "master.html"
}
```

The `children` field is an array of objects with the same `format`, `id`, `sha1` and `src` fields.

If the main document's direct children include other documents as well, they'll have a `children` field, otherwise they won't have it.

### Setting (overriding) the root id

You can set the root document `id` with the `-M root-id=...` (or `--metadata root-id=...`) option,
e.g.:

```sh
pandoc -f markdown -t inclusion-tree.lua -L include-doc.lua -M root-id=master-doc document-including-other-docs.md
```

You'll get a JSON like this:

```json
{
    "children": [
      ...
    ],
    "format": "markdown",
    "id": "master-doc",
    "sha1": "...",
    "src": "document-including-other-docs.md"
}
```

## Version

The current version is 0.6 (2025, September 18th).