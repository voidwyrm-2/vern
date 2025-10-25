import std/[
  tables,
  strformat,
  sequtils,
  strutils,
  options
]

import
  general,
  lexer,
  parser,
  value

export
  tables,
  value,
  options


let gcString = ""

template fillDefault*(): untyped =
  proc(typ: Type): Value {.closure, sideEffect.} = (let _ = gcString; typ.default)
# The `let _ = gcString` is to force non-gcsafe


type
  NativeOp* = proc(s: State, iptr: pointer)

  BindingType* = enum
    btNative,
    btNodes,
    btValue

  Binding* = object
    chars: int
    case typ: BindingType
    of btNative:
      p: NativeOp
    of btNodes:
      nodes: seq[Node]
    of btValue:
      value: Value

  FillProc* = proc(typ: Type): Value {.closure.}

  State* = ref object
    parent: State
    stack: seq[Value]
    bindings: TableRef[string, Binding]
    fill*: FillProc


func initBinding*(p: NativeOp): Binding =
  Binding(typ: btNative, chars: 0, p: p)

func initBinding*(nodes: seq[Node]): Binding =
  func getNodeLen(n: Node): int =
    case n.typ
    of ntIdent, ntReal, ntChar, ntString, ntDebug:
      n.lit.len
    of ntOperator:
      1
    of ntGrouping, ntArray:
      n.nodes.map(getNodeLen).foldl(a + b)
    of ntQuotation:
      getNodeLen(n.node) + 1
    else:
      0

  Binding(typ: btNodes, chars: nodes.map(getNodeLen).foldl(a + b), nodes: nodes)

proc initBinding*(file, text: string): Binding =
  let
    l = newLexer(file, newStringBuffer(text))
    tokens = l.lex()
    node = parseSnippet(tokens)

  initBinding(@[node])

func initBinding*(value: Value): Binding =
  Binding(typ: btValue, chars: ($value).len, value: value)

func typ*(binding: Binding): BindingType =
  binding.typ

func p*(binding: Binding): NativeOp =
  binding.p

func nodes*(binding: Binding): seq[Node] =
  binding.nodes

func value*(binding: Binding): Value =
  binding.value

func copy*(binding: Binding): Binding =
  case binding.typ
  of btValue:
    initBinding(binding.value.copy())
  else:
    binding

func `$`*(binding: Binding): string =
  case binding.typ
  of btNative:
    "<native procedure>"
  of btNodes:
    binding.nodes.map(lit).join(" ")
  of btValue:
    $binding.value

func display*(binding: Binding, name: string): string =
  let c = if binding.chars == 1: "char" else: "chars"
  fmt"{name} ({binding.chars} {c}) <- {binding}"


func newState*(cap: int, bindings: TableRef[string, Binding] = nil): State =
  new result
  result.stack = newSeqOfCap[Value](cap)
  result.bindings = bindings
  result.fill = fillDefault()

func newState*(parent: State, cap: int): State =
  result = newState(cap, parent.bindings)
  result.parent = parent
  result.fill = result.parent.fill

func copy*(self: State): State =
  new result

  result.stack = newSeq[Value](self.stack.len)

  if self.stack.len > 0:
    copyMem(result.stack[0].addr, self.stack[0].addr, self.stack.len)

  result.bindings = newTable[string, Binding](self.bindings.len)

  for (k, v) in self.bindings.pairs:
    result.bindings[k] = v

func stack*(self: State): auto =
  result = self.stack

func bindings*(self: State): auto =
  result = self.bindings

proc push*(self: State, value: Value) =
  self.stack.add(value)

proc trypop*(self: State): (Value, bool) =
  if self.stack.len > 0:
    result = (self.stack.pop(), true)

proc pop*(self: State, arg: uint8): Value =
  var ok: bool
  (result, ok) = self.trypop()

  if not ok and self.parent != nil:
    (result, ok) = self.parent.trypop()

  if not ok:
    raise newVernError(fmt"Stack was empty when getting argument {arg}")

proc clearStack*(self: State) =
  self.stack.setLen(0)

proc needs*(value: Value, arg: uint8, typ: set[Type]): Value =
  result = value

  if value isnot typ and typ.len != 0:
    raise newVernError(fmt"Expected {typ} for argument {arg}, but found {value.typ} instead")

proc needs*(value: Value, arg: uint8, typ: Type): Value =
  value.needs(arg, {typ})

proc whole*(value: Value, arg: uint8): int =
  let r = value.needs(arg, tReal).real

  result = int(r)

  if float(result) != r:
    raise newVernError(fmt"Argument {arg} must be an integer")

proc natural*(value: Value, arg: uint8): int =
  result = value.whole(arg)

  if result < 0:
    raise newVernError(fmt"Argument {arg} cannot be negative")

proc set*(self: State, name: string, binding: Binding) =
  when not defined(allowBindingRedef):
    if self.bindings.hasKey(name):
      raise newVernError(fmt"Cannot redefine binding '{name}'")

  self.bindings[name] = binding

proc get*(self: State, name: string): Binding =
  if not self.bindings.hasKey(name):
    raise newVernError(fmt"Unknown identifier '{name}'")

  self.bindings[name]

proc unset*(self: State, name: string): Option[Binding] =
  result = none[Binding]()

  if (var b: Binding; self.bindings.pop(name, b)):
    result = some(b)


proc displayStack*(stack: seq[Value], prefix: string = "") =
  var col = 28

  for val in stack:
    echo prefix, "\e[38;5;", col, "m", val, "\e[0m"

    col += 4

    if col in {51..62}:
      col = 64
    elif col > 231:
      col = 28

  stdout.write "\e[0m"

proc displayBindings*(bindings: TableRef[string, Binding]) =
  for (k, v) in bindings.pairs:
    echo v.display(k)
