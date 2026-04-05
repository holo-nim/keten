import glaze, std/macrocache

when false:
  # XXX this needs to be used so the nodes can be serialized properly
  type
    CuleTypeKind* = enum
      CuleExpr
      CuleTypedesc
      CuleStatic
      CuleTyped
    CuleType* = object
      case kind*: CuleTypeKind
      of CuleExpr:
        exprTyped*: bool
      of CuleTypedesc, CuleStatic, CuleTyped:
        constraint*: RawNimNode

type
  CuleField* = object
    column*: int
    name*: string
    `type`*: RawNimNode # can be untyped, typed, static, typedesc, or other typed node
    default*: RawNimNode
  CuleSchema* = object
    fields*: seq[CuleField]

proc getColumn*(schema: CuleSchema, name: string): int =
  result = -1
  for i, field in schema.fields:
    if field.name == name:
      return i

proc toNode*(schema: CuleSchema): NimNode =
  glaze(schema)

proc toSchema*(node: NimNode): CuleSchema =
  deglaze(node, result)

type SchemaId* = string

const schemas* = CacheTable"cule.schemas"

proc addSchema*(id: SchemaId, schema: CuleSchema) =
  schemas[id] = toNode(schema)

proc getSchema*(id: SchemaId): CuleSchema =
  toSchema(schemas[id])

type CuleFrozenError* = object of CatchableError

const freezes* = CacheTable"cule.freezes"

proc freeze*(id: SchemaId) {.compileTime.} =
  freezes[id] = glaze true

proc isFrozen*(id: SchemaId): bool {.compileTime.} =
  id in freezes and deglaze(freezes[id], bool)

proc getSchemaDataHandle*(id: SchemaId): string =
  "cule.data." & id

# maybe indexes?
