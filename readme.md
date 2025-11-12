# Vern

An array programming language whose focus is simplicity, and creating complexity from that simplicity.

## Example

```
Sum <- `+/

Fac <- ɩ1~`×⍀

Fib <- `(0 1)_ [`(`._, + :)@⌄]

[1 2 3 4 5] Sum ; 15
5 Fac ; [1 2 6 24 120]
11 Fib ; [0 1 1 2 3 5 8 13 21 34 55 89]
```

## Documentation

[intro.md](/docs/intro.md)

## Todo

- [x] Implement list syntax
- [x] Finalize the 'pop' operator's character (was `'`, finalized as `⌄`)
- [x] Add an escape formatter for unicode characters (in the form of `\[char]` and `\.[name]\`)
- [x] Get the escape formatter working with files
- [x] Implement the 'reduce' operator
- [x] Implement the 'range/iota' operator
- [x] Implement character literals (e.g. `'a`, `' `)
- [ ] Implement public/private bindings with `·`
- [x] Implement equals and not-equals
- [ ] Add additional named built-in operators (à la, Uiua's `&p`, `&ffi`, etc)
- [ ] Add basic examples
- [ ] Add a 1D convulsion, AoC, and Project Euler as examples
- [ ] Optimize arrays via reference counting
- [ ] Image manipulation (?)

## Building

### Debug

```bash
nimble build -l
./vern -repl
```

### Release

```bash
./build.nims host
./bin/host/vern -repl
```

### Distribution

```bash
./build.nims all
ls dist
```
