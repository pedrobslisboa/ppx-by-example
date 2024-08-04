# Building AST

## Description

Building an AST (Abstract Syntax Tree) is the core of creating a PPX. When creating a PPX, you'll need to build an AST to represent the code you want to generate.

For example, let's say you want to generate the following code:
```ocaml
let zero = [%int 0]
```
To replace `[%int 0]` with `0` to have `let zero = 0`, you'll need to build an AST that represents the code above.

There are many ways to build an AST. Here we'll talk about these three methods:

- Using `AST_builder` Low-Level Builders
- Using `AST_builder` High-Level Builders
- Using `Metaquot`

### Using `AST_builder` Low-Level Builders

The most basic way to build an AST with PPXLib is to use Low-Level Builders. Let's say we want to build a simple `0` integer AST:
```ocaml
({
    pexp_desc = (Pexp_constant (Pconst_integer ("0", None)));
    pexp_loc = loc;
    pexp_loc_stack = [];
    pexp_attributes = []
} : Ppxlib_ast.Ast.expression)
```
As you can see, it is very verbose and difficult to read and maintain.

### Using `AST_builder` Module

PPXLib provides a module called `AST_builder` that offers a set of functions to build ASTs. In the end, it's a wrapper around Low-Level Builders, but it's more readable.

Let's say we want to build a simple `1` integer AST. We can do it by using the `pexp_constant` function:
```ocaml
AST_builder.Default.pexp_constant ~loc (Pconst_integer ("1", None))
```
But it's still verbose, so we can use some abstractions that `AST_builder` provides:
```ocaml
let two ~loc = AST_builder.Default.eint ~loc 2
```

There are many abstraction functions that can be used to build ASTs. You can find them in the [documentation](https://ocaml-ppx.github.io/ppxlib/ppxlib/Ppxlib/AST_builder/Default/index.html).

> Note: `eint` stands for expression (`e`) integer (`int`).

### Using Metaquot

Metaquot is a syntax extension that allows you to write ASTs in a more readable way.

Let's say we want to build a simple `3` integer AST. We can do it by using the following syntax:
```ocaml
[%expr 3]
```
As we can see, Metaquot is the most readable way to build ASTs.
But it is constant/static. What if we would like to have dynamic values? 
Then we can use Anti-Quotations.

> :bulb: Anti-Quotations are used to insert values into the AST.
> There are many sintaxes for Anti-Quotations, check the [documentation](https://ocaml-ppx.github.io/ppxlib/ppxlib/generating-code.html#:~:text=The%20syntax%20for,won%27t%20be%20rewritten.).

Here is an example of how to use Anti-Quotations:
```ocaml
let some_expression expression = [%expr [%e expression]]
```
Where `%e` is the syntax for expressions. 

## Conclusion

In this section, we learned how to build ASTs using Low-Level Builders, High-Level Builders, and Metaquot. We also learned that Metaquot is the most readable way to build ASTs. There is no wrong or right way to build ASTs; it's up to you to choose the one that fits best for your use case. However, it's worthwhile to understand all of them as part of your learning process.