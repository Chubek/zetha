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
    BOOLEAN,
    VOID,
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

    bool isBasic() const pure nothrow @nogc @safe
    {
        return this.isIntegral() || this.isReal() || this.isVoid() || this.isBoolean();
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
        return this.kind == TypeKind.VOID;
    }

    bool isBoolean() const pure nothrow @nogc @safe
    {
        return this.kind = TypeKind.BOOL;
    }

    bool isFunction() const pure nothrow @nogc @safe
    {
	return this.kind == TypeKind.FUNCTION;
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

    // TODO: these methods must be relegated to their own class

/*
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
*/
    @property size_t size() const pure @safe
    {
	return sizeImpl();
    }

    @property ushort alignment() const pure @safe
    {
	return alignmentImpl();
    }

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

    string toStringWithName(string variableName) pure @safe
    {
        return toStringWithNameImpl(variableName);
    }

    bool isCompatibleWith(const CType other) pure @safe
    {
        return isCompatibleWithImpl(other);
    }

    bool isConvertibleTo(const CType other) pure @safe
    {
        return isConvertibleToImpl(other);
    }

    CType castTo(const CType other) pure @safe
    {
        return castToImpl(other);
    }

    CType usualArithConv(const CType other) pure @safe
    {
        return usualArithConvImpl(other);
    }

    CType promoteType(const CType other) pure @safe
    {
        return promoteImpl(other);
    }

    protected abstract size_t sizeImpl() const pure nothrow @safe;
    protected abstract ushort alignmentImpl() const pure nothrow @safe;

    protected abstract CType withQualImpl(TypeQual newQual) pure @safe;
    protected abstract string toStringWithNameImpl(string name) pure @safe;
    protected abstract bool isCompatibleWithImpl(const CType other) const pure nothrow @safe;
    protected abstract bool isConvertibleToImpl(const CType other) const pure nothrow @safe;
    protected abstract CType castToImpl(const CType other) const pure nothrow @safe;
    protected abstract CType usualArithConvImpl(const CType other) const pure nothrow @safe;
    protected abstract CType promoteImpl(const CType other) const pure nothrow @safe;
}

class IntegralType : CType
{
    // TODO
}

class RealType : CType
{
    // TODO
}

class BooleanType : CType
{
    // TODO
}

class VoidType : CType
{
    // TODO
}

class ArrayType : CType
{
    // TODO
}

class PointerType : CType
{
    // TODO
}

class ArrayType : CType
{
    // TODO
}

class StructType : CType
{
    // TODO
}

class UnionType : CType
{
    // TODO
}

class TypedefType : CType
{
    // TODO
}

class FunctionType : CType
{
    // TODO
}
