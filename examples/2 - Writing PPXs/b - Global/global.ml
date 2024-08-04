open Ppxlib
open Ast_builder.Default

let enum_tag = "enum"

let string_helpers ~loc ast =
  match ast with
  | ( Recursive,
      [
        {
          ptype_name = { txt = name; _ };
          ptype_kind = Ptype_variant variants;
          _;
        };
      ] ) ->
      let pattern_variant constructor value =
        constructor ~loc { txt = lident value; loc } None
      in
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
        [%pat? [%p ppat_var ~loc { txt = "to_string"; loc }]]
      in
      let to_string_expr =
        [%stri
          let[@warning "-32"] [%p function_name_pattern] =
           fun [%p arg_pattern] ->
            [%e
              pat_exp
                ~pat:(fun value ->
                  [%pat? [%p pattern_variant ppat_construct value]])
                ~expr:(fun value -> [%expr [%e expr_string value]])
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
                             ("Argument doesn't match " ^ name ^ " variants")])]
                  []]]
      in
      let function_name_pattern =
        [%pat? [%p ppat_var ~loc { txt = "from_string"; loc }]]
      in
      let from_string_expr =
        [%stri
          let[@warning "-32"] [%p function_name_pattern] =
           fun [%p arg_pattern] ->
            [%e
              pat_exp
                ~pat:(fun value ->
                  [%pat?
                    [%p ppat_constant ~loc (Pconst_string (value, loc, None))]])
                ~expr:(fun value ->
                  [%expr [%e pattern_variant pexp_construct value]])
                ~else_case ()]]
      in
      [ from_string_expr; to_string_expr ]
  | _ ->
      [
        [%stri
          Printf.printf "Ops, the type must only contains variant without args"];
      ]

let traverse =
  object (_ : Ast_traverse.map)
    inherit Ast_traverse.map as super

    method! module_binding mb =
      let mb = super#module_binding mb in
      match (mb.pmb_name, mb.pmb_expr.pmod_attributes) with
      | { txt = Some _; _ }, [ { attr_name = { txt = "enum"; _ }; _ } ] -> (
          match mb.pmb_expr.pmod_desc with
          | Pmod_structure
              ([ { pstr_desc = Pstr_type (name, variants); _ } ] as str) ->
              let type_ =
                string_helpers ~loc:mb.pmb_expr.pmod_loc (name, variants)
              in
              Ast_builder.Default.module_binding ~loc:mb.pmb_loc
                ~name:{ txt = mb.pmb_name.txt; loc = mb.pmb_name.loc }
                ~expr:
                  (Ast_builder.Default.pmod_structure
                     ~loc:mb.pmb_expr.pmod_loc (str @ type_))
          | _ -> mb)
      | _ -> mb
  end

let _ = Driver.register_transformation "enum" ~impl:traverse#structure
