import std/[
  strformat,
  strutils
]

import general


type
  TokenType* = enum
    ttIdent,
    ttOperator,
    ttReal,
    ttString,
    ttQuote,
    ttDefine
    ttParenLeft,
    ttParenRight,
    ttBracketLeft,
    ttBracketRight
    ttBraceLeft,
    ttBraceRight,

  Token* = object
    file: string
    ln, col: uint
    case typ: TokenType
    of ttIdent, ttOperator:
      name*: string
    of ttReal:
      r*: float
    of ttString:
      s*: seq[char]
    else:
      discard

  Lexer* = ref object
    r: Buffer
    file: string
    ln, col: uint
    cur, next: char
    eof, hasNext: bool


func typ*(t: Token): TokenType =
  t.typ

func ln*(t: Token): uint =
  t.ln

func lit*(t: Token): string =
  case t.typ
    of ttIdent, ttOperator:
      t.name
    of ttReal:
      $t.r
    of ttString:
      cast[string](t.s)
    of ttQuote:
      "`"
    of ttDefine:
      "<-"
    of ttParenLeft:
      "("
    of ttParenRight:
      ")"
    of ttBracketLeft:
      "["
    of ttBracketRight:
      "]"
    of ttBraceLeft:
      "{"
    of ttBraceRight:
      "}"

func trace*(t: Token): string =
  fmt"at {t.file}:{t.ln}:{t.col}"

func min*(t: Token): string =
  result = fmt"<{t.typ} `{t.lit}`>"

func `$`*(t: Token): string =
  result = fmt"<{t.typ} `{t.lit}` {t.ln} {t.col}>"


proc adv(self: Lexer)

proc newLexer*(file: string, reader: Buffer): Lexer =
  new result
  result.r = reader
  result.file = file
  result.ln = 1
  result.col = 0
  result.adv()
  result.adv()

proc readChar(self: Lexer): char =
  result = self.r.readChar()
  self.hasNext = self.r.endOfFile()

proc adv(self: Lexer) =
  self.cur = self.next

  inc self.col

  if self.hasNext:
    self.eof = true

  if not self.eof:
    self.next = self.readChar()

  if self.cur == '\n' and not self.hasNext:
    inc self.ln
    self.col = 0

func tok(self: Lexer, tt: TokenType): Token =
  Token(typ: tt, file: self.file, ln: self.ln, col: self.col)
  
func err(self: Lexer, msg: string, ln, col: uint) =
  let
    t = Token(typ: ttQuote, file: self.file, ln: ln, col: col)
    e = newVernError(msg)

  e.addTrace(t.trace())

  raise e

func err(self: Lexer, msg: string) =
  self.err(msg, self.ln, self.col)

proc collectIdent(self: Lexer): Token =
  result = Token(typ: ttIdent)
  result.file = self.file
  result.ln = self.ln
  result.col = self.col

  var buf: seq[char]

  while not self.eof:
    let ch = self.cur

    if ch notin {'a'..'z', 'A'..'Z'}:
      break
    
    buf.add(ch)
    self.adv()

  result.name = cast[string](buf)

proc collectReal(self: Lexer): Token =
  result = Token(typ: ttReal)
  result.file = self.file
  result.ln = self.ln
  result.col = self.col

  var
    buf: seq[char]
    dot = false

  while not self.eof:
    let ch = self.cur

    case ch:
    of '.':
      if self.next notin '0'..'9' or dot:
        break

      buf.add(ch)
      dot = true
    of '0'..'9':
      buf.add(ch)
    else:
      break

    self.adv()

  result.r = parseFloat(cast[string](buf))

proc collectString(self: Lexer): Token =
  result = Token(typ: ttString)
  result.file = self.file
  result.ln = self.ln
  result.col = self.col
  
  self.adv()

  var
    escaped = false
    buf: seq[char]
  
  while not self.eof:
    let ch = self.cur

    if escaped:
      buf.add:
        case ch
        of '\\', '\'', '"':
          ch
        of '0':
          '\0'
        of '\t':
          '\t'
        of 'n':
          '\n'
        of 'r':
          '\r'
        of 'v':
          '\v'
        of '\a':
          '\a'
        of 'f':
          '\f'
        of 'b':
          '\b'
        of 'e':
          '\e'
        else:
          self.err(fmt"Invalid escape specifier '{ch}'")
          '0'

      escaped = false
      self.adv()
      continue

    case ch
    of '\\':
      escaped = true
    of '"':
      break
    else:
      buf.add(ch)

    self.adv()

  if self.cur != '"':
    self.err("Unterminated string literal", self.ln, self.col)

  self.adv()

  result.s = buf

proc collectUnicode(self: Lexer, len: int): Token =
  result = Token(typ: ttOperator)
  result.file = self.file
  result.ln = self.ln
  result.col = self.col

  var buf = newSeq[char](len + 1)

  buf[0] = self.cur

  self.adv()

  for i in 1..len:
    if self.eof:
      self.err(fmt"Incomplete unicode character of length {len}")

    buf[i] = self.cur
    self.adv()

  result.name = cast[string](buf)

proc lex*(self: Lexer): seq[Token] =
  while not self.eof:
    let ch = self.cur

    case ch
    of char(0)..char(32), char(127):
      self.adv()
    of ';':
      while not self.eof and self.cur != '\n':
        self.adv()
    of '`':
      result.add(self.tok(ttQuote))
      self.adv()
    of '(':
      result.add(self.tok(ttParenLeft))
      self.adv()
    of ')':
      result.add(self.tok(ttParenRight))
      self.adv()
    of '[':
      result.add(self.tok(ttBracketLeft))
      self.adv()
    of ']':
      result.add(self.tok(ttBracketRight))
      self.adv()
    of 'a'..'z', 'A'..'Z':
      result.add(self.collectIdent())
    of '0'..'9':
      result.add(self.collectReal())
    of '"':
      result.add(self.collectString())
    of char(240):
      result.add(self.collectUnicode(3))
    of char(226):
      result.add(self.collectUnicode(2))
    else:
      if ch > char(127):
        self.err(fmt"Illegal character '{self.cur}'")
          
      if ch == '<' and self.next == '-':
        result.add(self.tok(ttDefine))
        self.adv()
      else:
        result.add(Token(typ: ttOperator, file: self.file, name: $ch, ln: self.ln, col: self.col))

      self.adv()
