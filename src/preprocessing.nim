import std/strformat

import general


proc collapseEscapes*(filepath: string) =
  var fIn: File

  if not fIn.open(filepath):
    raise newVernError(fmt"Cannot open file '{filepath}' for reading")
    
  defer: fIn.close()

  var
    buf = newSeqOfCap[char](fIn.getFileSize)
    ln = 1
    col = 0
    next: char
    cur: char

  if not fIn.endOfFile:
    next = fIn.readChar()

  proc cycle() =
    inc col
    cur = next

    if cur == '\n':
      inc ln
      col = 0

    if not fIn.endOfFile:
      next = fIn.readChar

  while not fIn.endOfFile:
    cycle()

    if cur == ';' and next == '\\':
      var sName = newSeqOfCap[char](20)

      cycle()
      cycle()

      while not fIn.endOfFile and cur != ';':
        sName.add(cur)
        cycle()

      cycle()

      let name = cast[string](sName)

      if sName.len == 0:
        raise newVernError("Glyph escape names cannot be empty")

      case name
      of "rep", "repeat":
        let chars = cast[seq[char]]("◯")
        buf.add(chars)
      else:
        raise newVernError(fmt"Uknown glyph escape name '{name}'")
    else:
      buf.add(cur)

  fIn.close()

  filepath.writeFile(cast[seq[byte]](buf))
