# Vern

An array programming language whose focus is simplicity, creating complexity from that simplicity.

## Example

```
Sum <- `+/

Fac <- ɩ1:⋈`*⍀

Fib <- `(0 1)_ `(, + : ?)@⊢

[1 2 3 4 5] Sum ; 15
5 Fac ; [1 2 6 24 120]
11 Fib ; 89
```

## Todo

- [x] implement list syntax
- [x] finalize the 'pop' operator's character (was `'`, finalized as `⌄`)
- [x] add an escape formatter for unicode characters (in the form of `\[char]` and `\+[name]\`)
- [x] get the escape formatter working with files
- [x] implement the 'reduce' operator
- [x] implement the 'range/iota' operator
- [x] implement character literals (e.g. `'a`, `' `)
- [ ] implement function tacitness
- [ ] add additional named built-in operators (à la, Uiua's `&p`, `&ffi`, etc)
- [ ] add basic examples
- [ ] add a 1D convulsion, AoC, and Project Euler as examples
- [ ] optimize arrays via reference counting
- [ ] image manipulation (?)

## Building

```bash
nimble build -l
```
