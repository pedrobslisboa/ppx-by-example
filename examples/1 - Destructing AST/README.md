# Destructuring AST

## Description

Destructuring AST is the core of creating a PPX (preprocessor extension) in OCaml. When creating a PPX, you'll need to destructure an AST to read the code you want to generate.

For example, let's say you want to generate the following code:
```ocaml
let zero = [%int 0]
```

To replace `[%int 0]` with `0` to have `let zero = 0`, you'll need to destructure an AST that represents the code above.

There are many ways to destructure an AST. Here we'll discuss these three methods:

- AST structure pattern matching
- Using `Ast_pattern` High-Level Destructors
- Using Metaquot

### AST Structure Pattern Matching

The most basic way to destructure an AST with PPXLib is to use AST structure pattern matching. Let's say we want to destructure a simple `0` integer AST:

Here's an improved and more detailed step-by-step explanation of the code:

```ocaml
let match_int_payload ~loc payload =
  match payload with
  | PStr
      [
        {
          pstr_desc =
            Pstr_eval
              ({
                 pexp_desc = Pexp_constant (Pconst_integer (value, None));
                 _;
               }, _);
          _;
        };
      ] -> (try Ok (value |> int_of_string) with Failure _ -> Error (Location.Error.createf ~loc "Value is not a valid integer"))
  | _ -> Error (Location.Error.createf ~loc "Wrong pattern")
```

> :pencil: Step-by-Step Explanation of the code above:
> 
> 1. **Pattern Matching the Payload**:
>    - `match payload with` begins the pattern matching on the `payload`.
>    - `PStr [...]` matches the payload, assuming it is a structure (`PStr`). (Payload(P) Structure(Str))
>    - The structure is expected to contain a list with one item, indicated by `[ ... ]`.
>
> 2. **Destructuring the Structure Item**:
>    - `{ ... }` within the list pattern matches the single structure item.
>    - `pstr_desc = Pstr_eval (...)` specifies that the `pstr_desc` field of the structure item should be `Pstr_eval`, indicating an evaluated expression.
>
> 3. **Extracting the Expression**:
>    - `Pstr_eval ({ pexp_desc = Pexp_constant (Pconst_integer (value, None)); ... }, _)`:
>      - The `Pstr_eval` node contains an expression.
>      - `pexp_desc = Pexp_constant (Pconst_integer (value, None))` matches the expression description, expecting it to be a constant integer (`Pconst_integer`).
>      - `value` captures the integer value as a string.
>      - `None` ensures that there is no suffix for the integer.
>    - `_` ignores other fields in the expression and structure item as they are not needed.
>
> 4. **Handling the Matched Value**:
>    - `try Ok (value |> int_of_string) with Failure _ -> Error (Location.Error.createf ~loc "Value is not a valid integer")`:
>      - Attempts to convert the `value` (captured as a string) to an integer using `int_of_string`.
>      - If successful, returns `Ok` with the integer value.
>      - If the conversion fails (`Failure _`), returns an `Error` with a message indicating the value is not a valid integer.
>
> 5. **Handling Mismatched Patterns**:
>    - `_ -> Error (Location.Error.createf ~loc "Wrong pattern")`:
>      - If the `payload` does not match the expected structure (`PStr` with a single `Pstr_eval` containing a `Pexp_constant` integer), it returns an `Error` with a message indicating the wrong pattern.

This detailed explanation provides a clear understanding of each step in the pattern matching and destructuring process, highlighting how the AST is navigated and how specific parts are extracted and processed.

As you can see, it is very verbose and difficult to read and maintain.

There are many variants for the payload representation, and many are different from `Pstr_eval`. We'll look at some of them later.

### Using `Ast_pattern` High-Level Destructors

To provide a more readable way to destructure an AST, PPXLib provides the `Ast_pattern`. Let's say we want to destructure a simple `0` integer AST:
```ocaml
open Ppxlib

let match_int_payload =
  let open Ast_pattern in
  pstr (pstr_eval (pexp_constant (pconst_integer __ none)) nil ^:: nil)
```

