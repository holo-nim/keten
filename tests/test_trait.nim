import ketin

type Stringable[T] {.fabric: ().} = object
  toString: proc (x: T): string
  #Self: type T = T # does not work

block:
  proc toString(a: int): string {.stitchDecl: Stringable.} =
    "int " & $a

block:
  proc toString(a: float): string =
    "float " & $a
  
  stitch Stringable, toString

doAssert Stringable.column(toString).choice()(1) == "int 1"
doAssert Stringable.column(toString).choice()(1.0) == "float 1.0"
doAssert not compiles(Stringable.column(toString).choice()(true))

block:
  stitchDecl Stringable:
    proc toString(a: bool): string =
      "bool " & $a

doAssert Stringable.column(toString).choice()(true) == "bool true"

when false:
  unravel(Stringable) do (toString, Self):
    doAssert toString(default(Self)) == $Self & " " & $default(Self)
