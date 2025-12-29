module zetha.symbol;

import zetha.strtbl : StringHandle;
import zetha.source : SourceLoc;
import zetha.ctype : CType;

import std.array : appender;
import std.format : format;

enum SymbolKind
{
    VARIABLE,
    FUNCTION,
    PARAMETER,
    TYPEDEF,
    ENUM_CONST,
    STRUCT_TAG,
    UNION_TAG,
    ENUM_TAG,
    LABEL,
}

enum SymbolFlags : ushort
{
    NONE = 0,
    DEFINED = 1 << 0,
    USED = 1 << 1,
    FILE_SCOPE = 1 << 2,
    EXTERNAL = 1 << 3,
    INTERNAL = 1 << 4,
    TENTATIVE = 1 << 5,
    FUNC_DEFINED = 1 << 6,
    INITIALIZED = 1 << 7,
    LABEL_DEFINED = 1 << 8,
    LABEL_USED = 1 << 9,
    BUILTIN = 1 << 10,
    TEMPORARY = 1 << 11,
}

enum StorageClass
{
    AUTO,
    EXTERN,
    REGISTER,
    STATIC,
    TYPEDEF,
}

struct SymbolAttributes
{
    bool addressTaken;
    bool escapes;
    bool isReadonly;
    bool isVolatile;
    bool isCompileTimeConst;
    bool needsEmission;
    bool emitted;
    bool comdat;
    bool pinnedReg;
    bool mayAlias;
    bool noAlias;
    bool isLive;
    bool hasLifetime;
    bool isLoopLocal;
    bool isCondDefined;
    bool defInit;
    bool mayInit;
    bool zeroInit;

    uint virtReg;
    uint physReg;
    uint useCount;
    uint writeCount;
}

struct Symbol
{
    StringHandle name;
    SymbolKind kind;
    SymbolAttributes attrs;
    CType type;
    StorageClass storage;
    SymbolFlags flags;
    SourceLoc declLoc;
    SourceLoc defnLoc;
    Symbol enclosingFunc;
    int scopeLevel;

    union
    {
        long enumValue;
        int offset;
        uint labelID;
    }

    this(StringHandle name, SymbolKind kind, CType type, StorageClass storage = StorageClass.AUTO)
    {
        this.name = name;
        this.kind = kind;
        this.storage = storage;
        this.flags = SymbolFlags.NONE;
        this.declLoc = SourceLoc.uninit();
        this.defnLoc = SourceLoc.uninit();
    }

    void setFlag(SymbolFlags flag) @safe
    {
        this.flags |= flag;
    }

    void clearFlag(SymbolFlags flag) @safe
    {
        this.flags &= ~flag;
    }

    void setDeclLoc(SourceLoc loc) @safe
    {
        this.declLoc = loc;
    }

    void setDefnLoc(SourceLoc loc) @safe
    {
        this.defnLoc = loc;
    }

    void setScopeLevel(int level) @safe
    {
        this.scopeLevel = level;
    }

    void setEnumValue(long value) @safe
    {
        this.enumValue = value;
    }

    void setOffset(int offset) @safe
    {
        this.offset = offset;
    }

    void setLabelID(uint id) @safe
    {
        this.labelID = id;
    }

    void setEnclosingFunc(Symbol func) @safe
    {
        this.enclosingFunc = func;
    }

    bool isAuto() const pure nothrow @nogc @safe
    {
        return this.storage == StorageClass.AUTO;
    }

    bool isStatic() const pure nothrow @nogc @safe
    {
        return this.storage == StorageClass.STATIC;
    }

    bool isExtern() const pure nothrow @nogc @safe
    {
        return this.storage == StorageClass.EXTERN;
    }

    bool isRegister() const pure nothrow @nogc @safe
    {
        return this.storage == StorageClass.REGISTER;
    }

    bool isTypedefST() const pure nothrow @nogc @safe
    {
        return this.storage == StorageClass.TYPEDEF;
    }

    bool isDefined() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.DEFINED;
    }

    bool isUsed() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.USED;
    }

    bool isFileScope() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.FILE_SCOPE;
    }

    bool isExternal() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.EXTERNAL;
    }

    bool isInternal() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.INTERNAL;
    }

    bool isTentative() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.TENTATIVE;
    }

    bool isFuncDefined() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.FUNC_DEFINED;
    }

    bool isInitialized() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.INITIALIZED;
    }

    bool isLabelDefined() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.LABEL_DEFINED;
    }

    bool isLabelUsed() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.LABEL_USED;
    }

    bool isBuiltin() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.BUILTIN;
    }

    bool isTemporary() const pure nothrow @nogc @safe
    {
        return this.flags & SymbolFlags.TEMPORARY;
    }

    bool isVariable() const pure nothrow @nogc @safe
    {
        return this.kind == SymbolKind.VARIABLE;
    }

    bool isFuncction() const pure nothrow @nogc @safe
    {
        return this.kind == SymbolKind.FUNCTION;
    }

    bool isParameter() const pure nothrow @nogc @safe
    {
        return this.kind == SymbolKind.PARAMETER;
    }

    bool isTypedef() const pure nothrow @nogc @safe
    {
        return this.kind == SymbolKind.TYPEDEF;
    }

    bool isEnumConstant() const pure nothrow @nogc @safe
    {
        return this.kind == SymbolKind.ENUM_CONSTANT;
    }

    bool isTag() const pure nothrow @nogc @safe
    {
        return this.kind == SymbolKind.STRUCT_TAG
            || this.kind == SymbolKind.UNION_TAG || this.kind == SymbolKind.ENUM_TAG;
    }

    bool isLabel() const pure nothrow @nogc @safe
    {
        return this.kind == SymbolKind.LABEL;
    }

    bool hasExternalLinkage() const pure nothrow @nogc @safe
    {
        if (this.isFileScope())
            return false;

        if (this.isStatic())
            return false;

        return this.isFunction() || this.isVariable();
    }

    bool hasInternalLinkage() const pure nothrow @nogc @safe
    {
        if (this.isFileScope())
            return false;

        return this.isStatic();
    }

    bool hasNoLinkage() const pure nothrow @nogc @safe
    {
        if (this.isFileScope() && this.isStatic())
            return true;

        if (this.isParameter())
            return true;

        if (this.isTypedef() || this.isEnumConst() || this.isLabel())
            return true;

        return false;
    }

    bool livesOnStack() const pure nothrow @nogc @safe
    {
        return this.isRegister() || this.isAuto();
    }

    bool spillsToMemory() const pure nothrow @nogc @safe
    {
        return !this.isRegister();
    }
}
