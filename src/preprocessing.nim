import std/[
  strformat,
  strutils,
  sequtils,
  macros
]

import general


macro switchOnMap(error: untyped): untyped =
  let
    inop = newTree(nnkAccQuoted, ident"in")

    entries: seq[tuple[keys: seq[string], glyph: string]] = staticRead("data/unicode_shortcuts.map")
    .strip()
    .split("\n")
    .mapIt((
      let entry = it.split(":");
      let keys = entry[0]
        .split(",")
        .mapIt(it.strip());
      (keys, entry[1].strip())
    ))

  var ifcases = newSeqOfCap[tuple[cond, body: NimNode]](entries.len)

  for (keys, glyph) in entries:
    ifcases.add((
      newCall(
        inop,
        ident"name",
        newLit(keys)
      ),
      newAssignment(ident"result", newLit(glyph))
    ))

  result = newIfStmt(ifcases)

  result.add(newTree(nnkElse, error))


func getGlyph(name: string): string =
  switchOnMap:
    raise newVernError(fmt"Unknown glyph escape '{name}'")

proc collapseEscapes*(file: string, buf: Buffer): tuple[buf: seq[char], collapses: uint64] =
  result.buf = newSeqOfCap[char](buf.size)

  var
    ln = 1
    col = 0
    inString = false
    next: char
    cur: char

  if not buf.endOfFile:
    next = buf.readChar()

  proc cycle() =
    inc col
    cur = next

    if cur == '\n':
      inc ln
      col = 0

    if not buf.endOfFile:
      next = buf.readChar()

  while not buf.endOfFile:
    cycle()

    if inString:
      if cur == '\\':
        cycle()
      elif cur == '"':
        inString = false
    elif cur == '"':
      inString = true
    elif cur == '\\' and (next in {'a'..'z'} or next == '+'):
      cycle()
      
      var name: string

      if cur == '+':
        name = newStringOfCap(10)

        cycle()

        while not buf.endOfFile and cur != '\\':
          name &= cur
          cycle()
      else:
        name = $cur

      let glyph =
        try:
          getGlyph(name)
        except VernError as e:
          e.addTrace(fmt"at {file}:{ln}:{col}")
          raise e
      
      result.buf.add(cast[seq[char]](glyph))
      inc result.collapses
    else:
      result.buf.add(cur)

proc collapseEscapes*(file, str: string): tuple[str: string, collapses: uint64] =
  let res = collapseEscapes(file, newStringBuffer(str))

  (cast[string](res.buf), res.collapses)

proc collapseEscapes*(filepath: string) =
  var f: File

  if not f.open(filepath):
    raise newVernError(fmt"Cannot open file '{filepath}' for reading")
    
  try:
    let res = collapseEscapes(filepath, newFileBuffer(f))
    f.close()
    filepath.writeFile cast[seq[byte]](res.buf)
  finally:
    f.close()
