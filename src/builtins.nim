import std/sequtils

import interpreter


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

addOp("/", `/`)

addOp("%", `mod`)

addOp("^", `^`)

addCompOp("=", `==`)

addCompOp("≠", `≠`)

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
  let val = s.pop(1).needs(1, tArray)

  s.push(newArray(val.shape().mapIt(newReal(it.float))))

# Pop
addP("'"):
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
