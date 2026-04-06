import std/macros

type TypeSectionGen* = enum Statement, TypeSection, TypeDef

proc detectTypeSection*(arg: NimNode): TypeSectionGen =
  case arg.kind
  of nnkTypeDef:
    when (NimMajor, NimMinor) >= (2, 0): result = TypeSection
    else: result = TypeDef
  of nnkTypeSection: result = TypeSection # to be safe for any future changes
  else: result = Statement

when false:
  proc wrap*(gen: TypeSectionGen, typeSection: NimNode, remaining: seq[NimNode]): NimNode =
    case gen
    of Statement:
      result = newStmtList()
      if not typeSection.isNil: result.add typeSection
      result.add remaining
    of TypeSection:
      result = if typeSection.isNil: newNimNode(nnkTypeSection) else: typeSection
      var i = 0
      while i < remaining.len:
        let st = remaining[i]
        case st.kind
        of nnkTypeDef:
          result.add st
          inc i
        of nnkTypeSection:
          for td in st: result.add td
          inc i
        else:
          var val = newNimNode(nnkStmtListType, typeSection)
          val.add st
          var j = i + 1
          while j < remaining.len and remaining[j].kind notin {nnkTypeDef, nnkTypeSection}:
            val.add remaining[j]
            inc j
          i = j
          val.add bindSym"void"
          result.add newTree(nnkTypeDef, genSym(nskType, "_"), newEmptyNode(), val)
      if result.len == 0:
        result.add newTree(nnkTypeDef, genSym(nskType, "_"), newEmptyNode(), bindSym"void")
    of TypeDef:
      if not typeSection.isNil and typeSection.len == 1:
        result = typeSection[0]
      else:
        var val = newNimNode(nnkStmtListType)
        if not typeSection.isNil: val.add typeSection
        val.add remaining
        val.add bindSym"void"
        result = newTree(nnkTypeDef, genSym(nskType, "_"), newEmptyNode(), val)

proc wrap*(gen: TypeSectionGen, stmts: NimNode): NimNode =
  case gen
  of Statement:
    result = stmts
  of TypeSection:
    if stmts.isNil: return nil
    case stmts.kind
    of nnkTypeDef:
      result = newNimNode(nnkTypeSection, stmts)
      result.add stmts
    of nnkTypeSection:
      result = stmts
    of nnkStmtList, nnkStmtListExpr, nnkStmtListType:
      result = newNimNode(nnkTypeSection, stmts)
      var i = 0
      while i < stmts.len:
        let st = stmts[i]
        case st.kind
        of nnkTypeDef:
          result.add st
          inc i
        of nnkTypeSection:
          for td in st: result.add td
          inc i
        of nnkStmtList, nnkStmtListExpr, nnkStmtListType:
          let ts = wrap(gen, st)
          for td in ts: result.add td
          inc i
        else:
          var val = newNimNode(nnkStmtListType, st)
          val.add st
          var j = i + 1
          while j < stmts.len and stmts[j].kind notin {nnkTypeDef, nnkTypeSection, nnkStmtList, nnkStmtListExpr, nnkStmtListType}:
            val.add stmts[j]
            inc j
          i = j
          val.add bindSym"void"
          result.add newTree(nnkTypeDef, genSym(nskType, "_"), newEmptyNode(), val)
      if result.len == 0:
        result.add newTree(nnkTypeDef, genSym(nskType, "_"), newEmptyNode(), bindSym"void")
    else:
      result.add newTree(nnkTypeDef, genSym(nskType, "_"), newEmptyNode(),
        newTree(nnkStmtListType, stmts, bindSym"void"))
  of TypeDef:
    let temp = wrap(TypeSection, stmts)
    if temp.len == 1:
      result = temp[0]
    else:
      result = newTree(nnkTypeDef, genSym(nskType, "_"), newEmptyNode(),
        newTree(nnkStmtListType, stmts, bindSym"void"))
