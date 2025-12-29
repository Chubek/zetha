module zetha.arena;

import core.stdc.stdlib : malloc, free;
import core.stdc.string : memmove;
import core.memory : GC;
import core.lifetime : emplace;
import std.algorithm : max;

import zetha.diag : getDiagEngine, Macros;

enum GROWTH_RATE = 1.6;
enum INIT_SIZE = 2048;

enum Lifetime
{
    PERMANENT,
    TRANSUNIT,
    FUNCTION,
    SCOPE,
    INTERN,
}

struct Arena
{
    private ubyte* buffer;
    private size_t capacity;
    private size_t offset;
    private Lifetime lifetime;

    this(size_t size, Lifetime)
    {
        this.buffer = cast(ubyte*) GC.malloc(size, GC.BlkAttr.NO_SCAN);

        if (this.buffer is null)
            getDiagEngine().invokeMacro(Macros.MEMORY_ALLOCATION_FAILURE);

        this.capacity = size;
        this.offset = 0;
    }

    ~this()
    {
        GC.free(this.buffer);
    }

    @property size_t size() const pure nothrow @nogc
    {
        return this.capacity;
    }

    @property Lifetime lifetime() const pure nothrow @nogc
    {
        return this.lifetime;
    }

    void* allocate(size_t reqSize, size_t reqAlign = (void*).alignof) nothrow @nogc
    {
        size_t aligned = (offset + reqAlign) & ~(reqAlign - 1);

        if (aligned + reqSize > capacity)
            grow(max(reqSize, capacity));

        auto mem = buffer + aligned;
        this.offset = aligned + size;
        return mem;
    }

    T* alloc(T, Args...)(size_t n, Args args) nothrow @nogc
    {
        auto mem = cast(T*) allocate(n * T.sizeof);
        return emplace!T(mem, args);
    }

    void reset()
    {
        offset = 0;
    }

    private void grow(size_t minBytes) @nogc
    {
        size_t newSize = capacity * GROWTH_RATE;
        while (newSize < offset + minBytes)
            newSize *= GROWTH_RATE;

        auto newBuf = cast(ubyte*) GC.malloc(newSize);

        if (newBuf is null)
            getDiagEngine().invokeMacro(Macros.MEMORY_ALLOCATION_FAILURE);

        this.buffer = memmove(newBuf, this.buffer, newSize);

        if (this.buffer is null)
            getDiagEngine().fatal("Memory reallocation failed").thenExit();
    }
}

shared static Arena gPermArena;
shared static Arena gTUArena;
shared static Arena gFuncArena;
shared static Arena gScopeArena;
shared static Arena gInternArena;

// TODO: implement `shared static this()` for initialization
// TODO: implement functions for allocating on each arena
