import std/sequtils

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

    echo "A: ", a
    echo "B: ", b
  
    s.push(if op(a, b): newReal(1) else: newReal(0))


addOp("+", `+`)

addOp("-", `-`)

addOp("*", `*`)

addOp("%", `/`)

addOp("◿", `mod`)

addOp("^", `^`)

addCompOp("=", `==`)

addCompOp("≠", `!=`)

# Execute
addP("!"):
  let quot = s.pop(1).needs(1, tQuote)

  intr.exec(quot.node)

# Length
addP("#"):
  let val = s.pop(1)

  s.push(newReal(float(val.len)))

# Shape/Shapeof
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

    substate = newState(intr.state, 5)
    subintr = newInterpreter(substate)

  for _ in 0..<amount:
    subintr.exec(quot.node)

  let items = substate.stack

  s.push(newArray(items))

# First
addP("⊢"):
  let arr = s.pop(1).needs(1, tArray)

  s.push(arr[0])

# Last
addP("⊣"):
  let arr = s.pop(1).needs(1, tArray)

  s.push(arr[^1])

# Reduce
addP("/"):
  let
    quot = s.pop(1).needs(1, tQuote)
    arr = s.pop(2).needs(2, tArray)
    even = arr.len mod 2 != 0

    substate = newState(intr.state, 2)
    subintr = newInterpreter(substate)

  # TODO: check if quotation signature is 2.1 here
  
  if arr.len > 0:
    if even:
      substate.push(arr[0])
    else:
      substate.push(arr[0].typ.default)

  for value in (if even: arr.values[1..^1] else: arr.values):
    substate.push(value)
    subintr.exec(quot.node)

  let stack = substate.stack

  if stack.len == 0:
    raise newVernError("Stack must have at least value after reducing")

  s.push(stack[^1])

# Scan
addP("⍀"):
  let
    quot = s.pop(1).needs(1, tQuote)
    arr = s.pop(2).needs(2, tArray)
    even = arr.len mod 2 == 0

    substate = newState(intr.state, 2)
    subintr = newInterpreter(substate)

  # TODO: check if quotation signature is 2.1 here
  
  if arr.len > 0:
    if even:
      substate.push(arr[0])
    else:
      substate.push(arr[0].typ.default)

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

addS("ɩ"):
  "`1@`+⍀"

# Join
addP("⋈"):
  let
    b = s.pop(1)
    a = s.pop(2)

  s.push(a.join(b))
