# Global Transformations

This section contains code examples to help you understand how to implement global transformations in OCaml using PPXLib.  
To run the examples:

```sh
make demo-global
```

### Table of Contents

- [Description](#description)
- [Implementing Global Transformations](#implementing-global-transformations)
  - [Example 1: Extending a Module with the `[@enum]` Attribute](#example-1-extending-a-module-with-the-enum-attribute)
  - [Example 2: Extending a Module with the `[@enum2 ~opt]` Attribute](#example-2-extending-a-module-with-the-enum2-opt-attribute)
- [Using `Ast_traverse`](#using-ast_traverse)
- [Linting with PPX](#linting-with-ppx)
  - [Example 1: Linting with `[@enum]`](#example-1-linting-with-enum)
  - [Example 2: Linting with `[@enum2]`](#example-2-linting-with-enum2)
- [Conclusion](#conclusion)

## Description

As we saw in the [Writing PPXs section](../README.md), global transformations are a powerful way to automate tasks that affect entire modules or large sections of code. By extending the principles of context-free transformations to operate at the module level, you can implement transformations that significantly reduce boilerplate and improve code consistency.

### Types of Global Transformations

- Lint
- Preprocess
- Instrumentation - Before
- Global Trasformation
- Instrumentation - After

## Implementing Global Transformations

### Example 1: Extending a Module with the `[@enum]` Attribute 
:link: [Sample Code](./context_free.ml#L5-L17)

Let's say we want to extend a module with automatically generated `to_string` and `from_string` functions based on a variant type using the `[@enum]` attribute.

#### Consider the following example:

```ocaml
module GameEnum = struct
  type t = Rock | Paper | Scissors
end [@enum]
(* Output:
module GameEnum = struct
  type t = Rock | Paper | Scissors
  let to_string = function
    | Rock -> "Rock"
    | Paper -> "Paper"
    | Scissors -> "Scissors"
  let from_string = function
    | "Rock" -> Rock
    | "Paper" -> Paper
    | "Scissors" -> Scissors
    | _ -> failwith "Invalid string"
end *)
```

#### Steps to Implement This Transformation:

- **Declare the Enum Tag and Function:**  
  Define a function that generates the `to_string` and `from_string` functions. This function's structure is similar to what we covered in the [Context-Free Transformations](../b%20-%20Context-Free/README.md) section. The only difference is that this function operates at the module level.

- **Override the `module_binding` Method:**  
  Use the `module_binding` method in an `Ast_traverse` object to scan the AST for module bindings with the `[@enum]` attribute and append the generated functions to the module structure. This expands on the principles covered in context-free transformations by applying them globally.

- **Register the Transformation:**  
  Finally, register the transformation with the PPX driver to automate its application during compilation.

### Example 2: Extending a Module with the `[@enum2 ~opt]` Attribute 
:link: [Sample Code](./context_free.ml#L126-L216)

Now, let's extend the previous example to include an `opt` argument in the `[@enum2]` attribute. This argument modifies the behavior of the `from_string` function to return an `option` type instead of raising an exception.

#### Consider the following example:

```ocaml
module GameEnum = struct
  type t = Rock | Paper | Scissors
end [@enum2 ~opt]
(* Output:
module GameEnum = struct
  type t = Rock | Paper | Scissors
  let to_string = function
    | Rock -> "Rock"
    | Paper -> "Paper"
    | Scissors -> "Scissors"
  let from_string = function
    | "Rock" -> Some Rock
    | "Paper" -> Some Paper
    | "Scissors" -> Some Scissors
    | _ -> None
end *)
```

#### Steps to Implement This Transformation:

- **Modify the Enum Function:**  
  Extend the function to include an optional `opt` argument that alters the behavior of the `from_string` function. This follows the same logic as the [Enum Deriver with args](../b%20-%20Context-Free/README.md#example-2-enum-deriver-with-args) example from the Context-Free section.

- **Update the `module_binding` Method:**  
  Enhance the `module_binding` method to handle the `[@enum2]` attribute and check for the `opt` argument, applying the appropriate changes to the `from_string` function.

- **Register the Transformation:**  
  As before, register the transformation with the PPX driver to ensure it is applied automatically during compilation.

## Using `Ast_traverse`

`Ast_traverse` is a powerful tool in PPXLib that allows you to traverse and transform the AST in a structured way. It's particularly useful for global transformations where you need to modify entire modules or large sections of code.

### How It Works:

`Ast_traverse` provides an object-oriented API for recursively visiting and transforming AST nodes. By inheriting from the `Ast_traverse.map` class, you can override methods corresponding to specific AST nodes (e.g., `module_binding`, `structure_item`, etc.) to implement custom transformations.

In the examples above, the `module_binding` method is overridden to identify modules with the `[@enum]` or `[@enum2]` attribute. The transformation is then applied to these modules, generating the necessary `to_string` and `from_string` functions and appending them to the module structure.

### Key Points:

- **Inherit from `Ast_traverse.map`:**  
  This allows you to create an object that can traverse and modify the AST.

- **Override specific methods:**  
  By overriding methods like `module_binding`, you can target specific parts of the AST for transformation.

- **Combine with `Driver.register_transformation`:**  
  After defining your transformation logic, use `Driver.register_transformation` to ensure it is applied during the compilation process.

## Linting with PPX

PPX allows you to implement linting rules to enforce coding standards or detect potential issues in your code. Below, we outline how to create linting rules for the `[@enum]` and `[@enum2]` attributes, building on concepts from the context-free linting examples.

### Example 1: Linting with `[@enum]` 
:link: [Sample Code](./context_free.ml#L126-L216)

This linting rule ensures that the `[@enum]` attribute is correctly used on a simple module structure containing a single variant type.

#### Steps to Implement This Lint:

- **Define the Linting Rule:**  
  Create a linting rule that inherits from `Ast_traverse.fold` to traverse the module structure. This rule checks whether the module adheres to the expected pattern for using the `[@enum]` attribute.

- **Register the Lint:**  
  Register the lint with the PPX driver, enabling it to run during the compilation process.

### Example 2: Linting with `[@enum2]` 
:link: [Sample Code](./context_free.ml#L126-L216)

This linting rule extends the previous example to check for the correct usage of the `opt` argument in the `[@enum2]` attribute.

#### Steps to Implement This Lint:

- **Extend the Linting Rule:**  
  Add logic to the linting rule to verify that the `opt` argument is present and that the `from_string` function returns an `option` type when `opt` is specified.

- **Register the Lint:**  
  As with the other examples, register the lint with the PPX driver to ensure it is applied automatically.

## Conclusion

Global transformations are a powerful tool for automating repetitive tasks and ensuring consistency across your codebase. By extending the concepts of context-free transformations to entire modules and leveraging `Ast_traverse`, you can significantly reduce boilerplate and maintain a clean, maintainable code structure. Additionally, implementing linting rules ensures that your transformations are used correctly and consistently throughout your project.

### [On the next section, we will explore advanced use cases of global transformations.](../c%20-%20Advanced%20Global%20Transformations/README.md)