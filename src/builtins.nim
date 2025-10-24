import std/[
  sequtils,
  algorithm
]

import
  general,
  interpreter


let builtins* = newTable[string, Binding]()


template addP(name: string, body: untyped) =
  builtins[name] = initBinding(
    proc(s {.inject.}: State, iptr: pointer) =
      let intr {.inject.} = cast[Interpreter](iptr)
      body
  )

template addS(name, body: string) =
  builtins[name] = initBinding("builtins.vern", body)

template addOp(name: string, op: untyped) =
  addP(name):
    let
      b = s.pop(1)
      a = s.pop(2)
  
    s.push(op(a, b))

template addCompOp(name: string, op: untyped) =
  addP(name):
    let
      b = s.pop(1)
      a = s.pop(2)

    s.push(if op(a, b): newReal(1) else: newReal(0))


# Add
addOp("+", `+`)

# Subtract
addOp("-", `-`)

# Multiply
addOp("*", `*`)

# Divide
addOp("%", `/`)

# Modulus
addOp("◿", `mod`)

# Power
addOp("^", `^`)

# Equals
addCompOp("=", `==`)

# Not Equals
addCompOp("≠", `!=`)

# Execute
addP("!"):
  let quot = s.pop(1).needs(1, tQuote)

  intr.exec(quot.node)

# Length
addP("#"):
  let val = s.pop(1)

  s.push(newReal(float(val.len)))

# Shape
addP("△"):
  let val = s.pop(1)

  s.push(newArray(val.shape().mapIt(newReal(it.float))))

# Identity
addP("●"):
  s.push(s.pop(1))

# Box
addP("■"):
  let val = s.pop(1)

  s.push(newBox(val))

# Unbox
addP("□"):
  let box = s.pop(1).needs(1, tBox)

  s.push(box.boxed)

# Pop
addP("⌄"):
  discard s.pop(1)

# Dup
addP("."):
  let val = s.pop(1)

  s.push(val)
  s.push(val)

# Over
addS(","):
  "`._:"

# Swap
addP(":"):
  let
    a = s.pop(1)
    b = s.pop(2)

  s.push(a)
  s.push(b)

# Dip
addP("_"):
  let
    quot = s.pop(1).needs(1, tQuote)
    val = s.pop(2)

  defer: s.push(val)

  intr.exec(quot.node)

# Repeat
addP("@"):
  let
    quot = s.pop(1).needs(1, tQuote)
    amount = s.pop(2).natural(2)

  for _ in 0..<amount:
    intr.exec(quot.node)

# First
addP("⊢"):
  let arr = s.pop(1).needs(1, tArray)

  s.push(arr[0])

# Last
addP("⊣"):
  let arr = s.pop(1).needs(1, tArray)

  s.push(arr[^1])

# Scan
addP("⍀"):
  let
    quot = s.pop(1).needs(1, tQuote)
    arr = s.pop(2).needs(2, tArray)
    even = (arr.len and 1) == 0

    substate = newState(intr.state, 2)
    subintr = newInterpreter(substate)

  if arr.len > 0:
    if even:
      substate.push(arr[0])
    else:
      substate.push(s.fill(arr[0].typ))

  var first = true

  for value in (if even: arr.values[1..^1] else: arr.values):
    if first:
      first = false
    else:
      let item = substate.pop(0)
      substate.push(item)
      substate.push(item)

    substate.push(value)
    subintr.exec(quot.node)

  let stack = substate.stack

  if stack.len == 0:
    raise newVernError("Stack must have at least value after reducing")

  s.push(newArray(substate.stack))

# Reduce
addS("/"):
  "⍀⊣"

# Iota
addS("ɩ"):
  "1-[`1@]`+⍀0:⋈"

# Join
addP("⋈"):
  let
    b = s.pop(1)
    a = s.pop(2)

  s.push(a.join(b))

# Decapitate
addP("⊓"):
  let
    arr = s.pop(1).needs(1, tArray)
    values = arr.values
  
  if values.len == 0:
    s.push(arr)
  else:
    s.push(newArray(values[1..^1], arr.arrTyp, arr.shape - 1))
    s.push(values[0])

# Index
addP("∈"):
  let
    ind = s.pop(1).natural(1)
    arr = s.pop(2).needs(2, tArray)

  s.push(arr[ind])

# Reverse
addP("⧖"):
  let val = s.pop(1)

  if val.typ == tArray:
    s.push(newArray(val.values.reversed()))
  else:
    s.push(val)

# Left Rotate
addS("↺"):
  ":`:_"

# Right Rotate
addS("↻"):
  "`:_:"

# Switch
addP("⊻"):
  let
    cases = s.pop(1).needs(1, tArray)
    other = s.pop(2).needs(2, tQuote)
    ind = s.pop(3).natural(3)

  if cases.len > 0 and cases.arrTyp != tQuote:
    raise newVernError("Argument 1 of ⊻ must be an array of quotations")

  if ind < cases.len:
    intr.exec(cases[ind].node)
  else:
    intr.exec(other.node)

# Fill
addP("~"):
  let val = s.pop(1)

  case val.typ
  of tQuote:
    s.fill = proc(typ: Type): Value =
      let
        substate = newState(5, intr.state.bindings)
        subintr = newInterpreter(substate)

      subintr.exec(val.node)

      if substate.stack.len == 0:
        nil
      else:
        substate.stack[^1]
  else:
    s.fill = proc(typ: Type): Value = val

  intr.fillTick = 1