As you can see, we have all the same information as the previous example, but in a more readable way.
- `PStr` -> `pstr`
- `Pstr_eval` -> `pstr_eval`
- `Pexp_constant` -> `pexp_constant`
- `Pconst_integer` -> `pconst_integer`
- `value` -> `__` (wildcard)
- `None` -> `none` (no suffix)

Another way to achieve this is:
```ocaml
let match_int_payload =
  let open Ast_pattern in
  pstr (pstr_eval (eint __) nil ^:: nil)
```

It's better to use `eint` instead of `pexp_constant` and `pconst_integer` because it provides better type safety. The `__` wildcard will expect to receive the label value (a string).

An alternative to ensure type safety while using `pexp_constant` and `pconst_integer` is:
```ocaml
let match_int_payload =
  let open Ast_pattern in
  pstr (pstr_eval (pexp_constant (pconst_integer __ none)) nil ^:: nil)

let test_match_pstr_eval () =
  let loc = Location.none in
  let structure_item = structure_item loc in
  let structure = [structure_item] in
  match Ast_pattern.parse match_int_payload loc (PStr structure) (fun value -> 
    try Ok (int_of_string value)
    with Failure _ -> Error (Location.Error.createf ~loc "Value is not a valid integer")
  ) with
  | Ok value ->
    Printf.printf "Matched pstr_eval with integer using Ast_pattern: %d\n" value
  | Error _ ->
    Printf.printf "Did not match pstr_eval\n"
```

As you can see, in the `parse` code, we handle the value as a string so we can convert it to an integer in the callback function.

This README now provides a clearer and more concise explanation of how to destructure an AST using different methods in PPXLib.

### Using Metaquot

As we've seen in the previous examples, Metaquot is a syntax extension that allows you to write ASTs in a more readable way. 
Let's say we want to destructure a simple `0` integer AST:
```ocaml
let match_int_payload expr =
  match expr with
  | [%expr 0] -> Ok 0
```

But it is constant/static. What if we would like to capture the int dynamically? 
Then we can use Anti-Quotations.

> :bulb: Anti-Quotations are used to insert patterns into the AST.
> There are many sintaxes for Anti-Quotations, check the [documentation](https://ocaml-ppx.github.io/ppxlib/ppxlib/matching-code.html#:~:text=The%20syntax%20for,in%0Ado_something_with%20sigi2).

For example, let's say we want to destructure match all `1 + <int>`:
```ocaml
let match_int_payload expr =
  match expr with
  | [%expr 1 + [%e? e]] -> (
      match e with
      | { pexp_desc = Pexp_constant (Pconst_integer (value, None)); _ } ->
          Ok (1 + (int_of_string value))
      | _ ->
          Error
            (Location.Error.createf ~loc:e.pexp_loc
               "Value is not a valid integer"))
  | _ -> Error (Location.Error.createf ~loc:expr.pexp_loc "Wrong pattern")
```

As you can see, we still have to use the `Pexp_constant` and `Pconst_integer` constructors, but the metaquot syntax makes long and complexy AST strucutures more readable as we don't have to declare the destructuring pattern for `1 +  `, only the pattern we want to capture.

Let's compare it with Ast_pattern:
```ocaml
let match_int_payload =
  let open Ast_pattern in
  pstr (pstr_eval (pexp_apply (eint 1) (Nolabel, eint __)) nil ^:: nil)
```

As you can see, the metaquot syntax is more readable and clear.

## Conclusion

This README provides a detailed explanation of how to destructure an AST using different methods in PPXLib, including AST structure pattern matching, `Ast_pattern` high-level destructors, and metaquot. There is no wrong or right way to build ASTs; it's up to you to choose the one that fits best for your use case. However, it's worthwhile to understand all of them as part of your learning process.