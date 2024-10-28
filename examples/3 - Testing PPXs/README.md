# Testing PPXs

## Description

Testing PPXs is crucial to ensure that your transformations work as expected and do not introduce bugs into your codebase. This section will guide you through the process of testing PPXs using both implementation tests and snapshot tests.

## Table of Contents

- [Types of Tests](#types-of-tests)
- [Implementation Tests](#implementation-tests)
  - [Example: Testing a Simple Transformation](#example-testing-a-simple-transformation)
  - [Example: Testing a More Complex Transformation](#example-testing-a-more-complex-transformation)
- [Snapshot Tests](#snapshot-tests)
  - [Example: Creating a Snapshot Test](#example-creating-a-snapshot-test)
  - [Example: Snapshot Test for a Module Transformation](#example-snapshot-test-for-a-module-transformation)

## Types of Tests

1. **Implementation Tests**: These tests verify that the PPX transformations produce the expected output for given input code. They are typically written using a testing framework like Alcotest.

2. **Snapshot Tests**: These tests capture the output of a PPX transformation and compare it against a previously saved "snapshot". This is useful for ensuring that changes to the PPX do not unintentionally alter the output.

## Implementation Tests

Implementation tests involve writing test cases that check the behavior of your PPX transformations. You can use a testing framework like Alcotest to write these tests.

### Example: Testing a Simple Transformation

[:link: Sample Code](./demo/test/test_sample.ml#L3-L6)

Consider a PPX that transforms `[%one]` into `1`. You can write a test case to verify this transformation:

```ocaml
let test_one () =
  let one = [%one] in
  Alcotest.check Alcotest.int "should be equal" one 1
````

### Example: Testing a More Complex Transformation

[:link: Sample Code](./demo/test/test_sample.ml#L11-L23)

For a more complex transformation, such as a PPX that generates `to_string` and `from_string` functions for a variant type, you can write a test case like this:

````ocaml
let test_enum () =
  let assert_string left right =
    Alcotest.check Alcotest.string "should be equal" right left
  in
  let rock = GameEnum.to_string Rock in
  let paper = GameEnum.to_string (GameEnum.from_string "Paper") in
  let stick =
    try GameEnum.to_string (GameEnum.from_string "Stick")
    with _ -> "Stick is not a valid value"
  in
  let () = assert_string rock "Rock" in
  let () = assert_string paper "Paper" in
  assert_string stick "Stick is not a valid value"
````

## Snapshot Tests

Snapshot tests are useful for verifying that the output of a PPX transformation remains consistent over time. They involve capturing the output of a transformation and comparing it against a saved snapshot.

### Example: Creating a Snapshot Test

[:link: Sample Code](./demo/test/mel_obj.t#L1-L6)

To create a snapshot test, you can use a tool like `ocamlformat` to format the output of your PPX transformation and compare it against a saved snapshot:

````sh
$ cat > input.ml << EOF
let one = [%one]
EOF

$ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
let one = 1
````

### Example: Snapshot Test for a Module Transformation

[:link: Sample Code](./demo/test/mel_obj.t#L15-L35)

For a more complex transformation, such as a module with a `[@enum]` attribute, you can create a snapshot test like this:

````sh
$ cat > input.ml << EOF
module GameEnum = struct
  type t = Rock | Paper | Scissors
end [@enum]
EOF

$ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
module GameEnum = struct
  type t = Rock | Paper | Scissors

  let from_string value =
    match value with
    | "Rock" -> Rock
    | "Paper" -> Paper
    | "Scissors" -> Scissors
    | _ -> raise (Invalid_argument "Argument doesn't match variants")
  [@@warning "-32"]

  let to_string value =
    match value with
    | Rock -> "Rock"
    | Paper -> "Paper"
    | Scissors -> "Scissors"
  [@@warning "-32"]
end
````

## Conclusion

Testing PPXs is essential to ensure that your transformations are correct and maintainable. By using both implementation tests and snapshot tests, you can verify that your PPX transformations produce the expected output and remain consistent over time.