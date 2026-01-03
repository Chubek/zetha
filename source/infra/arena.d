module zetha.infra.arena;

import zetha.infra.config : Config;
import zetha.infra.strpool : StringHandle;

import std.lifetime : emplace;
import core.stdc.string : memmove;
import core.memory : GC;

enum MemoryProvedance
{
    PERMANENT,
    FUNCTION,
    SCOPE,
}

struct Arena
{
    private void* _memory;
    private size_t _capacity;
    private size_t _offset;
    private size_t _align = Config.MemAlign;
    private size_t _resizeRatio = Config.ResizeRatio;
    private MemoryProvedance _provedance;

    this(size_t capacity, MemoryProvedance provedance = MemoryProvedance.SCOPE)
    {
        this._capacity = capacity;
        this._offset = 0;
        this._provedance = provedance;
        this._memory = cast(void*) GC.malloc(capacity);
    }

    ~this()
    {
        GC.free(this._memory);
    }

    @property size_t capacity() pure const nothrow @safe
    {
        return this._capacity;
    }

    @property size_t offset() pure const nothrow @safe
    {
        return this._offset;
    }

    @property MemoryProvedance provedance() pure const nothrow @safe
    {
        return this._provedance;
    }

    size_t roundUp(size_t reqSize) pure const nothrow @safe
    {
        return (reqSize + (this._align) - 1) & ~(this._align - 1);
    }

    void* allocate(size_t unitSize, size_t numUnit) nothrow @safe @trusted
    {
        if ((this.offset / this.capacity) >= this._resizeRatio)
            growArena();

        auto reqSizeAligned = roundUp(unitSize * numUnit);

        void* reqMem = this._memory + this._offset;
        this._offset += reqSizeAligned;

        return reqMem;
    }

    T* allocateSafely(T, Args...)(size_t numUnits, Args ctors) nothrow @safe @trusted
    {
        void* memory = allocate(T.sizeof, numUnits);
        return emplace!T(memory, ctors);
    }

    void growArena() nothrow @safe
    {
        size_t newSize = roundUp(this.capacity * 2);
        void* newMemory = GC.malloc(newSize);

        this._memory = memmove(newMemory, this._memory, this.offset);
        this._capacity = newSize;
    }
}

shared static Arena gPermanentArena;
shared static Map!(StringHandle, Arena) gFunctionArena;
shared static Stack!Arena gScopeArena;

static this()
{
    gPermanentArena = Arena(Config.PermanentArenaSize);
    gFunctionArena = new Map!(StringHandle, Arena);
    gScopeArena = new Stack!(Arena).init;
}

T* allocatePermanently(T, Args...)(size_t numUnits, Args ctors)
{
    return gPermanentArena.allocateSafely!T(numUnits, ctors);
}

T* allocateForFunction(T, Args...)(StringHandle funcName, size_t numUnits, Args ctors)
{
    return gFunctionArena[funcName].allocateSafely!T(numUnits, ctors);
}

T* allocateForScope(T, Args...)(size_t numUnits, Args ctors)
{
    return gScopeArena.front.allocateSafely!T(numUnits, ctors);
}

void pushScopeArena() @safe @trusted
{
    gScopeArena.pushBlankFront();
}

void popScopeArena() @safe @trusted
{
    gScopeArena.popFront();
}
