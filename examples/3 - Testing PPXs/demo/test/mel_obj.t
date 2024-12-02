[%one]
  $ cat > input.ml << EOF
  > let one = [%one]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let one = 1

[%one]
  $ cat > input.ml << EOF
  > let demo_one = [%one]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  [@@@ocaml.ppwarning "Ops, variable name must not start with demo_"]
  
  let demo_one = 1

[%one]
  $ cat > input.ml << EOF
  > module GameEnum = struct
  >   type t = Rock | Paper | Scissors
  > end [@enum]
  > EOF

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
