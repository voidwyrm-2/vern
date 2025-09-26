# Vern

An array programming language whose focus is simplicity, creating complexity from that simplicity, and using as few non-ASCII characters as possible.

## Example

```

Sum <- `+\

Fac <- |1+`*\

Fib <- `(0 1)_`(, + :)@'

[1 2 3 4 5] Sum ; 15
5 Fac ; 120
11 Fib ; 89
```

## Todo

- [ ] implement list syntax
- [ ] finalize the 'pop' operator's character (currently `'`)
- [ ] implement the 'range' operator
- [ ] add an escape formatter for unicode characters (maybe `\\[name]` and `\\u[num]`?)
- [ ] add additional named built-in operators (à la, Uiua's `&p`, `&ffi`, etc)
- [ ] add examples
- [ ] implement 1D convulsion as an example
- [ ] image manipulation (?)

## Building

```bash
nimble build -l
```
