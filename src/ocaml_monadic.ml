open Ast_mapper;;
open Ast_helper;;
open Asttypes;;
open Parsetree;;
open Location;;
open Longident;;

let mkident name = { txt = Lident name; loc = !default_loc };;

let ghostify loc =
    { loc with loc_ghost = true }
;;

let no_label = "";;

let ocaml_monadic_mapper argv =
    (* We override the expr mapper to catch bind and orzero.  *)
    { default_mapper with
      expr = fun mapper expr ->
        match expr with
        | { pexp_desc =
            Pexp_extension( { txt = "bind"; loc }, payload )
          } ->
          with_default_loc (ghostify loc) @@ fun () ->
          (* Matches "bind"-annotated expressions. *)
          begin
            match payload with
            | PStr [
                { pstr_desc =
                  Pstr_eval(
                    { pexp_desc = Pexp_let(Nonrecursive, value_bindings, body)
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
                  let bind_ident = Exp.ident @@ mkident "bind" in
                  (* This is the function we will be calling. *)
                  let cont_function =
                    Exp.fun_ no_label None bind_pattern body'
                  in
                  (* And finally, here's the wrapped expression. *)
                  Exp.apply bind_ident
                    [ (no_label, mapper.expr mapper bind_expr)
                    ; (no_label, cont_function)
                    ]
                | _ ->
                  (* Nothing left to do.  Just return the body. *)
                  mapper.expr mapper body
              in
              bind_wrap value_bindings
            | _ -> expr
          end
        | { pexp_desc =
            Pexp_extension( { txt = "orzero"; loc }, payload )
          } ->
          with_default_loc (ghostify loc) @@ fun () ->
          (* Matches "orzero"-annotated expressions. *)
          begin
            match payload with
            | PStr [
                { pstr_desc =
                  Pstr_eval(
                    { pexp_desc =
                      Pexp_let(Nonrecursive, value_bindings, body)
                    },
                    []
                  )
                }
              ] ->
              (* This is a let%orzero expression.  It's of the form
                   let%orzero $p1 = $e1 and ... and $pn = $en in $e0
                 and we want it to take the form
                   match $e1 with
                   | $p1 -> (match $e2 with
                             | $p2 -> ...
                                      (match $en with
                                       | $pn -> $e0
                                       | _ -> zero ())
                             | _ -> zero ())
                   | _ -> zero ()
              *)
              let rec orzero_wrap value_bindings' =
                match value_bindings' with
                | { pvb_pat = orzero_pattern
                  ; pvb_expr = orzero_expr
                  ; pvb_attributes = []
                  ; pvb_loc = orzero_loc
                  }::value_bindings'' ->
                  (* This is the name of the "zero" function. *)
                  let zero_ident = Exp.ident @@ mkident "zero" in
                  (* This is the recursive call for the success branch. *)
                  let success_branch = orzero_wrap value_bindings'' in
                  (* For the failure branch, we call zero. *)
                  let unit_value =
                    Exp.construct (mkident "()") None
                  in
                  let failure_branch =
                    Exp.apply zero_ident [(no_label, unit_value)]
                  in
                  Exp.match_ (mapper.expr mapper orzero_expr)
                    [ Exp.case orzero_pattern success_branch
                    ; Exp.case (Pat.any ()) failure_branch
                    ]
                | _ ->
                  (* Nothing left to do.  Just return the body. *)
                  mapper.expr mapper body
              in
              orzero_wrap value_bindings
            | _ -> expr
          end
        | { pexp_desc =
            Pexp_sequence(
              { pexp_desc = Pexp_extension({ txt = "guard" }, payload)
              },
              body_expr
            )
          } ->
          begin
            match payload with
            | PStr [{ pstr_desc = Pstr_eval(guard_expr, attrs) }] ->
              (* This is a sequenced expression with a [%guard ...] extension.  It
                 takes the form
                   [%guard expr']; expr
                 and we want it to take the form
                   if expr' then expr else zero ()
              *)
              let unit_value = Exp.construct (mkident "()") None in
              let zero_ident = Exp.ident @@ mkident "zero" in
              let guard_expr' =
                List.fold_left
                  Exp.attr (default_mapper.expr mapper guard_expr) attrs
              in
              let body_expr' = default_mapper.expr mapper body_expr in
              let zero_invocation =
                Exp.apply zero_ident [(no_label, unit_value)]
              in
              Exp.ifthenelse guard_expr' body_expr' (Some zero_invocation)
            | _ -> expr
          end
        | _ -> default_mapper.expr mapper expr
    }
;;

let () = register "bind" ocaml_monadic_mapper;;
