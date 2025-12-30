module zetha.arena;

import core.stdc.string : memmove;
import core.memory : GC;
import core.lifetime : emplace;
import std.algorithm : max;

enum GROWTH_RATE = 2;
enum INIT_SIZE = 2048;

enum Lifetime
{
    PERMANENT,
    FILE,
    FUNCTION,
    SCOPE,
    POOL,
}

struct Arena
{
    private ubyte* buffer;
    private size_t capacity;
    private size_t offset;
    private Lifetime lifetime;

    this(size_t size = INIT_SIZE, Lifetime lifetime = Lifetime.SCOPE)
    {
        this.buffer = cast(ubyte*) GC.malloc(size, GC.BlkAttr.NO_SCAN);

        if (this.buffer is null)
            throw new Exception("Null buffer");

        this.capacity = size;
        this.offset = 0;
        this.lifetime = lifetime;
    }

    ~this()
    {
        GC.free(this.buffer);
    }

    @property size_t size() const pure nothrow @nogc @safe
    {
        return this.capacity;
    }

    @property Lifetime providence() const pure nothrow @nogc @safe
    {
        return this.lifetime;
    }

    void* allocate(size_t reqSize, size_t reqAlign = (void*).alignof) @safe @trusted
    {
        size_t aligned = (offset + reqAlign) & ~(reqAlign - 1);

        if (aligned + reqSize > capacity)
            grow(max(reqSize, capacity));

        auto mem = buffer + aligned;
        this.offset = aligned + size;
        return mem;
    }

    T* alloc(T, Args...)(size_t n, Args args) @safe @trusted
    {
        auto mem = cast(T*) allocate(n * T.sizeof);
        return emplace!T(mem, args);
    }

    T[] allocArray(T, Args...)(size_t n, Args args) @safe @trusted @nogc
    {
        T* pointer = this.alloc!T(n, args);
        T[] array = pointer[0 .. n];
        return array;
    }

    void reset()
    {
        offset = 0;
    }

    private void grow(size_t minBytes) @safe @trusted
    {
        size_t newSize = capacity * GROWTH_RATE;
        while (newSize < offset + minBytes)
            newSize *= GROWTH_RATE;

        auto newBuf = cast(ubyte*) GC.malloc(newSize);

        if (newBuf is null)
            throw new Exception("Null buffer");

        this.buffer = cast(ubyte*) memmove(newBuf, this.buffer, newSize);

        if (this.buffer is null)
            throw new Exception("Null buffer");
    }
}
