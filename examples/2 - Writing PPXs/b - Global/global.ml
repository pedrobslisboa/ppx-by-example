open Ppxlib
open Ast_builder.Default

let enum_tag = "enum"

(* This function is well explained in the Context Free Section *)
let enum ~loc ?(opt = false) ast () =
  match ast with
  | _, [ { ptype_kind = Ptype_variant variants; _ } ] ->
      let expr_string = Ast_builder.Default.estring ~loc in
      let to_string_expr =
        [%stri
          let[@warning "-32"] to_string value =
            [%e
              pexp_match ~loc [%expr value]
                (List.map
                   (fun { pcd_name = { txt = value; _ }; _ } ->
                     case
                       ~lhs:
                         (ppat_construct ~loc (Located.lident ~loc value) None)
                       ~guard:None ~rhs:(expr_string value))
                   variants)]]
      in
      let else_case =
        case
          ~lhs:[%pat? [%p ppat_any ~loc]]
          ~guard:None
          ~rhs:
            (match opt with
            | true -> [%expr None]
            | _ ->
                [%expr
                  raise (Invalid_argument "Argument doesn't match variants")])
      in
      let from_string_expr =
        [%stri
          let[@warning "-32"] from_string value =
            [%e
              pexp_match ~loc [%expr value]
                (List.map
                   (fun { pcd_name = { txt = value; _ }; _ } ->
                     case
                       ~lhs:
                         (ppat_constant ~loc (Pconst_string (value, loc, None)))
                       ~guard:None
                       ~rhs:
                         (match opt with
                         | true ->
                             [%expr
                               Some
                                 [%e
                                   pexp_construct ~loc
                                     (Located.lident ~loc value)
                                     None]]
                         | _ ->
                             pexp_construct ~loc
                               (Located.lident ~loc value)
                               None))
                   variants
                @ [ else_case ])]]
      in
      [ from_string_expr; to_string_expr ]
  | _ ->
      [%str
        [%ocaml.error "Ops, enum2 must be a type with variant without args"]]

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
              let type_ = enum ~loc:mb.pmb_expr.pmod_loc (name, variants) () in
              Ast_builder.Default.module_binding ~loc:mb.pmb_loc
                ~name:{ txt = mb.pmb_name.txt; loc = mb.pmb_name.loc }
                ~expr:
                  (Ast_builder.Default.pmod_structure ~loc:mb.pmb_expr.pmod_loc
                     (str @ type_))
          | _ -> mb)
      | _ -> mb
  end

let _ = Driver.register_transformation "enum" ~impl:traverse#structure

module PreProcess = struct
  let traverse =
    object (_ : Ast_traverse.map)
      inherit Ast_traverse.map as super

      method! module_binding mb =
        let mb = super#module_binding mb in
        match (mb.pmb_name, mb.pmb_expr.pmod_attributes) with
        | ( { txt = Some _; _ },
            [ { attr_name = { txt = "enum2"; _ }; attr_payload = payload; _ } ]
          ) -> (
            let opt =
              match payload with PStr [%str opt] -> true | _ -> false
            in
            match mb.pmb_expr.pmod_desc with
            | Pmod_structure
                ([ { pstr_desc = Pstr_type (name, variants); _ } ] as str) ->
                let type_ =
                  enum ~loc:mb.pmb_expr.pmod_loc ~opt (name, variants) ()
                in
                Ast_builder.Default.module_binding ~loc:mb.pmb_loc
                  ~name:{ txt = mb.pmb_name.txt; loc = mb.pmb_name.loc }
                  ~expr:
                    (Ast_builder.Default.pmod_structure
                       ~loc:mb.pmb_expr.pmod_loc (str @ type_))
            | _ -> mb)
        | _ -> mb
    end
end

module Lint = struct
  let catch_all_pattern_found cases =
    List.exists
      (fun case ->
        match case.pc_lhs.ppat_desc with Ppat_any -> true | _ -> false)
      cases

  let traverse =
    object
      inherit [Driver.Lint_error.t list] Ast_traverse.fold

      method! module_binding mb acc =
        let loc = mb.pmb_loc in
        match
          (mb.pmb_name, mb.pmb_expr.pmod_desc, mb.pmb_expr.pmod_attributes)
        with
        | ( _,
            Pmod_structure [ { pstr_desc = Pstr_type (_, _); _ }; _ ],
            [ { attr_name = { txt = "enum"; _ }; _ } ] ) ->
            print_endline "Found enum";
            Driver.Lint_error.of_string loc
              "Ops, enum must be used on a simple module struct with only one \
               type variant"
            :: acc
        | _ -> acc
    end
end

let _ =
  Driver.register_transformation "enum2"
    ~lint_impl:(fun st -> Lint.traverse#structure st [])
    ~impl:PreProcess.traverse#structure
