# Syntax

## Types

Of Vern's six types, five have literal forms.

### Number/Real

```
   10 20 30 40
10
20
30
40
```

```
   3.14 1.2 8.6
3.14
1.2
8.6
```

### Character

```
   '0 'A
'0
'A
```

### Chars

```
   "disturbing the peace"
"disturbing the peace"

   1+
"ejtuvscjoh!uif!qfbdf"
```

### Array

```
   [1 2 3 4 5]
[1 2 3 4 5]
```

```
   ['a 'b 'c 'd]
['a 'b 'c 'd]
```

### Quotation

```
   `+
`+
```

```
   `(+ 2 ×)
`(+ 2 ×)
```

The sixth type, Box, is explained in the description of the [■ (box)](/docs/builtins.md/#---box) operator.

## Formatting

Many operators in Vern use Unicode glyphs as their identiifers, but most keyboards don't have these glyphs.  
To help with this, Vern has a built-in preprocessor that formats escape sequences into those glyphs[^1].

The REPL shows this nicely.
```
   10 2 \*
Formatted to: 10 2 ×
20

   1969 1984 \j
Formatted to: 1969 1984 ⋈
[1969 1984]

   "hello" \.id\
Formatted to: "hello" ●
"hello"
```

All of the preprocessor escapes can be shown with the 'shortcuts' command inside the REPL.

## Bindings

Bindings are immutable assignments, which can only be created at the top level.
```
   A <- 10
   B <- `+/

   [A A A A A] B
50

   C <-
```

If the body of a binding is empty, it will take a value from the stack;  
if the stack is empty, an binding binding is created.

## Subscripting

Subscripting allows you to set the last argument of an operator to a constant number.

The escape for subscript is `\,`

```
   10 +\,2
Formatted to: 10 +₂
12

   \i\,10
Formatted to: ɩ₁₀
[0 1 2 3 4 5 6 7 8 9]
```

This is useful for quotations.
```
   3 4 `(2 +) _
5
4
```

```
   3 4 `+\,2 _
Formatted to: 3 4 `+₂_
5
4
```


[^1]: I wrote a blog post about this: https://voidwyrm-2.github.io/posts/unicode-escapes.
