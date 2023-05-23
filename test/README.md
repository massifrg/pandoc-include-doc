# Tests for `include-doc.lua`

This directory contains some test files.

You must have a recent version of [Pandoc](https://pandoc.org) installed on your system.

To check them, enter this directory and type:

```sh
pandoc --verbose -f html -t markdown -s -L ../src/include-doc.lua master.html
```

That will assemble a file starting from `master.html`.

`master-with-circular.html` and `master-with-double-import.html` are modified versions
to test respectively the closed loop detection and the inclusion of a document more than once.

The former should end with an error (producing an output anyway), the latter should end
successfully without any error.

Here are the commands to test them:

```sh
pandoc --verbose -f html -t markdown -s -L ../src/include-doc.lua master-with-circular.html
pandoc --verbose -f html -t markdown -s -L ../src/include-doc.lua master-with-double-import.html
```