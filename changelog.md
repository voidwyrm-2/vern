# Changelog

## 0.6.0

- The escape formatter now works correctly on files
- (Fix) certain Unicode characters weren't being lexed correctly
- (Fix) the escape entry of ≠ was incorrectly written


## 0.5.0

- Added escapes for ≠ (notequal), ○ (index), ⊢ (first), ⊣ (last), ⥂ (decapitate), ⌄ (pop), ■ (box), and □ (unbox)
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
- (Fix) the result of `@` (repeat) was not contained inside of an array
- Added nim-noise as a dependency


## 0.2.0

- Array definitions are now supported
- Added the '△' (Shape/Shapeof) operator
- (Fix) shapes were getting incorrectly compared when doing operations on arrays


## 0.1.0

- Basic operators implemented
- Real and Quote types implemented
