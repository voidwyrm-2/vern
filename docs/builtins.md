# Builtins

> Note: the examples are shown as if run inside the REPL

### Math

#### `+` - Add

> Pervausive Dyadic function

Add values.

```
   2 1+
3
```

```
   [2 3 4] 1+
[3 4 5]
```

```
   [4 5 6] [1 2 3] +
[5 7 9]
```

#### `-` - Subtract

> Pervausive Dyadic function

Subtract values.

```
   2 1-
1
```

```
   [2 3 4] 1-
[1 2 3]
```

```
   [4 5 6] [1 2 3] -
[3 3 3]
```

#### `×` - Multiply

> Pervausive Dyadic function

> Shortcuts: `\.multiply\`, `\.mult\`, `\*`

Multiply values.

```
   5 3×
15
```

```
   [1 2 3] 2×
[2 4 6]
```

```
   [4 5 6] [1 2 3] ×
[4 10 18]
```

#### `%` - Divide

> Pervausive Dyadic function

> Shortcuts: `\.divide\`, `\.div\`, `\%`

Divide values.

```
   12 3÷
4
```

```
   [1 2 3] 2÷
[0.5 1 1.5]
```

```
   [4 5 6] [1 2 3] ÷
[4 2.5 2]
```

#### `◿` - Modulo

> Pervausive Dyadic function

> Shortcuts: `\.modulo\`, `\.modu\`, `\.mod\`, `\m`

Modulo values.

```
   27 10◿
7
```

```
   [3 7 14] 5◿
[3 2 4]
```

```
   [10 10 10] [3 4 5] ◿
[1 2 0]
```
 - ⁅
\.floor\, \.flo\ - ⌊
\.ceiling\, \.ceil\

#### `⁅` - Round

> Monadic function

> `\.round\`, `\.rou\`

Rounds a number to the nearest whole number.

```
   3.4⁅
3
```

```
   3.5⁅
4
```

#### `⌊` - Floor

> Monadic function

> `\.floor\`, `\.flo\`

Rounds a number towards negative infinity.

```
   3.4⌊
3
```

```
   3.5⌊
3
```

#### `⌈` - Ceiling

> Monadic function

> `\.ceiling\`, `\.ceil\`

Rounds a number towards positive infinity.

```
   3.4⌈
4
```

```
   3.5⌈
4
```

#### `=` - Equals

> Pervausive Dyadic function

Checks the equality of two values; the result of `=` will always be 0 or 1.

```
   1 2=
0
```

```
   [1 2 3 4] [3 5 5 4] =
[0 0 0 1]
```

#### `≠` - Not Equals

> Pervausive Dyadic function

> Shortcuts: `\.notequal\`, `\.neq\`, `\n`

Checks for the inequality of two values; the result of `≠` will always be 0 or 1.

```
   1 2≠
1
```

```
   [1 2 3 4] [3 5 5 4] ≠
[1 1 1 0]
```

#### `≍` - Match

> Dyadic function

> Shortcuts: `\.match\`, `\.mat\`, `\=`

Checks if two values are exactly the same.

```
   [1 2 3 4] [3 2 5 4] ≍
0
```

```
   [5 6 7 8] [5 6 7 8] ≍
1
```

```
   6 6 ≍
1
```

```
   2 4 ≍
0
```

#### `#` - Length

> Monadic function

Get the number of rows in an array.

```
   5#
1
```

```
   []#
0
```

```
   [1 2 3]#
3
```

```
   [[1 2] [3 4] [5 6]]#
3
```

#### `△` - Shape

> Monadic function

> Shortcuts: `\.shape\`, `\.sha\`, `\.sh\`

Get the dimensions of an array.

```
   5△
[]
```

```
   []△
[0]
```

```
   [1 2 3]△
[3]
```

```
   [[1 2] [3 4] [5 6]]△
[3 2]
```


#### `!` - Execute

> Monadic modifier

Executes a quotation.

```
   1 1 `+
1
1
`+

   !
2
```

```
   [1 2 3] `△
[1 2 3]
`△

   !
