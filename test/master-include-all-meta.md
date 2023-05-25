---
title: Assembled document
include-sub-meta: true
---

# Title

This is a master document that includes some parts from other documents.

::: {.include-doc include-format="html" include-src="chap1.html"}
This text will be replaced by the contents of \"chap1.html\".
:::

::: {.include-doc include-format="json" include-src="chap2.json"}
This text will be replaced by the contents of \"chap2.json\".
:::

::: {.include-doc include-format="markdown" include-src="chap3.md"}
This text will be replaced by the contents of \"chap3.md\".
:::

::: {.include-doc include-format="markdown" include-src="chap4.md"}
This text will be replaced by the contents of \"chap4.md\".
:::

::: {.include-doc include-format="markdown" include-src="chap5.md"}
This text will be replaced by the contents of \"chap5.md\".
:::
