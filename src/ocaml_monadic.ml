
let () =
  Migrate_parsetree.Driver.register ~name:"ocaml-monadic" Migrate_parsetree.Versions.ocaml_404
    (fun _config _cookies -> Ocaml_monadic_ppx.ocaml_monadic_mapper)
;;
