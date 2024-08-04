# Context-Free Transformations

## Description

Context-free transformations allow you to read and modify code locally, without needing to consider the global context. In practice, this means that a portion of the Abstract Syntax Tree (AST) is provided to the transformation, and the transformation returns a new AST with the applied modifications.

### Types of Context-Free Transformations

There are two main types of context-free transformations:

1. **[Extenders](https://ocaml-ppx.github.io/ppxlib/ppxlib/driver.html#def_extenders)**: These modify the extension node by generating a new one.
2. **[Derivers](https://ocaml-ppx.github.io/ppxlib/ppxlib/driver.html#def_derivers)**: These append code after the item without changing the original item.

## Extenders

Extenders allow you to replace parts of the code with new content. Let's look at some examples to understand how this works.

On extenders, we have to:
- **Hook the extension.**
- **Transform the payload** (if there is one).
- **Create a new AST.**

### Example 1: A Simple Extender

Consider the following code:

```ocaml
let one = [%one]
(* Output: let one = 1 *)
```

Here, `[%one]` is replaced with the integer value `1`. This is a basic example of an extender transformation.

#### Steps to Implement This Extender:

1. **Declare the extension name:**
   ```ocaml
   let extender_name = "one"
   ```

2. **Define the extender extractor:**
   Since there is no payload (additional data), we define the extractor as:
   ```ocaml
   let extender_extracter = Ast_pattern.(pstr nil)
   ```

3. **Create the new AST:**
   We define the expression that will replace `[%one]`:
   ```ocaml
   let expression ~loc = [%expr 1]
   ```
   Alternatively, you can use:
   ```ocaml
   let expression ~loc = Ast_builder.Default.eint ~loc 1
   ```

4. **Declare the extender using `Extension.V3.declare`:**
   ```ocaml
   let expand ~ctxt =
     let loc = Expansion_context.Extension.extension_point_loc ctxt in
     expression ~loc

   let extension =
     Extension.V3.declare extender_name Extension.Context.expression
       extender_extracter
       expand
   ```

### Example 2: A More Complex Extender with Payload

Let's look at a more complex example, where we replace `[%emoji "grin"]` with an emoji:

```ocaml
let grin = [%emoji "grin"]
(* Output: let grin = "😀" *)
```

#### Steps to Implement This Extender:

1. **Declare the extension name and extractor:**
   Here, the payload is a string (the alias of the emoji):
   ```ocaml
   let extender_name = "emoji"
   let extender_extracter = Ast_pattern.(single_expr_payload (estring __))
   ```

2. **Create the new AST:**
   We define the expression to replace the alias with the corresponding emoji:
   ```ocaml
   let expression ~loc ~emoji = [%expr [%e estring ~loc emoji]]
   ```

3. **Define the expansion logic:**
   We need to map the alias to an emoji and return the appropriate AST. If the alias isn't found, we return an error:
   ```ocaml
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
     | Some value -> expression ~loc ~emoji:value.emoji
     | None ->
         let ext =
           Location.error_extensionf ~loc "No emoji found for alias %s" emoji_text
         in
         Ast_builder.Default.pexp_extension ~loc ext
   ```

4. **Declare the extender:**
   ```ocaml
   let extension =
     Extension.V3.declare extender_name Extension.Context.expression
       extender_extracter
       expand
   ```

---

## Derivers

Derivers are slightly different from extenders. Instead of replacing parts of the code, they append new code after the item without altering the original content.

### Example: Enum Deriver

> :warning: **Note**: The following example is a little more complex. Take your time, it's explained step by step.

Let's say we want to add `to_string` and `from_string` functions to a variant type:

```ocaml
type t = A | B [@@deriving enum]
(* Output:
type t = A | B
let to_string = function
  | A -> "A"
  | B -> "B"
let from_string = function
  | "A" -> Some A
  | "B" -> Some B
  | _ -> None
*)
```

#### Steps to Implement This Deriver:

1. **Declare the deriver name:**
   ```ocaml
   let deriver_name = "enum"
   ```

2. **Define the arguments for the deriver:**
   For this example, we don't have any arguments:
   ```ocaml
   let args () = Deriving.Args.(empty)
   ```

3. **Build the new AST:**
   We'll match the AST we want to transform and generate the `to_string` and `from_string` functions.

   - **Match the type declaration with a pattern matching:**
     ```ocaml
       (* the structure_item we are looking for is a PStr_type *)
       match structure_item with
       | (
          (* Doesn't matter the rec_flag for us *)
           _,
           [
             {
               ptype_name = { txt = type_name; _ };
               ptype_kind = Ptype_variant variants;
               _;
             };
           ] ) -> (* ... *)
       | _ -> (* ... *)
     ```

   - **Create helper functions to generate the patterns:**
     ```ocaml
     let pattern_variant constructor value =
       constructor ~loc { txt = lident value; loc } None
     in

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
     ```

   - **Build the `to_string` function:**
     ```ocaml
     let function_name suffix = type_name ^ suffix in
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
                 [%pat? [%p pattern_variant ppat_construct value]])
               ~expr:(fun value -> [%expr [%e expr_string value]])
               ()]]
     in
     ```

   - **Build the `from_string` function:**
     ```ocaml
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
     let from_string_expr =
       [%stri
         let [%p function_name_pattern] =
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
     ```

   - **Combine and return the functions:**
     ```ocaml
     let enum ~loc structure_item =
       match structure_item with
       | ( _,
           [
             {
               ptype_name = { txt = type_name; _ };
               ptype_kind = Ptype_variant variants;
               _;
             };
           ] ) ->
           let function_name suffix = type_name ^ suffix in
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
             [%pat? [%p ppat_var ~loc { txt = function_name "_to_string"; loc }]]
           in
           let to_string_expr =
             [%stri
               let [%p function_name_pattern] =
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
     ```

4. **Declare the deriver:**
   ```ocaml
   let generator () =
     Deriving.Generator.V2.make (args ()) (fun ~ctxt ->
         enum ~loc:Expansion_context.Deriver.derived_item_loc ctxt)
   let _ = Deriving.add deriver_name ~str_type_decl:(generator ())
   ```

## Conclusion

Context-free transformations are a powerful tool in OCaml for modifying code locally. By understanding how to implement extenders and derivers, you can enhance your code generation capabilities and simplify repetitive tasks. With the examples provided, you should have a solid foundation for creating your own context-free transformations using PPXLib.