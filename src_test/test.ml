exception Test_failure of string;;

let string_of_list f xs =
  List.fold_left
    (fun a e -> if a = "" then f e else a ^ ", " ^ f e)
    ""
    xs
;;

module NondeterminismMonad = struct
  let return x = [x];;
  let bind m k = List.concat (List.map k m);;
end;;

let nondeterminism_test =
  let open NondeterminismMonad in
  let%bind x = [1;2;3] in
  let%bind y = [4;5] in
  return (x+y)
;;

let nested_bind_test =
  let open NondeterminismMonad in
  let%bind x =
    let%bind y = [1;2;3] in
    return (y+1)
  in
  return (x+1)
;;

let halt_with s = print_endline s; exit 1;;

let () =
  begin
    match nondeterminism_test with
    | [5;6;6;7;7;8] -> ()
    | _ ->
      halt_with
        ("Unexpected value from nondeterminism test: " ^
          string_of_list string_of_int nondeterminism_test)
  end;
  begin
    match nested_bind_test with
    | [3;4;5] -> ()
    | _ ->
      halt_with
      ("Unexpected value from nested_bind test: " ^
          string_of_list string_of_int nested_bind_test)
  end;
  print_endline "All tests passed."
;;

