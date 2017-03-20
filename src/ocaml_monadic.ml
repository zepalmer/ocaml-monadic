
let () =
  Ast_mapper.register
    "bind"
    Ocaml_monadic_ppx.ocaml_monadic_mapper
;;
