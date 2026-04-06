import glaze, std/[macrocache, macros]

type
  KetinAtomKind* = enum
    ExprAtom
    TypeAtom
    StaticAtom
  KetinAtomType* = object
    case kind*: KetinAtomKind
    of ExprAtom, TypeAtom, StaticAtom:
      constraint*: RawNimNode
  KetinField* = object
    # or "strand"
    column*: int
    name*: string
    `type`*: KetinAtomType # can be untyped, typed, static, typedesc, or other typed node
    default*: RawNimNode
  KetinSchema* = object
    # or "fabric"
    fields*: seq[KetinField]
    readRequiresFreeze*: bool

proc getColumn*(schema: KetinSchema, name: string): int =
  result = -1
  for i, field in schema.fields:
    if field.name == name:
      return i

proc toNode*(schema: KetinSchema): NimNode =
  glaze(schema)

proc toSchema*(node: NimNode): KetinSchema =
  deglaze(node, result)

type SchemaId* = string

const schemas* = CacheTable"ketin.schemas"

proc addSchema*(id: SchemaId, schema: KetinSchema) =
  schemas[id] = toNode(schema)

proc getSchema*(id: SchemaId): KetinSchema =
  toSchema(schemas[id])

proc readRequiresFreeze*(id: SchemaId): bool =
  result = false
  let node = schemas[id]
  for i in 1 ..< node.len:
    assert node[i].kind == nnkExprColonExpr
    if node[i][0].eqIdent"readRequiresFreeze":
      result = deglaze(node[i][1], bool)
      return result

type
  FrozenError* = object of CatchableError
  NotFrozenError* = object of CatchableError

const freezes* = CacheTable"ketin.freezes"

proc freeze*(id: SchemaId) {.compileTime.} =
  freezes[id] = glaze true

proc isFrozen*(id: SchemaId): bool {.compileTime.} =
  id in freezes and deglaze(freezes[id], bool)

proc getSchemaDataHandle*(id: SchemaId): string =
  "ketin.data." & id

# maybe indexes?
