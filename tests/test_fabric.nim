import ketin

type Foo {.fabric: ().} = object
  id: static int
  name: static string
  typ: typedesc

stitch Foo, 0, "abc", int
Foo.stitch 1, "def", float
Foo.stitch 2, "ghi", string

import std/strutils

proc take(s: string, T: type int): T = parseInt(s)
proc take(s: string, T: type float): T = parseFloat(s)
proc take(s: string, T: type string): T = s

proc print(x: int): string = "got int: " & $x
proc print(x: float): string = "got float: " & $x
proc print(x: string): string = "got string: " & $x

proc process(a: int, b: string): string =
  Foo.column(id).dispatch(a) do (id, name, typ):
    let val = take(b, typ)
    result = print(val) & " for " & name
  else: result = "invalid id: " & $a

doAssert process(0, "123") == "got int: 123 for abc"
doAssert process(0, "4000") == "got int: 4000 for abc"
doAssert process(0, "-5") == "got int: -5 for abc"
doAssert process(1, "1.23") == "got float: 1.23 for def"
doAssert process(1, "NaN") == "got float: nan for def"
doAssert process(2, "xyz") == "got string: xyz for ghi"
doAssert process(3, "...") == "invalid id: 3"
doAssert process(5, "") == "invalid id: 5" 
doAssert process(-1, "...") == "invalid id: -1"

proc getName(i: static int): string =
  Foo.column(id).find(i) do (id, name, typ):
    result = name
  else:
    result = "invalid"
doAssert getName(1) == "def"
doAssert getName(-1) == "invalid"
doAssert getName(0) == "abc"
doAssert getName(3) == "invalid"

proc getIdFromName(name: string): int =
  Foo.column(name).dispatch(name) do (id, _, _):
    result = id
  else:
    result = -1

doAssert getIdFromName("def") == 1
doAssert getIdFromName("") == -1
doAssert getIdFromName("ghi") == 2
doAssert getIdFromName("abc") == 0
doAssert getIdFromName("jkl") == -1
