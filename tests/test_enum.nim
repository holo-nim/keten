import ketin

type
  Enum = distinct uint8
  EnumEntries {.fabric: ().} = object
    value: static Enum
    name: static string

template define(name) =
  const `name` = Enum(currentCount(EnumEntries))
  stitch EnumEntries, `name`, astToStr(name)

define A
define B

doAssert A.uint8 != B.uint8
doAssert EnumEntries.column(value).collect({}) == {A, B}
doAssert EnumEntries.column(name).collect([]) == ["A", "B"]

define C

doAssert A.uint8 != C.uint8
doAssert B.uint8 != C.uint8
doAssert EnumEntries.column(value).collect({}) == {A, B, C}

proc foo(s: var string, a: Enum) =
  # has to be defined after the values, otherwise generics can be used to delay the compilation
  EnumEntries.column(value).dispatch(a) do (val, name):
    s.add name
  else:
    s.add "<invalid>"

var x = B
var msg = ""
foo(msg, x)
doAssert msg == "B"
EnumEntries.unravel() do (val, _):
  msg.foo(val)
doAssert msg == "BABC"
