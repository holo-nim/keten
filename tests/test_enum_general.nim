import ketin

type
  SomeExtensibleEnum* = concept
    proc entries(_: type Self): type
  ExtensibleEnums* {.fabric: ().} = object
    enumType: type SomeExtensibleEnum
    entries: type SomeFabric

template names*(T: type SomeExtensibleEnum): FabricColumn =
  T.entries.column(name)

template values*(T: type SomeExtensibleEnum): FabricColumn =
  T.entries.column(value)

template define*(T: type SomeExtensibleEnum, name: untyped, value: T) =
  mixin stitch
  const `name` = `value`
  stitch entries(T), `name`, astToStr(name)

template define*(T: type SomeExtensibleEnum, name: untyped) =
  define T, name, T(currentCount(entries(T)))

template newEnum(enumName, BaseType) {.dirty.} =
  type `enumName`* = distinct `BaseType`
  type `enumName Entries`* {.fabric: ().} = object
    value: static `enumName`
    name: static string
  template entries*(_: type `enumName`): type = `enumName Entries`
  template `define enumName`(name; value) {.used.} =
    define(`enumName`, name, value)
  template `define enumName`(name) {.used.} =
    define(`enumName`, name)
  stitch ExtensibleEnums, `enumName`, `enumName Entries`

newEnum Foo, uint8

Foo.define A
defineFoo B

doAssert A.uint8 != B.uint8
doAssert Foo.values.collect({}) == {A, B}
doAssert Foo.names.collect([]) == ["A", "B"]

Foo.define C

doAssert A.uint8 != C.uint8
doAssert B.uint8 != C.uint8
doAssert Foo.values.collect({}) == {A, B, C}

proc foo(s: var string, a: Foo) =
  # has to be defined after the values, otherwise generics can be used to delay the compilation
  Foo.values.dispatch(a) do (val, name):
    s.add name
  else:
    s.add "<invalid>"

var x = B
var msg = ""
foo(msg, x)
doAssert msg == "B"
Foo.entries.unravel() do (val, _):
  msg.foo(val)
doAssert msg == "BABC"
