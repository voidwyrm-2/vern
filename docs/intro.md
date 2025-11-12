# Introduction

Vern is a stack-based array programming language.

There are two parts to this which require explaination, "stack-based" and "array programming".

## Stack-based

A [stack-based](https://en.wikipedia.org/wiki/Stack-oriented_programming) language is one that operates on a stack.  
Every operation is simply a function that pops an amount of values from the stack,
does something to them, then pushes the result back onto the stack.

For example, the expression `1 + 2 * 3` in a stack-based would be `2 3 * 1 +`.  
If we added parentheses, `(1 + 2) * 3`, it would instead be `1 2 + 3 *`.

As you can see, stack-based languages don't need parentheses for forcing operator precedence,
since they do operations completely linearly.

Let's look at something a bit more complex, the `Sum` example in the readme:
```
Sum <- `+/
```

People who have written stack-based languages, array languages,
or Lisps before may somewhat understand what this is doing.

But for those who don't, I'll break it down.

This snippet has three parts:

1.
```
`+
```
This creates a [quotation](https://en.wikipedia.org/wiki/Lisp_(programming_language)#Self-evaluating_forms_and_quoting),
which is a snippet of quote that can be executed or evalutated at a later time.  
This is a quotation of the `+` (add) operator, so when this quotation is executed,
it will add two numbers on the stack together and output the result.

2.
```
/
```
This is the reduce operator, which applies a reducing function (or quotation, in this case) to an array.  
This operator takes in an array and a quotation, applies the quotation to each item of the array,
then returns the result.

3.
```
Sum <-
```
This creates a binding, which is an immutable (or, unchangable) variable or function, named `Sum` with the body of whatever is after the `<-`.  
If there is nothing after the `<-`, a value is popped off of the stack and used as the value of the binding.

## Array Programming

Array programming is a paradigm in which arrays and operations on arrays are used to do things.

For example, in array languages, instead of adding an array and a number being an error,
it applies that addition to every item in the array.
```
    + [1 2 3 4 5] 10
[11 12 13 14 15]

    ⊜□ ⊸≠@\s "one step forward one step back"
["one"│"step"│"forward"│"one"│"step"│"back"]
```
[^1]

### Further Resources

[syntax.md](/docs/syntax.md) and [builtins.md](/docs/builtins.md).

[^1]: [Uiua](https://uiua.org) used as an example.
