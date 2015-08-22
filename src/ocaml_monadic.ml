open Ast_mapper;;
open Ast_helper;;
open Asttypes;;
open Parsetree;;
open Location;;
open Longident;;

let ghostify loc =
    { loc with loc_ghost = true }
;;

let no_label = "";;

let ocaml_monadic_mapper argv =
    (* We override let%bind expressions to call the "bind" in context. *)
    { default_mapper with
      expr = fun mapper expr ->
        match expr with
        | { pexp_desc =
            Pexp_extension( { txt = "bind"; loc }, payload )
          } ->
          (* Matches "bind"-annotated expressions. *)
          begin
            match payload with
            | PStr [
                { pstr_desc =
                  Pstr_eval(
                    { pexp_desc =
                      Pexp_let(
                        Nonrecursive,
                        value_bindings,
                        body
                      )
                    },
                    []
                  )
                }
              ] ->
              (* This is a let%bind expression!  It's of the form
                   let%bind $p1 = $e1 and ... and $pn = $en in $e0
                 and we want it to take the form
                   bind $e1 (fun $p1 -> ... bind $en (fun $pn -> ...) ...)
              *)
              let rec bind_wrap value_bindings' =
                match value_bindings' with
                | { pvb_pat = bind_pattern
                  ; pvb_expr = bind_expr
                  ; pvb_attributes = []
                  ; pvb_loc = bind_loc
                  }::value_bindings'' ->
                  (* Recurse and then wrap the resulting body. *)
                  let body' = bind_wrap value_bindings'' in
                  (* This is the name of the "bind" function. *)
                  let bind_ident =
                    { pexp_attributes = []
                    ; pexp_loc = ghostify bind_loc
                    ; pexp_desc = Pexp_ident({
                        txt = Lident "bind";
                        loc = ghostify bind_loc
                      })
                    }
                  in
                  (* This is the function we will be calling. *)
                  let cont_function =
                    { pexp_attributes = []
                    ; pexp_loc = ghostify bind_loc
                    ; pexp_desc = Pexp_fun(no_label, None, bind_pattern, body')
                    }
                  in
                  (* And finally, here's the wrapped expression. *)
                  { pexp_attributes = []
                  ; pexp_loc = bind_loc
                  ; pexp_desc =
                    Pexp_apply(
                      bind_ident,
                      [ (no_label, mapper.expr mapper bind_expr)
                      ; (no_label, cont_function)
                      ]
                    )
                  }
                | _ ->
                  (* Nothing left to do.  Just return the body. *)
                  mapper.expr mapper body
              in
              bind_wrap value_bindings
            | _ -> expr
          end
        | _ -> default_mapper.expr mapper expr
    }
;;

let () = register "bind" ocaml_monadic_mapper;;

