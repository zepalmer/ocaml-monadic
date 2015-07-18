# ocaml-monadic
Lightweight PPX extension for OCaml to support natural monadic syntax.

## Purpose
At the time of this writing, the PPX syntax extensions for monads available in the OPAM repositories are largely invested in providing a monadic syntax which looks similar to that of Haskell.  While this syntax is familiar, it is also quite different from OCaml's syntax (and even from Haskell's non-monadic syntax), leading to a well-known difficulty in transitioning existing code to and from monadic form.  This syntax extension aims to provide a monadic syntax which blends more readily with that of OCaml.

## Usage
The only syntax extension provided by this library is the `let%bind` syntax.  This syntax applies only to non-recursive `let` expressions.  For instance, the code
  ```ocaml
  let%bind x = [1;2;3] in
  let%bind y = [4;5;6] in
  return (x + y)
  ```
desugars to
  ```ocaml
  bind [1;2;3] (fun x ->
    bind [4;5;6] (fun y ->
      return (x+y)
    )
  )
  ```
The functions `bind` and `return` are assumed to be defined in local scope; this may occur in any fashion but is most easily accomplished with a local open (e.g. `let open MyMonad in`).

## Dependents
To use this library in your project, it suffices to depend upon it via `ocamlfind`.  The `lib/META` file ensures that ocamlfind will apply the PPX extension.  In an `_oasis` file, for instance, it suffices to list this library as a build dependency.
