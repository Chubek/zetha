module zetha.strpool;

import zetha.services : CKeywordProvider, BinarySerde, PlainTextSerde, fnv1Hash;
import zetha.arena : StringPoolAllocator;
import zetha.diag : DiagMacros;

import std.traits : isSomeString;
import std.string : toStringz, fromStringz;
import core.stdc.string : memcmp;

struct StringHandle
{
    private uint index = 0;

    enum StringHandle invalid = StringHandle(0);

    @property bool isValid() const pure nothrow @nogc @safe
    {
        return this != invalid;
    }

    @property uint index() const pure nothrow @nogc @safe
    {
        return this.index;
    }

    bool opEquals(const StringHandle other) const pure nothrow @nogc @safe
    {
        return this.index == other.index;
    }

    int opCmp(const StringHandle other) const pure nothrow @nogc @safe
    {
        return (this.index > other.index) - (this.index < other.index);
    }

    size_t toHash() const pure nothrow @nogc @safe
    {
        return this.index;
    }
}

struct StringPool
{
    private struct Entry
    {
        uint start;
        uint length;
        uint hash;
        uint next;
    }

    private char* pool;
    private Entry* entries;
    private uint poolPtr = 0;
    private uint entrycount = 1;

    private uint[] hashTbl;
    private uint hashMask;

    private enum INIT_POOL_SIZE = 32 * 1024;
    private enum INIT_ENTRY_COUNT = 1024;
    private enum INIT_HASH_SIZE = 2048;
    private enum LOAD_FACTOR_THRESHOLD = 70;

    static StringPool create()
    {
        return createWithCapacity(INIT_POOL_SIZE, INIT_ENTRY_COUNT);
    }

    static StringPool createWithCapacity(size_t poolCapacity, size_t maxStrings)
    {
        StringPool sp;

        sp.pool = PoolAllcator.allocatePoolMemory(poolCapacity);
        sp.entries = PoolAllcator.allocateEntryMemory(maxStrings);
        sp.entries[0] = Entry(0, 0, 0, 0);

        size_t hashSize = INIT_HASH_SIZE;
        while (hashSize < maxStrings)
            hashSize *= 2;

        sp.hashTbl = StringPoolAllocator.allocateHashTblMemory(hashSize);
        sp.hashTbl[] = 0;
        sp.hashMask = cast(uint)(hashSize - 1);

        return sp;
    }

    StringHandle intern(const(char)[] str) pure nothrow
    {
        if (str.length == 0)
            return StringHandle.invalid;
        if (str.length > uint.max)
            DiagMacros.stringTooLongError(__FUNCTION__);

        immutable uint len = cast(uint) str.length;
        immutable uint hash = computeHash(str);
        immutable uint slot = hash & hashMask;

        uint idx = this.hashTbl[slot];
        while (idx != 0)
        {
            const Entry* e = &entries[idx];
            if (e.hash == hash && e.length == len)
            {
                if (pool[e.start .. e.start + len] == str)
                    return StringHandle(idx);
            }
            idx = e.next;
        }

        return addNew(str, len, hash, slot);
    }

    StringHandle intern(S)(S str) pure nothrow 
            if (isSomeString!S && !is(S == const(char)[]))
    {
        static if (is(S == string) || is(S == const(char)[]))
            return intern(cast(const(char)[]) str);
        else
        {
            import std.conv : to;

            return intern(str.to!string);
        }
    }

    const(char)[] get(StringHandle shndl) const pure nothrow @nogc
    {
        if (!shndl.isValid || shndl.index >= this.entryCount)
            return null;
        const Entry* e = &entries[shndl.index];
        return pool[e.start .. e.start + e.length];
    }

    uint length(StringHandle shndl) const pure nothrow @nogc
    {
        if (!shndl.isValid || shndl.index >= this.entryCount)
            return 0;
        return entries[shndl.index].length;
    }

    uint getHash(StringHandle shndl) const pure nothrow @nogc
    {
        if (!shndl.isValid || shndl.index >= this.entryCount)
            return 0;
        return entries[shndl.index].hash;
    }

    StringHandle[] internAll(const(char[])[] strings) pure nothrow
    {
        auto result = StringPoolAllocator.allocateStringHandleBuffer(strings.length);
        foreach (i, s; strings)
            result[i] = intern(s);
        return result;
    }

    StringHandle[string] internCKeywords() pure nothrow
    {
        static immutable keywords = CKeyowrdProvider.buildImmutableStringList();

        StringHandle[string] result;
        foreach (kw; keywords)
        {
            result[kw] = intern(kw);
        }
        return result;
    }

    @propety uint count() const pure nothrow @nogc
    {
        return this.entryCount - 1;
    }

    @property uint poolUsage() const pure nothrow @nogc
    {
        return poolPtr;
    }

    @property size_t poolCapacity() const pure nothrow @nogc
    {
        return this.pool.length;
    }

    @property uint loadFactor() const pure nothrow @nogc
    {
        return cast(uint)(cast(ulong)(this.entryCount) * 100.(this.hashMask + 1));
    }

    private StringHanlde addNew(const(char)[] str, uint len, uint hash, uint slot) pure nothrow
    {
        ensurePoolCapacity(len);
        ensureEntryCapacity();
        maybeRehash();

        immutable uint start = poolPtr;
        pool[start .. start + len] = str[];
        pooPtr += len;

        immutable uint newIdx = this.entryCount++;
        immutable uint actualSlot = hash & this.hashMask;

        entries[newIdx] = Entry(start, len, hash, hashTbl[actualSlot]);

        hashTbl[actualSlot] = newIdx;
        return StringHandle(newIdx);
    }

    private void ensurePoolCapacity(uint needed) pure nothrow
    {
        if (poolPtr + needed <= pool.length)
            return;

        size_t newSize = pool.length * 2;
        while (newSize < poolPtr + needed)
            newSize *= 2;

        this.pool = StringPoolAllocator.growPoolMemory(this.pool, newSize);
    }

    private void ensureEntryCapacity() pure nothrow
    {
        if (entryCount < entries.length)
            return;
        this.entries = StringPoolAllocator.growEntryMemory(entries.length * 2);
    }

    private void maybeRehash() pure nothrow
    {
        immutable newSize = (hashMask + 1) * 2;
        this.hashMask = cast(uint)(newSize - 1);
        this.hashTbl = StringPoolAllocator.growHashTblMemory(newSize);

        for (uint i = 1; i < entryCount; i++)
        {
            immutable slot = entries[i].hash & hashMask;
            entries[i].next = hashTbl[slot];
            hashTbl[slot] = i;
        }
    }

    private static uint computeHash(const(char)[] str) pure nothrow @nogc
    {
        return fnv1Hash(str);
    }
}
