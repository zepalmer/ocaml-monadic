Developing
----------

This file will contain notes relevant to the development of this library.


Manual Experimentation
======================

To view the output of the `ocaml-monadic` PPX rewriter, a command like the
following is sufficient:

```
ocamlfind ppx_tools/rewriter -ppx _build/src/ocaml_monadic.native test_file.ml
```

This requires the OPAM package `ppx_tools` to be installed.

