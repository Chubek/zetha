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

    this()
    {
        this._id = this._idCounter++;
    }

    @property size_t id() const pure nothrow @safe @trusted
    {
        return this._id;
    }

    string toString() const pure @safe @trusted
    {

        auto underlying = gStringPool.externString(this.id);
        enforce(underlying !is null, "String externing failed");
        return to!string(underlying);
    }

    size_t toHash() const pure @safe @trusted
    {
        return this.id;
    }

    bool opEquals(const StringHandle other) const pure nothrow @safe @trusted
    {
        return this._id == other._id;
    }

    // TODO: add operator methods
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
