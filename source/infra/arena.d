module zetha.infra.arena;

import zetha.infra.config : Config;
import zetha.infra.strpool : StringHandle;
import zetha.infra.abstyy : Set;

import std.lifetime : emplace;
import core.stdc.string : memmove;
import core.memory : GC;

enum MemoryProvenance
{
    PERMANENT,
    FUNCTION,
    SCOPE,
    TEMPORARY,
}

struct Arena
{
    private void* _memory;
    private size_t _capacity;
    private size_t _offset;
    private size_t _align = Config.MemAlign;
    private size_t _resizeRatio = Config.ResizeRatio;
    private MemoryProvenance _provanence;

    this(size_t capacity, MemoryProvenance provanence = MemoryProvenance.SCOPE)
    {
        assert((capacity & (capacity - 1)) == 0, "Capacity must be power of 2");
        this._capacity = capacity;
        this._offset = 0;
        this._provanence = provanence;
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

    @property MemoryProvenance provanence() pure const nothrow @safe
    {
        return this._provanence;
    }

    @property float ratio() pure const nothrow @safe
    {
        return (cast(float) this.offset) / (cast(float) this.capacity);
    }

    size_t roundUp(size_t reqSize) pure const nothrow @safe
    {
        return (reqSize + (this._align) - 1) & ~(this._align - 1);
    }

    void reset() nothrow @safe
    {
        this._offset = 0;
    }

    void* allocate(size_t unitSize, size_t numUnit) nothrow @safe @trusted
    {
        if (this.ratio >= this._resizeRatio)
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
        memmove(cast(const(void)*) newMemory, cast(const(void)*) this._memory, this.offset);
        GC.free(this._memory);
        this._memory = newMemory;
        this._capacity = newSize;
    }
}

synchronized shared static Arena gPermanentArena;
synchronized shared static Arena[StringHandle] gFunctionArena;
synchronized shared static Stack!Arena gScopeArena;
synchronized shared static Arena gTemporaryArena;

static this()
{
    gPermanentArena = Arena(Config.PermanentArenaSize, MemoryProvenance.PERMANENT);
    gTemporaryArena = Arena(Config.TemporaryArenaSize, MemoryProvenance.TEMPORARY);
    gFunctionArena = new Arena[StringHandle];
    gScopeArena = new Stack!(Arena);
}

T* allocatePermanently(T, Args...)(size_t numUnits, Args ctors)
{
    return gPermanentArena.allocateSafely!T(numUnits, ctors);
}

T* allocateTemporarily(T, Args...)(size_t numUnits, Args ctors)
{
    return gTemporaryArena.allocateSafely!T(numUnits, ctors);
}

T* allocateForFunction(T, Args...)(StringHandle funcName, size_t numUnits, Args ctors)
{
    return gFunctionArena[funcName].allocateSafely!T(numUnits, ctors);
}

T* allocateForScope(T, Args...)(size_t numUnits, Args ctors)
{
    return gScopeArena.front.allocateSafely!T(numUnits, ctors);
}

void newFunctionArena(StringHandle funcName) @safe @trusted
{
    gFunctionArena[funcName] = Arena(Config.FunctionArenaSize, MemoryProvenance.FUNCTION);
}

void pushScopeArena() @safe @trusted
{
    gScopeArena.push(Arena(Config.ScopeArenaSize));
}

void popScopeArena() @safe @trusted
{
    gScopeArena.popFront();
}
