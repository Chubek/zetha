module zetha.symbol.symbol;

import zetha.providers.memory : SymbolAllocator;
import zetha.providers.strpool : StringHandle;
import zetha.providers.cspecs : CKeywordProvider;
import zetha.providers.abstyy : Set;
import zetha.provenance.srcfile : SourceLocation, SourceSite;
import zetha.typespec.core : CType;

enum SymbolKind : ubyte
{
    VARIABLE,
    FUNCTION,
    PARAMETER,
    ENUM_CONST,
    ENUM_TAG,
    STRUCT_FIELD,
    STRUCT_TAG,
    UNION_FIELD,
    UNION_TAG,
    TYPEDEF,
    LABEL,
}

enum ComputedAttr : ubyte
{
    ADDRESSED = 1 << 0,
    COMPUTED = 1 << 1,
    TEMPORARY = 1 << 2,
    GENERATED = 1 << 3,
    DEFINED = 1 << 4,
}

struct Symbol
{
    private uint _id;
    private SymbolKind _kind;
    private StringHandle _name;
    private SourceLocation _location;
    private SourceSite _defSite;
    private CType _type;
    private Set!ComputedAttr _computedAttrs;

    this(uint id, SymbolKind kind, StringHandle name, SourceLocation location,
            SourceSite defSite, CType type)
    {
        this._id = id;
        this._kind = kind;
        this._name = name;
        this._deSite = defSite;
        this._type = type;
        this._computedAttrs = Set.init;
    }

    size_t toHash() const pure nothrow @nogc @safe @trusted
    {
        return this._id;
    }

    size_t toString() const pure nothrow @nogc @safe @trusted
    {
        import std.format : format;

        auto resolvedName = this._name.resolve();
        return format("%s::%s", resolvedName, this._type.toString());
    }

    // TODO
}
