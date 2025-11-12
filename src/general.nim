import std/[
  strutils,
  sequtils,
  options,
  macros,
  strformat,
  os,
  math,
  tables
]


const langVersion* = staticRead("../vern.nimble")
  .split("\n")
  .filterIt(it.startsWith("version"))[0]
  .split("=")[^1]
  .strip()[1..^2]


template panic*(msg: string): untyped =
  raise newException(Defect, msg)


proc pathToCache*(): string =
  result = getCacheDir("vern")

  if not result.dirExists():
    result.createDir()


func canBeChar*(real: float): bool =
  real >= 0 and real <= 255 and splitDecimal(real).floatpart == 0


func copy*[K, V](table: TableRef[K, V]): TableRef[K, V] =
  ## Shallowly copies a TableRef
  result = newTable[K, V](table.len)

  for (k, v) in table.pairs:
    result[k] = v


type
  VernError* = ref object of CatchableError
    stackTrace: seq[string]

func newVernError*(msg: string): VernError =
  VernError(msg: msg)

func addTrace*(self: VernError, trace: string) =
  self.stackTrace.add(trace)

func `$`*(self: VernError): string =
  result = "Error: "
  result &= self.msg

  if self.stackTrace.len > 0:
    result &= "\nStacktrace:\n " & self.stackTrace.join("\n ")


type
  Buffer* = ref object of RootObj

  FileBuffer* = ref object of Buffer
    f: File
    realEndOfFile: int8 = -1

  StringBuffer* = ref object of Buffer
    str: string
    idx: int

method readChar*(self: Buffer): char {.base.} =
  discard

method size*(self: Buffer): int64 {.base.} =
  discard

method endOfFile*(self: Buffer): bool {.base.} =
  discard

method index*(self: Buffer): int64 {.base.} =
  discard

method close*(self: Buffer) {.base.} =
  discard


func newFileBuffer*(f: File): FileBuffer =
  new result
  result.f = f

method readChar*(self: FileBuffer): char =
  try:
    result = self.f.readChar()
  except EOFError:
    result = '\0'

method size*(self: FileBuffer): int64 =
  self.f.getFileSize

method endOfFile*(self: FileBuffer): bool =
  result = self.f.endOfFile and self.realEndOfFile == 0

  if self.realEndOfFile > 0:
    dec self.realEndOfFile
  elif self.f.endOfFile and self.realEndOfFile < 0:
    self.realEndOfFile = 2

method index*(self: FileBuffer): int64 =
  -1

method close*(self: FileBuffer) =
  self.f.close()


func newStringBuffer*(str: string): StringBuffer =
  new result
  result.str = str

method readChar*(self: StringBuffer): char =
  if self.idx < self.str.len:
    result = self.str[self.idx]

  inc self.idx

method size*(self: StringBuffer): int64 =
  self.str.len.int64

method endOfFile*(self: StringBuffer): bool =
  self.idx > self.str.len + 1

method index*(self: StringBuffer): int64 =
  self.idx.int64


func expect*[T](opt: Option[T], msg: string): T =
  if opt.isNone:
    raise newVernError(msg)

  opt[]


macro select*(val, cases: untyped): untyped =
  let
    eq = newTree(nnkAccQuoted, ident"==")
    an = newTree(nnkAccQuoted, ident"and")

  var ifcases = newSeqOfCap[tuple[cond, body: NimNode]](cases.len)

  for (i, n) in cases.pairs:
    var cond: NimNode

    let arg = n[1]

    if arg.kind != nnkTupleConstr:
      raise newException(ValueError, fmt"Expected tuple, but found '{arg.toStrLit}' instead")

    if val.len != arg.len and not (arg[^1].kind == nnkAccQuoted and arg[^1].eqIdent("..")):
      continue

    for (j, it) in arg.pairs:
      if it.kind == nnkIdent and it.eqIdent("_"):
        if cond == nil:
          cond = newLit(true)
        continue
      elif it.eqIdent(".."):
        break
      elif cond == nil:
        cond = newCall(eq, val[j], it)
      else:
        cond = newCall(an, cond, newCall(eq, val[j], it))
    
    ifcases.add((cond, n[2]))

  result = newIfStmt(ifcases)
