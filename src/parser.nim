import std/[
  options,
  strformat,
  sequtils,
  strutils
]

import
  general,
  lexer


type
  NodeType* = enum
    ntIdent,
    ntOperator,
    ntReal,
    ntString,
    ntGrouping,
    ntArray,
    ntQuotation,
    ntBinding,
    ntDebug

  Node* = ref object
    case typ: NodeType
    of ntIdent, ntOperator, ntReal, ntString, ntDebug:
      tok: Token
    of ntGrouping, ntArray:
      anchor: Token
      nodes: seq[Node]
    of ntQuotation:
      node: Node
    of ntBinding:
      name: Token
      body: seq[Node]

  Parser* = ref object
    tokens: seq[Token]
    idx: int


func newEmptyNode*(): Node =
  Node(typ: ntGrouping)

func typ*(self: Node): NodeType =
  self.typ

func tok*(self: Node): ptr Token =
  addr self.tok

func node*(self: Node): Node =
  self.node

func nodes*(self: Node): seq[Node] =
  if self.typ == ntBinding:
    self.body
  else:
    self.nodes

func name*(self: Node): ptr Token =
  addr self.name

func trace*(self: Node): string =
  case self.typ
  of ntIdent, ntOperator, ntReal, ntString, ntDebug:
    self.tok.trace()
  of ntGrouping, ntArray:
    self.anchor.trace()
  of ntQuotation:
    self.node.trace()
  of ntBinding:
    self.name.trace()

func lit*(self: Node): string =
  case self.typ
  of ntIdent, ntOperator, ntReal, ntString, ntDebug: 
     self.tok.lit
  of ntGrouping, ntArray:
    "(" & self.nodes.mapIt(it.lit).join(" ") & ")"
  of ntQuotation:
    fmt"`{self.node.lit}"
  of ntBinding:
    let body = self.body.mapIt(it.lit).join(" ")
    fmt"{self.name.name} <- {body}"

proc `$`*(self: Node): string =
  result = fmt"({self.typ} "

  case self.typ
  of ntIdent, ntOperator, ntReal, ntString, ntDebug: 
    result &= self.tok.min()
  of ntGrouping, ntArray:
    result &= self.nodes.mapIt($it).join(" ")
  of ntQuotation:
    result &= fmt"`{self.node}"
  of ntBinding:
    let body = self.body.mapIt($it).join(" ")
    result &= fmt"{self.name.name} {body}"

  result &= ")"


func newParser*(tokens: seq[Token]): Parser =
  new result
  result.tokens = tokens

func peek(self: Parser): Option[ptr Token] =
  if self.idx + 1 < self.tokens.len:
    result = some(addr self.tokens[self.idx + 1])

proc parseGrouping(self: Parser, anchor: ptr Token): Node
proc parseArray(self: Parser, anchor: ptr Token): Node
proc parseQuotation(self: Parser, anchor: ptr Token): Node
proc parseBinding(self: Parser, name: ptr Token): Node

proc parseItem(self: Parser, topLevel: bool = false): Node =
  let tok = addr self.tokens[self.idx]

  case tok[].typ
  of ttIdent:
    if (let next = self.peek(); topLevel and next.isSome and next.get()[].typ == ttDefine):
      result = self.parseBinding(tok)
    else:
      result = Node(typ: ntIdent, tok: tok[])
  of ttOperator:
    if (let next = self.peek(); topLevel and next.isSome and next.get()[].typ == ttDefine):
      result = self.parseBinding(tok)
    else:
      result = Node(typ: ntOperator, tok: tok[])
  of ttReal:
    result = Node(typ: ntReal, tok: tok[])
  of ttString:
    result = Node(typ: ntString, tok: tok[])
  of ttQuote:
    result = self.parseQuotation(tok)
  of ttParenLeft:
    result = self.parseGrouping(tok)
  of ttBracketLeft:
    result = self.parseArray(tok)
  of ttDebug:
    result = Node(typ: ntDebug, tok: tok[])
  else:
    let e = newVernError(fmt"Unexpected token '{tok[].lit}'")
    e.addTrace(tok[].trace())
    raise e

proc parseQuotation(self: Parser, anchor: ptr Token): Node =
  result = Node(typ: ntQuotation)

  inc self.idx

  result.node = self.parseItem()

proc parseGrouping(self: Parser, anchor: ptr Token): Node =
  result = Node(typ: ntGrouping)
  result.anchor = anchor[]

  inc self.idx

  while self.idx < self.tokens.len:
    if self.tokens[self.idx].typ == ttParenRight:
      return

    result.nodes.add(self.parseItem())
    inc self.idx

  let e = newVernError(fmt"Expected ')' to close grouping")
  e.addTrace(anchor[].trace())
  raise e

proc parseArray(self: Parser, anchor: ptr Token): Node =
  result = Node(typ: ntArray)
  result.anchor = anchor[]

  inc self.idx

  while self.idx < self.tokens.len:
    if self.tokens[self.idx].typ == ttBracketRight:
      return

    result.nodes.add(self.parseItem())
    inc self.idx

  let e = newVernError(fmt"Expected ']' to close array")
  e.addTrace(anchor[].trace())
  raise e

proc parseBinding(self: Parser, name: ptr Token): Node =
  result = Node(typ: ntBinding)
  result.name = name[]
  
  inc self.idx
  inc self.idx

  var line = name[].ln

  while self.idx < self.tokens.len:
    if self.tokens[self.idx].ln > line:
      dec self.idx # TODO: refactor parser to remove this
      break

    result.body.add(self.parseItem())
    inc self.idx
  
proc parse(self: Parser, toplevel: bool): seq[Node] =
  while self.idx < self.tokens.len:
    result.add(self.parseItem(toplevel))
    inc self.idx

proc parse*(self: Parser): seq[Node] =
  self.parse(true)

proc parseSnippet*(tokens: seq[Token]): Node =
  let p = newParser(tokens)
  Node(typ: ntGrouping, nodes: p.parse(false))
