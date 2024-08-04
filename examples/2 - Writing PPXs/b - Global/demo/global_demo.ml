module GameEnum = struct
  type t = Rock | Paper | Scissors
end [@enum]

let _ = print_endline (GameEnum.to_string Rock)
let _ = print_endline (GameEnum.to_string (GameEnum.from_string "Paper"))
