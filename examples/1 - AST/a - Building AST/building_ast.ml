open Ppxlib

let loc = Location.none

let zero ~loc : Ppxlib_ast.Ast.expression =
  {
    pexp_desc = Pexp_constant (Pconst_integer ("0", None));
    pexp_loc = loc;
    pexp_loc_stack = [];
    pexp_attributes = [];
  }

let of_string_opt_expr ~loc fn name =
  Ast_builder.Default.value_binding ~loc
    ~pat:(Ast_builder.Default.pvar ~loc name)
    ~expr:
      (Ast_builder.Default.eapply ~loc
         (Ast_builder.Default.evar ~loc fn)
         [ Ast_builder.Default.evar ~loc name ])

let rec of_string_exp_let ~loc types =
  match types with
  | [] -> Ast_builder.Default.eunit ~loc
  | (name, type_) :: rest ->
      let of_string = of_string_opt_expr ~loc (type_ ^ "_of_string_opt") name in
      let of_string =
        Ast_builder.Default.pexp_let ~loc Nonrecursive [ of_string ]
          (of_string_exp_let ~loc rest)
      in
      of_string

let of_path_stri ~loc types =
  [%stri let of_path path = [%e of_string_exp_let ~loc types]]

let module_ =
  Ast_builder.Default.module_binding ~loc
    ~name:{ txt = Some "Routes"; loc }
    ~expr:
      (Ast_builder.Default.pmod_structure ~loc
         ([%stri type t] :: [ of_path_stri ~loc [ ("foo", "name") ] ]))

let _ =
  print_endline
    ("\nAST with AST pure tree build: "
    ^ Astlib.Pprintast.string_of_structure
        [ Ast_builder.Default.pstr_module ~loc module_ ])

let _ =
  print_endline
    ("\nAST with AST pure tree build: "
    ^ Astlib.Pprintast.string_of_expression (zero ~loc))

let one ~loc =
  Ast_builder.Default.pexp_constant ~loc (Parsetree.Pconst_integer ("1", None))

let _ =
  print_endline
    ("\nAST with AST build pexp_constant: "
    ^ Astlib.Pprintast.string_of_expression (one ~loc))

let two ~loc = Ast_builder.Default.eint ~loc 2

let _ =
  print_endline
    ("\nAST with AST build eint: "
    ^ Astlib.Pprintast.string_of_expression (two ~loc))

let three ~loc = [%expr 3]

let _ =
  print_endline
    ("\nAST with AST build eint: "
    ^ Astlib.Pprintast.string_of_expression (three ~loc))

let let_expression =
  let expression =
    Ast_builder.Default.pexp_constant ~loc:Location.none
      (Pconst_integer ("3", None))
  in
  let pattern =
    Ast_builder.Default.ppat_var ~loc:Location.none
      (Ast_builder.Default.Located.mk ~loc:Location.none "foo")
  in
  let let_binding =
    Ast_builder.Default.value_binding ~loc:Location.none ~pat:pattern
      ~expr:expression
  in

  Ast_builder.Default.pexp_let ~loc:Location.none Nonrecursive [ let_binding ]
    (Ast_builder.Default.eunit ~loc:Location.none)

let _ =
  print_endline
    ("\nLet expression with Ast_builder: "
    ^ Astlib.Pprintast.string_of_expression let_expression)

let let_expression =
  [%expr
    let foo = 3 in
    ()]

let _ =
  print_endline
    ("\nLet expression with metaquot: "
    ^ Astlib.Pprintast.string_of_expression let_expression)

let anti_quotation_expr expr = [%expr 1 + [%e expr]]

let _ =
  print_endline
    ("\nLet expression with metaquot and anti-quotation: "
    ^ Astlib.Pprintast.string_of_expression (anti_quotation_expr (one ~loc)))

let _ =
  print_endline
    ("\nAccess ./ast_playground.ml to play with ast"
    ^ Astlib.Pprintast.string_of_expression (anti_quotation_expr (one ~loc)))