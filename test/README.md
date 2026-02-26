# Tests for `include-doc.lua`

This directory contains some test files.

You must have a recent version of [Pandoc](https://pandoc.org) installed on your system.

To check them, enter this directory and type:

```sh
pandoc --verbose -f html -t markdown -s -L ../src/include-doc.lua master.html
```

That will assemble a file starting from `master.html`.

## Tests for multiple inclusions

`master-with-circular.html` and `master-with-double-import.html` are modified versions
to test respectively the closed loop detection and the inclusion of a document more than once.

The former should end with an error (producing an output anyway), the latter should end
successfully without any error.

Here are the commands to test them:

```sh
pandoc --verbose -f html -t markdown -s -L ../src/include-doc.lua master-with-circular.html
pandoc --verbose -f html -t markdown -s -L ../src/include-doc.lua master-with-double-import.html
```

## Test double inclusion of the same file from different sources

You may include the same file, or two different files with the same filename, but different paths.

Since the filename is the same, the automatically generated id could be the same, but the filter
renames the ids that are equal but point to different sources:

```sh
pandoc --verbose -f html -t markdown -s -L ../src/include-doc.lua master-with-double-two-sources-same-id.html
```

## Tests for metadata inclusions

`master-include-all-meta.md` has an `include-sub-meta` meta value set to `true`, that makes
the filter include all the included documents' metadata under the key `included-sub-meta`
in the resulting document.

Here's the command to test it:

```sh
pandoc --verbose -f markdown -t markdown -s -L ../src/include-doc.lua master-include-all-meta.md
```

`master-include-some-meta.html` shows how to import the metadata only of some sub-documents,
adding the class `include-meta` to the including `Div` elements.

Here's the command to test it:

```sh
pandoc --verbose -f html -t markdown -s -L ../src/include-doc.lua master-include-some-meta.html
```

## A test file with less classes and attributes

`master-with-less-attributes.html` produces the same output of `master.html` without
specifying the class `include-doc` and the `include-format` attribute for every inclusion.

```sh
pandoc --verbose -f html -t markdown -s -L ../src/include-doc.lua master-with-less-attributes.html
```

## A test of inclusion of single elements picked by id or class from a sub-document

```sh
pandoc --verbose -f markdown -t markdown -s -L ../src/include-doc.lua master-pick-elements.md
```

## Testing `inclusion.tree.lua`

`inclusion-tree.lua` is a custom writer/filter to extract the structure of documents' inclusion.

### As a writer

```sh
pandoc -f html  -L ../src/include-doc.lua -t ../src/inclusion-tree.lua -s master.html
```

### As a filter

```sh
pandoc -f html  -t html -L ../src/include-doc.lua -L ../src/inclusion-tree.lua master.html
```