# Writing PPXs

## Description

After knowing how to build an AST and destructure it, we can now write your own PPX in OCaml.

## Transformations

The soul of a PPX is the transformation. We want to get our AST and transform it into something like a new AST or errors.

Those transformations can be divided into two categories that we will cover on nested folders:

- [Context-free transformations](./a%20-%20Context%20Free/README.md)
- [Global transformations](./b%20-%20Global/README.md)

And they can work in different phases:

- Lint (Global)
- Preprocess (Global)
- Instrumentation - Before (Global)
- Context-free
- Global Trasformation (Global)
- Instrumentation - After (Global)

The following diagram shows the order of the phases and Driver's methods:
<figure>
  <img
  src="./ppxlib-phases.png"
  alt="The beautiful MDN logo.">
  <figcaption><a href="https://x.com/_anmonteiro/status/1644031054544789504">https://x.com/_anmonteiro/status/1644031054544789504</a></figcaption>
</figure>

## How

PPXs commonly follow these steps:

- Match the AST we want.
- Work with the AST. For example:
  - Returning a new AST. Add new functions, change the name of a variable, etc.
  - Linting the code.
  - or doing anything else. Really, you're programming, everything is possible!

On the next folders, we will show you how to write a PPX on every transformation type and phase.