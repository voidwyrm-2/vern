import std/[
  sequtils,
  options,
  strformat,
  strutils,
  math,
  macros
]

import
  general,
  lexer,
  parser


type
  Type* {.size: 1.} = enum
    tQuote,
    tReal,
    tChar,
    tArray,
    tChars,
    tBox

  Shape* = seq[uint32]

  Signature* = tuple[i, o: uint8]

  Value* = ref object
    case typ: Type
    of tQuote:
      node: Node
    of tReal:
      real: float
    of tChar:
      char: char
    of tArray:
      arrTyp: Option[Type]
      shape: Shape
      values: seq[Value]
    of tChars:
      chars: seq[char]
    of tBox:
      boxed: Value


func `$`*(typ: Type): string =
  case typ
  of tQuote:
    "Quote"
  of tReal:
    "Real"
  of tChar:
    "Char"
  of tArray:
    "Array"
  of tChars:
    "Chars"
  of tBox:
    "Box"

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

func `$`*(shape: Shape): string

func `==`*(a, b: Shape): bool =
  if a.len != b.len:
    return false

  for i in 0..<a.len:
    if a[i] != b[i]:
      return false

  true

func `!=`*(a, b: Shape): bool =
  not (a == b)

func `===`*(a, b: Shape): bool =
  a[1..^1] == b[1..^1]

func `!==`*(a, b: Shape): bool =
  not (a === b)

func `+`*(a: Shape, b: uint32): Shape =
  result = a

  if result.len > 0:
    result[0] += b

func `-`*(a: Shape, b: uint32): Shape =
  result = a

  if result.len > 0:
    result[0] -= b

func `$`*(shape: Shape): string =
  result = "⎡"
  
  result &= shape.mapIt($it).join(" ")

  result &= "⎦"


func newQuote*(node: Node): Value =
  Value(typ: tQuote, node: node)

func newReal*(real: float): Value =
  Value(typ: tReal, real: real)

func newChar*(char: char): Value =
  Value(typ: tChar, char: char)

proc getTypeOfValues(typ: var Option[Type], value: Value) =
  if value.typ == tArray:
    if value.values.len > 0:
      typ.getTypeOfValues(value.values[0])
  else:
    typ = some(value.typ)

func shape*(self: Value): Shape

proc getShapeOfValues(shape: var seq[uint32], typ: Type, values: seq[Value]) =
  shape.add(uint32(values.len))
  
  var prevShape: Shape

  if values.len > 0:
    prevShape = values[0].shape()

  for value in values:
    if typ != value.typ and value.typ != tArray:
      raise newVernError(fmt"Array is of type {typ}, but an item of type {value.typ} was found")
    elif value.typ == tArray and prevShape.len != value.shape.len:
      raise newVernError(fmt"Cannot combine arrays of ranks {prevShape.len} and {value.shape.len}")
    elif value.typ == tArray and prevShape != value.shape:
      raise newVernError(fmt"Cannot combine arrays of shapes {prevShape} and {value.shape}")

  if values.len > 0 and values[0] != nil:
    if values[0].typ == tArray:
      shape.getShapeOfValues(typ, values[0].values)
    elif values[0].typ == tChars:
      shape.add(uint32(values[0].chars.len))

func newArray*(values: varargs[Value]): Value =
  let sValues = values.toSeq()

  var
    arrTyp: Option[Type]
    shape: seq[uint32]

  if sValues.len > 0 and sValues[0] != nil:
    arrTyp.getTypeOfValues(sValues[0])

    shape.getShapeOfValues(arrTyp.get, sValues)

  if shape.len == 0:
    shape.add(0)

  Value(typ: tArray, arrTyp: arrTyp, shape: shape, values: sValues)

func newArray*(values: seq[Value], typ: Option[Type], shape: Shape): Value =
  Value(typ: tArray, arrTyp: typ, shape: shape, values: values)

func newArray*(values: seq[Value], typ: Type, shape: Shape): Value =
  newArray(values, some(typ), shape)

func newChars*(chars: seq[char]): Value =
  Value(typ: tChars, chars: chars)

