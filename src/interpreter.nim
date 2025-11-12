import
  general,
  state,
  parser

from lexer import
  lit,
  trace,
  newLexer,
  lex

export state


type Interpreter* = ref object
  state*: State
  fillTick*: uint8 = 0


proc newInterpreter*(state: State): Interpreter =
  new result
  result.state = state

proc newInterpreter*(bindings: TableRef[string, Binding] = nil): Interpreter =
  newInterpreter(newState(10, bindings))

proc exec*(self: Interpreter, nodes: openArray[Node])

proc debugRecur(s: State) =
  if s.parent != nil:
    debugRecur(s.parent)
    echo "┣━━━━━━"

  s.stack.displayStack("┃ ")

proc exec*(self: Interpreter, n: Node) =
  case n.typ
  of ntDebug:
    echo "┏ ? ", n.trace()
    debugRecur(self.state)
  of ntIdent, ntOperator:
    let binding = self.state.get(n.tok[].name)

    case binding.typ
    of btNative:
      let p = binding.p
      p(self.state, cast[pointer](self))
    of btNodes:
      self.exec(binding.nodes)
    of btValue:
      self.state.push(binding.value)

    if binding.typ != btValue:
      if self.fillTick > 0:
        dec self.fillTick
      else:
        self.state.fill = fillDefault()
        self.state.fillIsDefault = true
  of ntReal:
    self.state.push(newReal(n.tok[].r))
  of ntChar:
    self.state.push(newChar(n.tok[].ch))
  of ntString:
    self.state.push(newChars(n.tok[].s))
  of ntGrouping:
    self.exec(n.nodes)
  of ntArray:
    let
      substate = newState(self.state, 5)
      intr = newInterpreter(substate)

    intr.exec(n.nodes)

    let items = substate.stack

    self.state.push(newArray(items))
  of ntQuotation:
    self.state.push(newQuote(n.node))
  of ntSuperscripted:
    panic("unreachable for branch ntSuperscripted")
  of ntSubscripted:
    self.state.push(newReal(n.num.float))
    self.exec(n.node)
  of ntBinding:
    let
      name = n.name[].name
      body = n.nodes
    
    if body.len == 0:
      let
        (val, ok) = self.state.trypop()
        binding = if not ok: initBinding(body) else: initBinding(val)

      self.state.set(name, binding)
    else:
      self.state.set(name, initBinding(body))

proc exec*(self: Interpreter, nodes: openArray[Node]) =
  for n in nodes:
    try:
      self.exec(n)
    except VernError as e:
      e.addTrace(n.trace())
      raise e
