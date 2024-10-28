let test title fn = Alcotest.test_case title `Quick fn

let test_one () =
  let one = [%one] in
  Alcotest.check Alcotest.int "should be equal" one 1

module GameEnum = struct
  type t = Rock | Paper | Scissors
end [@enum]

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

let tests =
  ("Sample", [ test "test" test_one; test "enum" test_enum ])
