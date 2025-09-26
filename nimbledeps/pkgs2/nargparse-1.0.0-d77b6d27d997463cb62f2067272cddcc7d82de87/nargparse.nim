import std/[
  tables,
  strutils,
  strformat,
  sequtils,
  sets
]

export sets


type
  ArgparseError* = object of CatchableError

  FlagType = enum
    ftFlag,
    ftOpt,
    ftList,
    ftSet

  FlagResult* = ref object of RootObj
    ## Holds the common state for the results of flags.
    name: string
    typ: FlagType
    exists: bool = false

  NoOpt* = ref object of FlagResult
    ## The result of flags that take no arguments.

  SingleOpt* = ref object of FlagResult
    ## The result of flags that take one argument.
    value: string

  ListOpt* = ref object of FlagResult
    ## The result of flags that take a list of arguments.
    values: seq[string]

  SetOpt* = ref object of FlagResult
    ## The result of flags that take an exclusive list of arguments.
    values: HashSet[string]

  Flag = ref object
    res: FlagResult
    names: seq[string]
    help: string

  Argparser* = ref object
    name: string
    flags: seq[Flag]
    flagMap: OrderedTable[string, Flag]

func set(self: FlagResult, value: string) =
  SingleOpt(self).value = value

func add(self: FlagResult, value: string) =
  ListOpt(self).values.add(value)

func incl(self: FlagResult, value: string) =
  SetOpt(self).values.incl(value)

func exists*(self: FlagResult): bool =
  self.exists

func value*(self: SingleOpt): string =
  self.value

func value*(self: ListOpt): seq[string] =
  self.values

func value*(self: SetOpt): HashSet[string] =
  self.values

func newArgparser*(name: string): Argparser =
  Argparser(name: name)

func addFlag(self: Argparser, names: openArray[string], help: string, typ: FlagType): FlagResult =
  if varargsLen(name) == 0:
    raise newException(ValueError, "Flags must have at least one name")

  let f = Flag(names: names.toSeq(), help: help)
  
  case typ
  of ftFlag:
    f.res = NoOpt()
  of ftOpt:
    f.res = SingleOpt()
  of ftList:
    f.res = ListOpt()
  of ftSet:
    f.res = SetOpt()
  
  f.res.typ = typ
  result = f.res

  self.flags.add(f)

  for name in names:
    if name.startsWith("-"):
      raise newException(ValueError, fmt"Flag names cannot start hyphens (referring to '{name}')")
    elif self.flagMap.hasKey(name):
      raise newException(ValueError, fmt"Flag '{name}' already exists")

    self.flagMap[name] = f

func flag*(self: Argparser, names: varargs[string], help: string = ""): NoOpt =
  ## Creates a flag without an argument.
  NoOpt(self.addFlag(names, help, ftFlag))

func opt*(self: Argparser, names: varargs[string], help: string = ""): SingleOpt =
  ## Creates a flag with a single argument.
  ## An error is thrown if the flag is passed multiple times.
  SingleOpt(self.addFlag(names, help, ftOpt))

func optList*(self: Argparser, names: varargs[string], help: string = ""): ListOpt =
  ## Creates a flag that can be passed multiple times to collect a list of arguments.
  ListOpt(self.addFlag(names, help, ftList))

func optSet*(self: Argparser, names: varargs[string], help: string = ""): SetOpt =
  ## Creates a flag that can be passed multiple times to collect a set of arguments.
  ## An error is thrown if an option is passed multiple times.
  SetOpt(self.addFlag(names, help, ftSet))

proc parse*(self: Argparser, args: openArray[string]): seq[string] =
  ## Parses the given arguments.
  var lastFlag: FlagResult

  for rawArg in args:
    var hyphens = 0

    while hyphens < rawArg.len() and rawArg[hyphens] == '-':
      hyphens += 1

    let arg = rawArg[hyphens..^1]

    if hyphens == 0:
      if lastFlag != nil:
        case lastFlag.typ:
        of ftFlag:
          discard
        of ftOpt:
          lastFlag.set(arg)
        of ftList:
          lastFlag.add(arg)
        of ftSet:
          if arg in SetOpt(lastFlag).values:
            raise newException(ArgparseError, fmt"Argument '{arg}' was already passed for flag '{lastFlag.name}'")

          lastFlag.incl(arg)

        lastFlag = nil
      else:
        result.add(arg)
    elif hyphens == 1 or hyphens == 2:
      if lastFlag != nil:
        raise newException(ArgparseError, fmt"Expected argument for flag '{lastFlag.name}'")

      if not self.flagMap.hasKey(arg):
        raise newException(ArgparseError, fmt"Unknown flag '{arg}'")

      let
        flag = self.flagMap[arg]
        res = flag.res

      if res.exists and res.typ in {ftFlag, ftOpt}:
        raise newException(ArgparseError, fmt"Flag '{arg}' has already been passed")

      res.exists = true
      res.name = arg

      if res.typ != ftFlag:
        lastFlag = res
    else:
      raise newException(ArgparseError, fmt"Invalid flag '{arg}'")

func `<`(a, b: tuple[n, h: string]): bool {.used.} =
  a.n.len() < b.n.len()

proc `$`*(self: Argparser): string =
  result = self.name

  for flag in self.flags:
    result &= " [-" & flag.names.join(" -") & "]"

  var flags: seq[tuple[n, h: string]]
  
  for flag in self.flags:
    var str = "-"

    str &= flag.names.join(", -")

    case flag.res.typ
    of ftFlag:
      discard
    of ftOpt:
      str &= " <value>"
    of ftList, ftSet:
      str &= " <values...>"

    flags.add((str, flag.help))

  let maxlen = max(flags).n.len()

  for flag in flags:
    let spaces = maxlen - flag.n.len() + 2

    result &= "\n"
    result &= flag.n
    
    for _ in 0..<spaces:
      result &= " "

    result &= flag.h
