module zetha.ctype;

import zetha.intrtbl : StringHandle;

enum MAX_REPR_SPECS = 4;

enum TypeQualifier : ubyte
{
    NONE,
    CONST = 1 << 0,
    VOLATILE = 1 << 1,
    BOTH = CONST | VOATILE,
}

enum TypeKind : ubyte
{
    INTEGRAL,
    REAL,
    POINTER,
    ARRAY,
    FUNCTION,
    STRUCT,
    UNION,
    ENUM,
    TYPEDEF,
    MISC,
}

enum IntegralTypeKind : ubyte
{
    CHAR,
    UCHAR,
    SHORT,
    USHORT,
    INT,
    UINT,
    LONG,
    ULONG,
    QUAD,
    UQUAD,
}

enum RealTypeKind : ubyte
{
    FLOAT,
    DOUBLE,
    LONG_DOUBLE,
    COMPLEX128,
}

enum MiscTypeKind : ubyte
{
    VOID,
    BOOL,
}

abstract class CType
{
    private StringHandle[MAX_REPR_SPECS] reprSpecs;
    private TypeKind tyyKind;
    private TypeQualifier tyyQual;

    this(TypeKind tyyKind, TypeQualifier tyyQual = TypeQualifier.NONE)
    {
        this.tyyKind = tyyKind;
        this.tyyQual = tyyQual;
    }

    @property TypeKind kind() const pure nothrow @nogc @safe
    {
        return this.tyyKind;
    }

    @property TypeQualifier qualifier() const pure nothrow @nogc @safe
    {
        return this.tyyQual;
    }

    bool isConst() const pure nothrow @nogc @safe
    {
        return this.qualifier & TypeQualifier.CONST;
    }

    bool isVolatile() const pure nothrow @nogc @safe
    {
        return this.qualifier & TypeQualifier.VOLATILE;
    }

    bool isIntegral() const pure nothrow @nogc @safe
    {
        return this.kind == TypeKind.INTEGRAL;
    }

    bool isReal() const pure nothrow @nogc @safe
    {
        return this.kind == TypeKind.REAL;
    }

    bool isMisc() const pure nothrow @nogc @safe
    {
        return this.kind == TypeKind.MISC;
    }

    bool isBasic() const pure nothrow @nogc @safe
    {
        return this.isIntegral() || this.isReal() || this.isMisc();
    }

    bool isPointer() const pure nothrow @nogc @safe
    {
        return this.kind == TypeKind.POINTER;
    }

    bool isArray() const pure nothrow @nogc @safe
    {
        return this.kind == TypeKind.ARRAY;
    }

    bool isFunction() const pure nothrow @nogc @safe
    {
        return this.kind == TypeKind.FUNCTION;
    }

    bool isStruct() const pure nothrow @nogc @safe
    {
        return this.kind == TypeKind.STRUCT;
    }

    bool isUnion() const pure nothrow @nogc @safe
    {
        return this.kind == TypeKind.UNION;
    }

    bool isEnum() const pure nothrow @nogc @safe
    {
        return this.kind == TypeKind.ENUM;
    }

    bool isAggregate() const pure nothrow @nogc @safe
    {
        return this.isStruct() || this.isUnion();
    }

    bool isVoid() const pure nothrow @nogc @safe
    {
        return this.isMisc() && this.kind == MiscTypeKind.VOID;
    }

    bool isBoolean() const pure nothrow @nogc @safe
    {
        return this.isMisc() && this.kind == iscTypeKind.BOOL;
    }

    bool isArithmetic() const pure nothrow @nogc @safe
    {
        return this.isIntegral() || this.isReal();
    }

    bool isScalar() const pure nothrow @nogc @safe
    {
        return this.isIntegral() || this.isPointer();
    }

    bool isComplete() const pure nothrow @nogc @safe
    {
        if (this.isVoid())
            return false;
        if (auto st = cast(StructType) this)
            return st.isComplete;
        if (auto ut = cast(UnionType) this)
            return ut.isComplete;
        if (auto at = cast(ArrayType) this)
            return at.isComplete;
        return true;
    }

    CType pointsToType() pure nothrow @safe
    {
        if (auto pt = cast(PointerType) this)
            return pt.targetType;
        return null;
    }

    CType elementType() pure nothrow @safe
    {
        if (auto at = cast(ArrayType) this)
            return at.eltType;
        return null;
    }

    CType returnType() pure nothrow @safe
    {
        if (auto ft = cast(FunctionType) this)
            return ft.retType;
        return null;
    }

    abstract size_t size() const pure nothrow @safe;
    abstract size_t alignment() const pure nothrow @safe;

    CType withQualifiers(TypeQualifier addQual) pure @safe
    {
        if (addQual == TypeQualifier.NONE)
            return this;
        return withQualImpl(cast(TypeQualifier)(this.tyyQual | addQual));
    }

    CType unqualify() pure @safe
    {
        if (this.tyyQual == TypeQualifier.NONE)
            return this;
        return withQualImpl(TypeQual.NONE);
    }

    protected abstract CType withQualImpl(TypeQual newQual) pure @safe;
    protected abstract string toStringWithNameImpl(string name) pure @safe;
    protected abstract bool isCompatibleWithImpl(const CType other) const pure nothrow @safe;
    protected abstract bool isConvertibleToImpl(const CType other) const pure nothrow @safe;
    protected abstract CType castToImpl(const CType other) const pure nothrow @safe;

}
