# A master file to test the inclusion of single elements of external documents

When you specify `include-pick-id` and/or `include-pick-classes` along with `include-doc`,
you can include only some `Blocks` or `Inlines` of a sub-document, instead of the whole doc:

- with `include-pick-id` you specify the identifier of the Block or Inline
  you want to include

- with `include-pick-classes` you specify a space-separated list of classes:
  if an element has at least one of those classes, it gets included

- the inclusion is only for elements that have an `Attr`: `Div`, `Header`, `Table`,
  `Figure` and `CodeBlock` blocks; `Span`, `Header`, `Image` and `Code` inlines

- since the replacement must be a list of blocks, every selected inline is embedded
  in a `Para` block

- if there's no block or inline matching, no inclusion takes place and the placeholder text
  is kept untouched

Here's Table C:

::: {.include-doc include-src="repository.html" include-pick-id="table_C"}
This text will be replaced by table C contained in "repository.html".
:::

Here's figure 1:

::: {.include-doc include-src="repository.html" include-pick-id="figure_1"}
This text will be replaced by figure 1 contained in "repository.html".
:::

Here's chapter 2 title from "chap2.json":

::: {.include-doc include-src="chap2.json" include-pick-id="chapter-2"}
This text will be replaced by the Header of chapter 2 contained in "chap2.json".
:::

The next inclusion does not change the placeholder text, because there's
no element with identifier "missing" in "repository.html":

::: {.include-doc include-src="repository.html" include-pick-id="missing"}
This placeholder text should stay untouched, because there's no element with a "missing"
identifier in "repository.html".
:::

Include the elements with the "two-cols-table" class:

::: {.include-doc include-src="repository.html" include-pick-classes="two-cols-table"}
This placeholder text should be replaced by the elements with a "two-cols-table" class in "repository.html".
:::

Elements with the class "mark". Every inline is put in a paragraph of its own:

::: {.include-doc include-src="repository.html" include-pick-classes="mark"}
This placeholder text should be replaced by the elements (blocks as well as inlines) with a "mark" class in "repository.html".
:::