[3]
```

#### `■` - Box

> Monadic function

> Shortcuts: `\.box\`, `\.bx\`, `\b`

Turn a value into a box.  
This is Vern's only way to create mixed-type arrays.

Normally, arrays can only be created if their types and shapes match.  
```
   [1 'a [2 3]]
Error: Array is of type Real, but an item of type Char was found
Stacktrace:
 at repl:1:2
```

But if the values are wrapped in Boxes, types and shapes may be matched.

```
   [1■ 'a■ [2 3]■]
[1|'a|[2 3]]
```

Pervausive functions apply through boxes.

```
   20■ 30■
■20
■30

   +
■■50
```
```
   20■■ 30■■
■■20
■■30

   +
■■50

   . +
■■100
```

#### `□` - Unbox

> Monadic function

> Shortcuts: `\.unbox\`, `\.unbx\`, `\.un\`, `\u`

Take a value out of a box.

```
   20■■ 40 +
■■60

   □□
60
```

#### `●` - Identity

> Monadic function

> Shortcuts: `\.identity\`, `\.iden\`, `\.id\`

Do nothing with one value.

```
   5 ●
5
```

#### `⌄` - Pop

> Monadic 0-output function

> Shortcuts: `\.pop\`, `\.po\`, `\p`

Discard the value at the top of the stack.

```
   1 2 3 ⌄
1
2
```

```
   4 [5 6] ⌄
4
```

#### `.` - Dup

> Monadic function

Duplicate the value at the top of the stack.

```
   1 .
1
1
```

```
   3 . *
9
```

```
   [2 3 4] . %
[1 1 1]
```

#### `,` - Over

> Triadic function

Duplicate the value under the top stack value.

```
   0 1 ,
0
1
0
```

```
   'a 'b 'c ,
'a
'b
'c
'b
```

#### `_` - Dip

> Monadic modifier

Temporarily pop the top value off the stack and execute a quotation.

```
   [3 2 1 `+_]
[5 1]
```

```
   [4 3 2 1 `+_]
[4 5 1]
```

#### `@` - Repeat

> Monadic modifier

Repeat a quotation an amount of times.

```
   0 5 `(2+)@
10
```

```
   [] 5 `(2⋈)@
[2 2 2 2 2]
```

#### `⊢` - First

> Monadic function

> Shortcuts: `\.first\`, `\.fir\`, `\f`

Get the first row of an array.

```
   [1 2 3]⊢
1
```

```
   [[1 2] [3 4] [5 6]]⊢
[1 2]
```

#### `⊣` - Last

> Monadic function

> Shortcuts: `\.last\`, `\.la\`, `\l`

Get the last row of an array.

```
   [1 2 3]⊣
3
```

```
   [[1 2] [3 4] [5 6]]⊣
[5 6]
```


#### `/` - Reduce

> Monadic modifier

Apply a reducing quotation to an array.

```
   [1 2 3 4 5] `+/
15
```


#### `⍀` - Scan

> Monadic modifier

> Shortcuts: `\.scan\`, `\.sca\`, `\.sc\`, `\s`

Like `/`, but intermediate values are kept.

```
   [1 2 3 4 5] `+⍀
[1 3 6 10 15]
```


#### `ɩ` - Iota

> Monadic function

> Shortcuts: `\.iota\`, `\.io\`, `\i`

Make an array of numbers from 0 to N - 1.

```
   10 ɩ
[0 1 2 3 4 5 6 8 9]
```


#### `⋈` - Join

> Dyadic function

> Shortcuts: `\.join\`, `\.joi\`, `\.jo\`, `\j`

Join two arrays end-to-end.

```
   2 1⋈
[2 1]
```

```
   [10 20] [30 40]⋈
[10 20 30 40]
```


#### `⊓` - Decapitate

> Dyadic function

> Shortcuts: `\.decapitate\`, `\.decapit\`, `\.decap\`, `\.de\`, `\d`

Returns the head and tail of an array.

```
   [1 2 3 4]⊓
[2 3 4]
1
```


#### `⧖` - Reverse

> Monadic function

> Shortcuts: `\.switch\`, `\.swi\`, `\.sw\`

Reverses an array.

```
   [1 2 3 4]⧖
[4 3 2 1]
```

```
   "hello"⧖
"olleh"
```


#### `∈` - Index

> Dyadic function

> Shortcuts: `\.index\`, `\.ind\`

Returns an item at an index in an array.

```
   [1 2 3 4] 0∈
1
```

```
   [10 20 30 40] 3∈
40
```


#### `↺` - Left/Downwards Rotate

> Tryadic function

> Shortcuts: `\.lrot\`, `\.lr\`, `\.drot\`, `\.dr\`

Rotates three items on the stack downwards.

```
   1 2 3
1
2
3

   ↺
3
1
2
```


#### `↻` - Right/Upwards Rotate

> Tryadic function

> Shortcuts: `\.rrot\`, `\.rr\`, `\.urot\`, `\.ur\`

Rotates three items on the stack upwards.

```
   1 2 3
1
2
3

   ↻
2
3
1
```


#### `⊻` - Switch

> Tryadic function

> Shortcuts: `\.switch\`, `\.swi\`, `\.sw\`

Switches on an index.

If the index is out of range for the given quotation array,
the extra quotation is executed.

```
   0 `0 [`10 `20 `30 `40] ⊻
10
```

```
   3 `0 [`10 `20 `30 `40] ⊻
40
```

```
   4 `0 [`10 `20 `30 `40] ⊻
0
```

```
   20 `0 [`10 `20 `30 `40] ⊻
0
```


#### `~` - Fill

> Monadic meta-function

Sets the fill value for operators.

If the given fill value is a quotation, that quotation will be executed when a fill value is used.

```
   [1 2 3 4 5] `+/
15

   [1 2 3 4 5] 10~`+/
25
```

```
   [1 2 3 4 5] `×/
0

   [1 2 3 4 5] 1~`×/
120
```

```
   [1 2 3 4 5] `(10 10+)~ `×/
2400
```


#### `⍨` - Unfill

> Niladic meta-function

> Shortcuts: `\.unfill\`, `\.unfi\`, `\.unf\`, `\~`

Returns the fill value.

If no fill value is set, an error will occur.

```
   10~ ⍨
10
```

```
   ⍨
Error: No fill value set
Stacktrace:
 at repl:1:2
```


#### `⋯` - Explode

> Monadic function

Deconstructs an array.

```
   ['a 'b 'c] ⋯
'a
'b
'c
```
