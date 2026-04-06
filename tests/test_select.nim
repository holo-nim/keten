import ketin

type Values {.fabric: ().} = object
  val: untyped

const foo {.stitchDecl: Values.} = 123

doAssert Values.column(0).pick == 123

Values.stitch 456
Values.stitch 789

doAssert Values.column(0).pluck == 123
doAssert Values.column(0).collect([]) == [123, 456, 789]
doAssert Values.column(val).collect({range[0..1000](0)}) == {range[0..1000](0), 123, 456, 789}

type Overloads {.fabric: ().} = object
  sym: typed

proc bazInt(x: int): string {.stitchDecl: Overloads.} = "int " & $x
proc bazFloat(x: float): string {.stitchDecl: Overloads.} = "float " & $x

doAssert choice(Overloads.column(0))(123) == "int 123"
doAssert choice(Overloads.column(0))(1.23) == "float 1.23"
