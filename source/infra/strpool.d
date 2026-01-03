module zetha.infra.strpool;

import zetha.infra.config : Config;
import zetha.infra.arena : allocatePermanently;

import core.stdc.string : memmove;
import core.atomic : atomicFetchAdd;
import std.traits : isSomeString;
import std.exception : enforce;
import std.conv : to;

struct StringHandle
{
    private size_t _id;
    private shared size_t _idCounter = 0;
    private string _externCache;

    this()
    {
        this._id = this._idCounter;
        this._idCounter = atomicFetchAdd(this._idCounter, 1);
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

    string toString() @safe @trusted
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

        import std.algorithm.cmp;

        return cmp(this.repr, other.repr);

    }
}

class StringPool
{
    private immutable(char)* _pool;
    private size_t _capacity;
    private size_t _used;
    private size_t[] _offsets;
    private size_t[] _lengths;
    private size_t[string] _strToID;

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

    StringHandle internString(immutable(char)* str, size_t len) @safe @trusted
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
        if (auto exists = this.handleDedup(data, len))
            return *exists;

        size_t requiredSpace = len + 1;
        enforce(this.used + requiredSpace <= this.capacity, "String Pool capacity exceeded");

        size_t offset = this.used;
        this._offsets ~= offset;

        char* mutablePool = cast(char*) this._pool;
        memmove(cast(void*)(mutablePool + offset), cast(const(void)*) data, len);
        (mutablePool + offset)[len] = '\0';

        this._used += requiredSpace;
        this._lengths ~= len;

        auto handle = StringHandle();
        this._strToID[handle.id] = data[0 .. len].idup;
        return handle;
    }

    private StringHandle handleDedup(const(immutable(char)*) data, size_t len)
    {
        string candidate = data[0 .. len].idup;

        if (auto existing = candidate in this._strToID)
            return StringHandle(*existing);

        return null;
    }

    string externString(size_t id) const pure @safe @trusted
    {
        if (id >= this.offsets.length)
            return null;
        size_t offset = this._offsets[id];
        size_t length = this._lengths[id];
        return to!string(this._pool[offset .. offset + length]);
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

StringHandle internCString(immutable(char)[] str)
{
    return gStringPool.internString(str);
}
