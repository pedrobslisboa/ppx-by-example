(lang dune 3.8)

(using melange 0.1)

(name ppx-studies)

(license MIT)

(maintainers "Pedro B S Lisboa <pedrobslisboa@gmail.com>")

(authors "Pedro B S Lisboa <pedrobslisboa@gmail.com>")

(source
 (github pedrobslisboa/ppx-studies))

(generate_opam_files true)

(implicit_transitive_deps false)

(package
 (name ppx-studies)
 (synopsis "This project contains examples to help on understanding what are and how to write PPXs in OCaml.")
 (allow_empty)
 (depends
  (ocaml
   (>= 5.0.0))
  alcotest
  ocaml-lsp-server
  ocamlformat
  ppx_deriving
  ppxlib))
