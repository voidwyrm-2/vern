import std/[
  strformat,
  strutils,
  sequtils,
  macros
]

import general


macro switchOnMap(value, error: untyped): untyped =
  let
    idResult = ident"result"

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

  result = newNimNode(nnkCaseStmt, nil)

  result.add(value)

  for (keys, glyph) in entries:
    let bran = newNimNode(nnkOfBranch, nil)

    for k in keys:
      bran.add(newLit(k))

    bran.add(newStmtList(newAssignment(idResult, newLit(glyph))))

    result.add(bran)

  result.add(newTree(nnkElse, error))


func getGlyph(name: string): string =
  switchOnMap(name):
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

  cycle()

  while not buf.endOfFile:
    if inString:
      if cur == '\\':
        result.buf.add('\\')
        cycle()
      elif cur == '"':
        inString = false

      result.buf.add(cur)
      cycle()
    elif cur == '"':
      inString = true
      result.buf.add(cur)
      cycle()
    elif cur == '\\':
      cycle()
      
      var value: string

      if cur == '.':
        value = newStringOfCap(10)

        cycle()

        while not buf.endOfFile and cur != '\\':
          value &= cur
          cycle()

        cycle()
      elif cur in {',', '\''}:
        value = newStringOfCap(3)

        let superscript = cur == '\''

        cycle()

        while not buf.endOfFile and cur in {'0'..'9'}:
          value &= cur
          cycle()

        if buf.endOfFile and cur in {'0'..'9'}:
          value &= cur

        if value.len == 0:
          let e = newVernError("Subscript number escapes cannot be empty")
          e.addTrace(fmt"at {file}:{ln}:{col}")
          raise e

        var subscr = newStringOfCap(value.len * 3)

        for ch in value:
          if superscript:
            case ch
            of '1':
              subscr &= 194.char
              subscr &= 185.char
            of '2', '3':
              subscr &= 194.char
              subscr &= char(ch.int - 48 + 176)
            else:
              subscr &= 226.char
              subscr &= 129.char
              subscr &= char(ch.int - 48 + 176)
              
          else:
            subscr &= 226.char
            subscr &= 130.char
            subscr &= char(ch.int - 48 + 128)

        result.buf.add(subscr)

        inc result.collapses

        continue
      else:
        value = $cur
        cycle()

      let glyph =
        try:
          getGlyph(value)
        except VernError as e:
          e.addTrace(fmt"at {file}:{ln}:{col}")
          raise e
      
      result.buf.add(glyph)
      inc result.collapses
    else:
      result.buf.add(cur)
      cycle()

proc collapseEscapes*(file, str: string): tuple[str: string, collapses: uint64] =
  let res = collapseEscapes(file, newStringBuffer(str))

  (cast[string](res.buf), res.collapses)

proc collapseEscapes*(filepath: string) =
  var f: File

  if not f.open(filepath):
    when defined(debug):
      raise newVernError(fmt"Cannot open file '{filepath}' for reading and writing")
    else:
      raise newVernError(fmt"Cannot open file '{filepath}'")
    
  try:
    let res = collapseEscapes(filepath, newFileBuffer(f))

    #[
    let written = f.writeChars(res.buf, 0, res.buf.len)
    if written < res.buf.len:
      raise newVernError(fmt"Writing error: {written} bytes written, but the buffer contains {res.buf.len} bytes")
    ]#

    if res.collapses > 0:
      f.close()

      filepath.writeFile cast[seq[byte]](res.buf)
  finally:
    f.close()
