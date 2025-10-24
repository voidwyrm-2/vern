# Changelog

## 0.10.1

- (Fix) 'ɩ' didn't create the correct range
- (Fix) '⍀' caused an error when given an empty array

## 0.10.0

- '@' no longer creates an array automatically
- '/' is now a composite made up of '⍀' and '⊣'
- The readme examples now function correctly
- Added the '∈' (index), '⧖' (reverse), '↺' (left rotate), '↻' (right rotate), '⊻' (switch), and '~' (fill)
- Quotations with whitespace separating the quote and quote body (e.g. '\` hello', '\`    ()') now causes an error
- The fill value for '⍀' and '/' may now be set with '~'
- '⋈' has been optimized with pre-join type checking
- Improved the error messages for array indexing and joining


## 0.9.0

- (Fix) empty quotations weren't flagged as an error
- Added the '⊓' (decapitate) operator


## 0.8.0

- Implemented characters literals
- If applicable, character sequences will result from operating on character sequences and non-character values


## 0.7.0

- Divide is now '%', and modulo is now '◿'
- Added the '?' (debug), '●' (identity), '⊢' (first), '⊣' (last), '/' (reduce), '⍀' (scan), 'ɩ' (iota), and '⋈' (join) operators
- Multi-character glyph escapes now use '.' instead of '+'
- Added the 'Char' type
- (Fix) the array type-checker wouldn't correctly infer the type of arrays


## 0.6.0

- The escape formatter now works correctly on files
- (Fix) certain Unicode characters weren't being lexed correctly
- (Fix) the escape entry of ≠ was incorrectly written


## 0.5.0

- Added escapes for '≠' (notequal), '○' (index), '⊢' (first), '⊣' (last), '⥂' (decapitate), '⌄' (pop), '■' (box), and '□' (unbox)
- Added the 'Box' type
- △ on Non-Array and non-Chars values now returns an empty shape


## 0.4.0

- The escape formatter currently only works in the REPL
- Added the 'shortcuts' command to the REPL
- (Fix) Unicode characters weren't being lexed correctly
- using △ (shape) on the Chars type is now valid


## 0.3.0

- Vern now has a built-in REPL


## 0.2.1

- Implemented a basic escape formatter for converting escapes to Unicode characters; at the moment this does not function properly
- (Fix) the result of '@' (repeat) was not contained inside of an array
- Added nim-noise as a dependency


## 0.2.0

- Array definitions are now supported
- Added the '△' (shape) operator
- (Fix) shapes were getting incorrectly compared when doing operations on arrays


## 0.1.0

- Basic operators implemented
- Real and Quote types implemented
