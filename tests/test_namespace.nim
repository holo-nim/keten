import ketin, std/macros

type Namespace {.fabric: ().} = object
  name: static string
  value: typed

template identity(_, value): untyped = value
template undefined(name): untyped = {.error: "not defined: " & astToStr(name).}
template get(_: type Namespace, name): untyped =
  Namespace.column("name").find(astToStr(name), identity) do: undefined(name)

block:
  type Foo {.stitchDecl(Namespace, "Foo").} = ref object
    case a: bool
    of true: x: string
    else: discard
  const bar {.stitchDecl(Namespace, "bar").} = "abc"
  proc baz(x: int): string = "int " & $x
  proc baz(x: float): string = "float " & $x
  macro defineOverloaded(s: typed) =
    let name = newLit $s
    result = newStmtList()
    for sym in s:
      result.add quote do:
        stitch Namespace, `name`, `sym`
  defineOverloaded baz
  when (NimMajor, NimMinor) < (2, 0): # Foo is not locally declared due to https://github.com/nim-lang/Nim/issues/22571
    type Foo = Namespace.get(Foo)
  doAssert Foo(a: true, x: "abc").x == bar
  doAssert baz(123) == "int 123"
  doAssert baz(1.23) == "float 1.23"

  type Generic[T] {.stitchDecl(Namespace, "Generic").} = ref object
    case a: bool
    of true: x: T
    else: discard
  doAssert Generic[string](a: true, x: bar).x == bar

doAssert Namespace.get(Foo)(a: true, x: "abc").x == Namespace.get(bar)
type BazOverloads {.fabric: ().} = object
  sym: typed
Namespace.unravel() do (name, value):
  when name == "baz":
    stitch BazOverloads, value
doAssert BazOverloads.column(0).choice()(123) == "int 123"
doAssert BazOverloads.column(0).choice()(1.23) == "float 1.23"

when false: # can't explicitly instantiate generic type symbol
  doAssert Namespace.pick(Generic)[string](a: true, x: "abc").x == Namespace.pick(bar)
