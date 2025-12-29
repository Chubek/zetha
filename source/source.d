module zetha.source;

import zetha.strtbl : StringHandle;
import std.typecons : Nullable;

struct SourcePos
{
    uint offset;

    enum SourcePos invalid = SourcePos(uint.max);

    @property bool isValid() const pure nothrow @nogc @safe
    {
        return this.offset != uint.max;
    }

    SourcePos opBinary(string op : "+")(uint n) const pure nothrow @nogc @safe
    {
        if (!this.isValid)
            return invalid;
        return SourcePos(offset + n);
    }

    int opBinary(string op : "-")(SourcePos other) const pure nothrow @nogc @safe
    {
        return cast(int) this.offset - cast(int) other.offset;
    }

    int opCmp(SourcePos other) const pure nothrow @nogc @safe
    {
        if (this.offset < other.offset)
            return -1;
        if (this.offset > other.offset)
            return 1;
        return 0;
    }
}
