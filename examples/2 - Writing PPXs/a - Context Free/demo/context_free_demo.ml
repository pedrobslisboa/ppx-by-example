type tree = Leaf | Node [@@deriving enum]

let _ = Node
let _ = Leaf

let _ = Printf.printf "Leaf to string: %s\n" (tree_to_string (tree_from_string "Leaf"))
let _ = Printf.printf "Node to string: %s\n" (tree_to_string (tree_from_string "Node"))

let one = [%one]
let _ = Printf.printf "One: %d\n" one

let grin = [%emoji "grin"]
let smiley = [%emoji "smiley"]
let _ = print_endline ("grin: " ^ grin)
let _ = print_endline ("smiley: " ^ smiley)