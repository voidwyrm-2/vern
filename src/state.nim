import std/[
  tables,
  strformat,
  sequtils,
  strutils
]

import
  general,
  lexer,
  parser,
  value

export
  tables,
  value


type
  NativeOp* = proc(s: State, iptr: pointer)

  BindingType* = enum
    btNative,
    btNodes,
    btValue

  Binding* = object
    case typ: BindingType
    of btNative:
      p: NativeOp
    of btNodes:
      nodes: seq[Node]
    of btValue:
      value: Value

  State* = ref object
    parent: State
    stack: seq[Value]
    bindings: TableRef[string, Binding]


func initBinding*(p: NativeOp): Binding =
  Binding(typ: btNative, p: p)

func initBinding*(nodes: seq[Node]): Binding =
  Binding(typ: btNodes, nodes: nodes)

proc initBinding*(file, text: string): Binding =
  let
    l = newLexer(file, newStringBuffer(text))
    tokens = l.lex()
    node = parseSnippet(tokens)

  initBinding(@[node])

func initBinding*(value: Value): Binding =
  Binding(typ: btValue, value: value)

func typ*(binding: Binding): BindingType =
  binding.typ

func p*(binding: Binding): NativeOp =
  binding.p

func nodes*(binding: Binding): seq[Node] =
  binding.nodes

func value*(binding: Binding): Value =
  binding.value

func `$`*(binding: Binding): string =
  case binding.typ
  of btNative:
    "<native procedure>"
  of btNodes:
    binding.nodes.mapIt(it.lit).join(" ")
  of btValue:
    $binding.value


func newState*(cap: int, bindings: TableRef[string, Binding] = nil): State =
  new result
  result.stack = newSeqOfCap[Value](cap)
  result.bindings = bindings

func newState*(parent: State, cap: int): State =
  result = newState(cap, parent.bindings)
  result.parent = parent

func stack*(self: State): auto =
  self.stack

func bindings*(self: State): auto =
  self.bindings

proc push*(self: State, value: Value) =
  self.stack.add(value)

proc trypop*(self: State): Value =
  if self.stack.len > 0:
    result = self.stack.pop()

proc pop*(self: State, arg: uint8): Value =
  result = self.trypop()

  if result == nil and self.parent != nil:
    result = self.parent.trypop()

  if result == nil:
    raise newVernError(fmt"Stack was empty when getting argument {arg}")

proc clearStack*(self: State) =
  self.stack.setLen(0)

proc needs*(value: Value, arg: uint8, typ: set[Type]): Value =
  result = value

  if value.typ notin typ and typ.len != 0:
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