func newBox*(value: Value): Value =
  Value(typ: tBox, boxed: value)

func default*(typ: Type): Value =
  case typ
  of tQuote:
    newQuote(parser.newEmptyNode())
  of tReal:
    newReal(0)
  of tChar:
    newChar(0.char)
  of tArray:
    newArray()
  of tChars:
    newChars(@[])
  of tBox:
    newBox(newReal(0))

func `is`*(self: Value, typ: set[Type]): bool =
  case self.typ
  #of tBox:
  #  if tBox in typ:
  #    true
  #  else:
  #    self.boxed is typ
  else:
    self.typ in typ

func `isnot`*(self: Value, typ: set[Type]): bool =
  not (self is typ)

func `is`*(self: Value, typ: Type): bool =
  self is {typ}

func `isnot`*(self: Value, typ: Type): bool =
  not (self is typ)

func typ*(self: Value): Type =
  self.typ

func node*(self: Value): Node =
  self.node

func real*(self: Value): float =
  self.real

func arrTyp*(self: Value): Type =
  self.arrTyp.unsafeGet()

func values*(self: Value): seq[Value] =
  self.values

func boxed*(self: Value): Value =
  self.boxed

func shape*(self: Value): Shape =
  case self.typ
  of tArray:
    self.shape
  of tChars:
    @[self.chars.len.uint32]
  else:
    @[]

func rank*(self: Value): int =
  self.shape.len

func len*(self: Value): int =
  case self.typ
  of tArray:
    self.values.len
  of tChars:
    self.chars.len
  else:
    1

func `[]`*(self: Value, ind: Natural): Value =
  case self.typ
  of tArray:
    if self.rank == 0:
      raise newVernError("Cannot index into a rank 0 array")

    if ind >= self.values.len:
      raise newVernError(fmt"Index {ind} is out of bounds for shape {self.shape}")

    self.values[ind]
  #of tBox:
  #  self.boxed[ind]
  else:
    raise newVernError(fmt"Cannot index into type {self.typ}")

func `[]`*(self: Value, ind: BackwardsIndex): Value =
  if ind.int > self.len and self.typ notin {tArray, tBox}:
    raise newVernError(fmt"Backwards index {ind.int} is out of bounds for shape {self.shape}")

  self[self.len - ind.int]

func bool*(self: Value): bool =
  self.real != 0

iterator withValues*(self: Value): Value =
  for value in self.values:
    yield value

template opImpl(name: string, op: untyped) =
  select (self.typ, other.typ):
    maybe (tReal, tReal):
      result = newReal(op(self.real, other.real))
    maybe (tChar, tChar):
      let n = self.char.float + other.char.float
      
      result = if n.canBeChar: newChar(n.char) else: newReal(n)
    maybe (tReal, tChar):
      let res = op(self.real, float(other.char))

      result = if res.canBeChar: newChar(res.char) else: newReal(res)
    maybe (tChar, tReal):
      let res = op(float(self.char), other.real)

      result = if res.canBeChar: newChar(res.char) else: newReal(res)
    maybe (tArray, tArray):
      if self.shape != other.shape:
        raise newVernError(fmt"Shapes {self.shape} and {other.shape} are incompatible")

      var values = newSeq[Value](self.values.len)

      for i in 0..<values.len:
        values[i] = op(self.values[i], other.values[i])

      result = newArray(values)
    maybe (_, tArray):
      let values = other.values.mapIt(op(self, it))
      result = newArray(values)
    maybe (tArray, _):
      let values = self.values.mapIt(op(it, other))
      result = newArray(values)
    maybe (tReal, tChars):
      var canBeChars = true

      let items = other.chars.mapIt((
        let v = op(self.real, float(it));
        canBeChars = canBeChars and v.canBeChar;
        v
      ))

      if canBeChars:
        result = newChars(items.mapIt(it.char))
      else:
        result = newArray(items.mapIt(newReal(it)))
    maybe (tChars, tReal):
      var canBeChars = true

      let items = self.chars.mapIt((
        let v = op(float(it), other.real);
        canBeChars = canBeChars and v.canBeChar;
        v
      ))

      if canBeChars:
        result = newChars(items.mapIt(it.char))
      else:
        result = newArray(items.mapIt(newReal(it)))
    maybe (tBox, _):
      result = newBox(op(self.boxed, other))
    maybe (_, tBox):
      result = newBox(op(self, other.boxed))
    maybe (tBox, tBox):
      result = newBox(op(self.boxed, other.boxed))
    maybe (_, _):
      raise newVernError("Cannot " & name & fmt" {self.typ} and {other.typ}")

