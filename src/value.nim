import std/[
  sequtils,
  options,
  strformat,
  strutils,
  math
]

import
  general,
  lexer,
  parser


type
  Type* {.size: 1.} = enum
    tQuote,
    tReal,
    tArray,
    tChars

  Shape* = seq[uint32]

  Value* = ref object
    case typ: Type
    of tQuote:
      node: Node
    of tReal:
      real: float
    of tArray:
      arrTyp: Option[Type]
      shape: Shape
      values: seq[Value]
    of tChars:
      chars: seq[char]


func `$`*(typ: Type): string =
  case typ
  of tQuote:
    "Quote"
  of tReal:
    "Real"
  of tArray:
    "Array"
  of tChars:
    "Chars"

func `$`*(types: set[Type]): string =
  let sTypes = types.toSeq()

  case types.len
  of 0:
    panic("Empty Type set")
  of 1:
    result = fmt"type {sTypes[0]}"
  of 2:
    result = fmt"types {sTypes[0]} or {sTypes[1]}"
  else:
    result = "types "
    result &= sTypes[0..^2].mapIt($it).join(", ")
    result &= ", or "
    result &= $sTypes[^1]


func `$`*(shape: Shape): string =
  ($shape)[1..^1]


func newQuote*(node: Node): Value =
  Value(typ: tQuote, node: node)

func newReal*(real: float): Value =
  Value(typ: tReal, real: real)

func getShapeOfValues(shape: var seq[uint32], values: seq[Value], ) =
  shape.add(uint32(values.len))

  if values.len > 0 and values[0] != nil:
    if values[0].typ == tArray:
      shape.getShapeOfValues(values[0].values)
    elif values[0].typ == tChars:
      shape.add(uint32(values[0].chars.len))

func newArray*(values: varargs[Value]): Value =
  let sValues = values.toSeq()

  var
    arrTyp = none[Type]()
    shape: seq[uint32]

  if sValues.len > 0 and sValues[0] != nil:
    arrTyp = some(sValues[0].typ)

  shape.getShapeOfValues(sValues)

  if shape.len == 0:
    shape.add(0)

  Value(typ: tArray, arrTyp: arrTyp, shape: shape, values: sValues)

func newChars*(chars: seq[char]): Value =
  Value(typ: tChars, chars: chars)

func typ*(self: Value): Type =
  self.typ

func real*(self: Value): float =
  self.real

func node*(self: Value): Node =
  self.node

func len*(self: Value): int =
  case self.typ
  of tArray:
    self.values.len
  of tChars:
    self.chars.len
  else:
    1

template opImpl(name: string, op: untyped) =
  select (self.typ, other.typ):
    maybe (tReal, tReal):
      result = newReal(op(self.real, other.real))
    maybe (tArray, tArray):
      if self.shape != other.shape:
        raise newVernError(fmt"Shapes {self.shape} and {other.shape} are incompatible")

      var values = newSeq[Value](self.values.len)

      for i in 0..<values.len:
        values[i] = op(self.values[i], other.values[i])

      result = newArray(values)
    maybe (tReal, tArray):
      let values = other.values.mapIt(op(self, it))
      result = newArray(values)
    maybe (tArray, tReal):
      let values = self.values.mapIt(op(it, other))
      result = newArray(values)
    maybe (tReal, tChars):
      let values = other.chars
        .mapIt(op(self.real, float(it)))
        .mapIt(newReal(it))

      result = newArray(values)
    maybe (tChars, tReal):
      let values = self.chars
        .mapIt(op(float(it), other.real))
        .mapIt(newReal(it))

      result = newArray(values)
    maybe (_, _):
      raise newVernError("Cannot " & name & fmt" {self.typ} and {other.typ}")

template opCompImpl(name: string, op: untyped) =
  select (self.typ, other.typ):
    maybe (tReal, tReal):
      result = newReal(op(self.real, other.real))
    maybe (tArray, tArray):
      if self.shape != other.shape:
        raise newVernError(fmt"Shapes {self.shape} and {other.shape} are incompatible")

      var values = newSeq[Value](self.values.len)

      for i in 0..<values.len:
        values[i] = op(self.values[i], other.values[i])

      result = newArray(values)
    maybe (tReal, tArray):
      let values = other.values.mapIt(op(self, it))
      result = newArray(values)
    maybe (tArray, tReal):
      let values = self.values.mapIt(op(it, other))
      result = newArray(values)
    maybe (_, _):
      result = false

proc `+`*(self, other: Value): Value =
  opImpl("add", `+`)

proc `-`*(self, other: Value): Value =
  opImpl("subtract", `-`)

proc `*`*(self, other: Value): Value =
  opImpl("multiply", `*`)

proc `/`*(self, other: Value): Value =
  opImpl("divide", `/`)

proc `mod`*(self, other: Value): Value =
  opImpl("modulo", `mod`)

proc `^`*(self, other: Value): Value =
  opImpl("get the power of", `^`)

proc `==`*(self, other: Value): bool =
  false

proc `≠`*(self, other: Value): bool =
  true

func `$`*(self: Value): string =
  case self.typ
  of tQuote:
    fmt"`{self.node.lit}"
  of tReal:
    let str = $self.real

    if str.endsWith(".0"):
      str[0..^3]
    else:
      str
  of tArray:
    "[" & self.values.mapIt($it).join(" ") & "]"
  of tChars:
    "\"" & cast[string](self.chars) & "\""
