module zetha.infra.strpool;

import zetha.infra.config : Config;
import zetha.infra.arena : allocatePermanently;

import core.stdc.string : memmove;
import std.traits : isSomeString;
import std.exception : enforce;
import std.conv : to;

struct StringHandle
{
    private size_t _id;
    private static size_t _idCounter = 0;
    private string _externCache;

    this()
    {
        this._id = this._idCounter++;
        this._externCache = null;
    }

    @property size_t id() const pure nothrow @safe @trusted
    {
        return this._id;
    }

    @property string repr() const pure nothrow @safe @trusted
    {
        return this._externCache;
    }

    string toString() const pure @safe @trusted
    {
        if (this._externCache !is null)
            return this._externCache;

        auto underlying = gStringPool.externString(this.id);
        enforce(underlying !is null, "String externing failed");
        this._externCache = to!string(underlying);
        return this._externCache;
    }

    alias getExternRepr = toString;

    size_t toHash() const pure @safe @trusted
    {
        return this.id;
    }

    bool opEquals(const StringHandle other) const pure nothrow @safe @trusted
    {
        return this._id == other._id;
    }

    int opCmp(const StringHandle other) const pure nothrow @safe @trusted
    {
        if (this.repr is null)
            this.getExternRepr();

        if (other.repr is null)
            other.getExternRepr();

        if (this.repr[0] > other.repr[0])
            return 1;
        if (this.repr[0] < other.repr[0])
            return -1;

        return 0;

    }
}

class StringPool
{
    private immutable(char)* _pool;
    private size_t _capacity;
    private size_t _used;
    private size_t[] _offsets;

    this(size_t capacity)
    {
        this._capacity = capacity;
        this._used = 0;
        this._offsets = [];
        this._offsets.length = 0;
        this._pool = allocatePermanently!(immutable(char))(capacity);
    }

    @property size_t capacity() const pure
    {
        return this._capacity;
    }

    @property size_t used() const pure
    {
        return this._used;
    }

    StringHandle internString(immutable(char)* str, size_t length) @safe @trusted
    {
        enforce(str !is null, "Cannot intern null pointer");
        return internStringImpl(str, len);
    }

    StringHandle internString(S)(S str) if (isSomeString!S)
    {
        auto utf8Str = to!(immutable(char)[])(str);
        return internStringImpl(utf8Str.ptr, utf8Str.length);
    }

    private StringHandle internStringImpl(const(immutable(char)*) data, size_t len) @safe
    {
        size_t requiredSpace = len + 1;
        enforce(this.used + requiredSpace <= this.capacity, "String Pool capacity exceeded");

        size_t offset = this.used;
        this.offsets ~= offset;

        memmove(cast(void*)(this._pool + offset), cast(const(void)*) data, len);
        (this._pool + offset)[len] = '\0';

        this._used += requiredSpace;

        return StringHandle();
    }

    string externString(size_t id) const pure @safe @trusted
    {
        if (id >= this.offsets.length)
            return null;
        return this._pool + this._offsets[id];
    }
}

synchronized shared static StringPool gStringPool;

static this()
{
    gStringPool = new StringPool(Config.StrPoolSize);
}

StringHandle internDString(string str)
{
    return gStringPool.internString(str);
}
