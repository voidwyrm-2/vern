import std/[
  strutils,
  sequtils,
  options,
  macros,
  strformat,
  os
]


const langVersion* = staticRead("../vern.nimble")
  .split("\n")
  .filterIt(it.startsWith("version"))[0]
  .split("=")[^1]
  .strip()[1..^2]


func panic*(msg: string) =
  raise newException(Defect, msg)


proc pathToCache*(): string =
  result = getCacheDir("vern")

  if not result.dirExists():
    result.createDir()


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

  StringBuffer* = ref object of Buffer
    str: string
    idx: int

method readChar*(self: Buffer): char {.base.} =
  discard

method endOfFile*(self: Buffer): bool {.base.} =
  discard


func newFileBuffer*(f: File): FileBuffer =
  new result
  result.f = f

method readChar*(self: FileBuffer): char =
  self.f.readChar()

method endOfFile*(self: FileBuffer): bool =
  self.f.endOfFile()


func newStringBuffer*(str: string): StringBuffer =
  new result
  result.str = str

method readChar*(self: StringBuffer): char =
  if self.idx < self.str.len:
    result = self.str[self.idx]

  inc self.idx

method endOfFile*(self: StringBuffer): bool =
  self.idx > self.str.len


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
