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
 (allow_empty)
 (depends
  (ocaml
   (>= 5.0.0))
  melange
  ocaml-lsp-server
  ocamlformat
  ppxlib
  (ocaml-lsp-server :with-test)))
