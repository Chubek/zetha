module zetha.infra.abstyy;

import std.traits : isCallable, ReturnType;

struct Stream(T)
{
    private T[] _buffer;
    private size_t _pos;
    private T delegate() _generatorFn;
    private bool _isGeneratorBased;
    private bool _exhausted;

    this(T[] data)
    {
        this._buffer = data;
        this._pos = 0;
        this._isGeneratorBased = false;
        this._exhaused = false;
    }

    this(T delegate() genFn)
    {
        this._generatorFn = genFn;
        this._isGeneratorBased = true;
        this._exhausted = false;
    }

    @property bool empty() const pure @safe @trusted
    {
        if (this._isGeneratorBased)
            return this._exhausted;
        return this._pos >= this._buffer.length;
    }

    @property T front() @safe @trusted
    {
        if (this._isGeneratorBased)
        {
            if (this._buffer.length <= this._pos)
            {
                auto val = this.generatorFn();
                this.buffer ~= val;
            }
            return this._buffer[this._pos];
        }
        return this._buffer[this._pos];
    }

    void popFront()
    {
        this._pos++;
    }

    T get()
    {
        T val = this.front;
        this.popFront();
        return val;
    }

    T[] take(size_t n)
    {
        T[] result;
        result.reserve(n);
        foreach (_; 0 .. n)
        {
            if (this.empty)
                break;
            result ~= this.get();
        }
        return result;
    }

    void skip(size_t n)
    {
        foreach (_; 0 .. n)
        {
            if (this.empty)
                break;
            this.popFront();
        }
    }

    void reset()
    {
        this._pos = 0;
        this._exhausted = false;
    }

    @property size_t pos() const pure
    {
        return this._pos;
    }

    size_t save() const pure
    {
        return this._pos;
    }

    void restore(size_t savedPos)
    {
        this._pos = savedPos;
    }

    void markExhausted()
    {
        this._exhausted = true;
    }

    auto map(U, alias allocFn)(U delegate(T) mapFn)
    {
        U[] result = allocFn(this._buffer.length);
        foreach (elt; this._buffer)
            result ~= mapFn(elt);
        return result;
    }

    auto filter(alias allocFn)(bool delegate(T) predFn)
    {
        T[] result = allocFn(this._buffer.length);
        foreach (elt; this._buffer)
            if (predFn(elt))
                result ~= elt;
        return result;
    }

    int opApply(scope int delegate(T) dg)
    {
        while (!this.empty)
            if (auto result = dg(this.get()))
                return result;
        return 0;
    }

    int opApply(scope int delegate(size_t, T) dg)
    {
        size_t index = 0;
        while (!this.empty)
            if (auto result = dg(index++, get()))
                return result;
        return 0;
    }
}
