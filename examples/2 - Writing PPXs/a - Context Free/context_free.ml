open Ppxlib
open Ast_builder.Default

(* PPX Extender *)
let structure_item ~loc = [%expr 1]

let expand ~ctxt =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  structure_item ~loc

type emoji = { emoji : string; alias : string }

let my_extension =
  Extension.V3.declare "one" Extension.Context.expression
    Ast_pattern.(pstr nil)
    expand

let rule = Ppxlib.Context_free.Rule.extension my_extension
let () = Driver.register_transformation ~rules:[ rule ] "one"

(* PPX Extender with payload *)
let pattern = Ast_pattern.(single_expr_payload (estring __))
let expression ~loc ~value = [%expr [%e estring ~loc value]]

let emojis =
  [
    { emoji = "😀"; alias = "grin" };
    { emoji = "😃"; alias = "smiley" };
    { emoji = "😄"; alias = "smile" };
  ]

let expand ~ctxt emoji_text =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in

  let find_emoji_by_alias alias =
    List.find_opt (fun emoji -> alias = emoji.alias) emojis
  in

  match find_emoji_by_alias emoji_text with
  | Some value -> expression ~loc ~value:value.emoji
  | None ->
      let ext =
        Location.error_extensionf ~loc "No emoji for %s alias" emoji_text
      in
      Ast_builder.Default.pexp_extension ~loc ext

let my_extension =
  Extension.V3.declare "emoji" Extension.Context.expression pattern expand

(* PPX Deriver *)
let rule = Ppxlib.Context_free.Rule.extension my_extension
let () = Driver.register_transformation ~rules:[ rule ] "emoji"
let args () = Deriving.Args.(empty)

(* add to_string and from_string helpers to a type variant *)
let enum ~ctxt ast =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  match ast with
  | ( _,
      [
        {
          ptype_name = { txt = type_name; _ };
          ptype_kind = Ptype_variant variants;
          _;
        };
      ] ) ->
      let function_name suffix = type_name ^ suffix in
      let expr_string = Ast_builder.Default.estring ~loc in
      let pat_exp ~pat ~expr ?else_case () =
        let cases =
          List.map
            (fun { pcd_name = { txt = value; _ }; _ } ->
              case ~lhs:(pat value) ~guard:None ~rhs:(expr value))
            variants
        in
        let cases =
          match else_case with
          | Some else_case -> cases @ [ else_case ]
          | None -> cases
        in
        [%expr [%e pexp_match ~loc [%expr value] cases]]
      in
      let arg_pattern = [%pat? value] in
      let function_name_pattern =
        [%pat? [%p ppat_var ~loc { txt = function_name "_to_string"; loc }]]
      in
      let to_string_expr =
        [%stri
          let [%p function_name_pattern] =
           fun [%p arg_pattern] ->
            [%e
              pat_exp
                ~pat:(fun value ->
                  ppat_construct ~loc (Located.lident ~loc value) None)
                ~expr:(fun value -> expr_string value)
                ()]]
      in
      let else_case =
        case
          ~lhs:[%pat? [%p ppat_any ~loc]]
          ~guard:None
          ~rhs:
            [%expr
              [%e
                pexp_apply ~loc
                  [%expr
                    raise
                      (Invalid_argument
                         [%e
                           estring ~loc
                             ("Argument doesn't match " ^ type_name
                            ^ " variants")])]
                  []]]
      in
      let function_name_pattern =
        [%pat? [%p ppat_var ~loc { txt = function_name "_from_string"; loc }]]
      in
      let from_string_expr =
        [%stri
          let [%p function_name_pattern] =
           fun [%p arg_pattern] ->
            [%e
              pat_exp
                ~pat:(fun value ->
                  ppat_constant ~loc (Pconst_string (value, loc, None)))
                ~expr:(fun value ->
                  pexp_construct ~loc (Located.lident ~loc value) None)
                ~else_case ()]]
      in
      [ from_string_expr; to_string_expr ]
  | _ ->
      [
        [%stri
          Printf.printf "Ops, the type must only contains variant without args"];
      ]

let generator () = Deriving.Generator.V2.make (args ()) enum
let _ = Deriving.add "enum" ~str_type_decl:(generator ())