#[
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
]#

func `$`*(self: Value): string

func join*(self, other: Value): Value =
  template boxedJoin(boxed, nonboxed: Value) =
    result = newArray(@[boxed, newBox(nonboxed)], tBox, @[2u32])

  select (self.typ, other.typ):
    maybe (tArray, tArray):
      if self.shape !== other.shape:
        raise newVernError(fmt"Cannot join arrays of shapes {self.shape} and {other.shape}")

      if self.values.len > 0 and other.values.len > 0 and self.arrTyp() != other.arrTyp():
        raise newVernError(fmt"Cannot join arrays of types {self.arrTyp()} and {other.arrTyp()}")

      var arr = newSeqOfCap[Value](self.len + other.len)
      
      arr.add(self.values)
      arr.add(other.values)

      result = newArray(arr, self.arrTyp, self.shape + self.shape[0])
    maybe (tArray, _):
      var arr = newSeqOfCap[Value](self.len + 1)

      if self.values.len > 0 and self.arrTyp() != other.typ:
        raise newVernError(fmt"Cannot join array of type {self.arrTyp()} and scalar of type {other.typ}")

      arr.add(self.values)
      arr.add(other)
  
      result = newArray(arr, other.typ, self.shape + 1)
    maybe (_, tArray):
      var arr = newSeqOfCap[Value](self.len + 1)

      if other.values.len > 0 and other.arrTyp() != self.typ:
        raise newVernError(fmt"Cannot join array of type {self.typ} and scalar of type {other.arrTyp()}")

      arr.add(self)
      arr.add(other.values)
      
      result = newArray(arr, self.typ, other.shape + 1)
    maybe (tBox, tBox):
      result = newArray(@[self, other], tBox, @[2u32])
    maybe (tBox, _):
      boxedJoin(self, other)
    maybe (_, tBox):
      boxedJoin(other, self)
    maybe (_, _):
      if self.typ != other.typ:
        raise newVernError(fmt"Cannot join types {self.typ} and {other.typ}")
      
      result = newArray(self, other)

func `+`*(self, other: Value): Value =
  opImpl("add", `+`)

func `-`*(self, other: Value): Value =
  opImpl("subtract", `-`)

func `*`*(self, other: Value): Value =
  opImpl("multiply", `*`)

func `/`*(self, other: Value): Value =
  opImpl("divide", `/`)

func `mod`*(self, other: Value): Value =
  opImpl("modulo", `mod`)

func `^`*(self, other: Value): Value =
  opImpl("get the power of", `^`)

func `==`*(self, other: Value): bool =
  false

func `!=`*(self, other: Value): bool =
  not (self == other)

func copy*(self: Value): Value =
  case self.typ
  of tQuote:
    self
  of tReal:
    newReal(self.real)
  of tChar:
    newChar(self.char)
  of tArray:
    newArray(self.values.mapIt(it.copy()))
  of tChars:
    let chars = newSeq[char](self.chars.len)

    if self.chars.len > 0:
      copyMem(chars[0].addr, self.chars[0].addr, self.chars.len)

    newChars(chars)
  of tBox:
    newBox(self.boxed.copy())

func `$`*(self: Value): string =
  case self.typ
  of tQuote:
    fmt"`{self.node.lit}"
  of tReal:
    if self.real.splitDecimal().floatpart == 0:
      $self.real.int
    else:
      $self.real
  of tChar:
    fmt"'{self.char}"
  of tArray:
    "[" & self.values.mapIt($it).join(" ") & "]"
  of tChars:
    "\"" & cast[string](self.chars) & "\""
  of tBox:
    fmt"■{self.boxed}"
