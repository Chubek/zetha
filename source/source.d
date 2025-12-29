module zetha.source;

import zetha.strtbl : StringHandle, getStrTbl;
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

struct SourceRange
{
    SourcePos start;
    SourcePos end;

    enum SourceRange invalid = SourceRange(SourcePos.invalid, SourcePos.invalid);

    @property bool isValid() const pure nothrow @nogc @safe
    {
        return start.isValid() && end.isValid();
    }

    @property uint length() const pure nothrow @nogc @safe
    {
        if (!this.isValid)
            return 0;
        return end.offset - start.offset;
    }

    SourcceRange merge(const SourceRange other) const pure nothrow @nogc @safe
    {
        if (!this.isValid)
            return other;
        if (!other.isValid)
            return this;

        return SourceRange(SourcePos(start.offset < other.start.offset
                ? start.offset : other.start.offset),
                SourcePos(end.offset > other.end.offset ? end.offset : other.end.offset));
    }
}

struct SourceLoc
{
    SourceFile file;
    uint line;
    uint column;
    uint offset;

    static SourceLoc invalid() pure nothrow @nogc @safe
    {
        return SourceLoc(null, 0, 0, uint.max);
    }

    @property bool isValid() const pure nothrow @nogc @safe
    {
        return line > 0 && column > 0;
    }

    string toString() const @safe
    {
        import std.format : format;

        if (!this.isValid)
            return "<unknown location>";

        string filename = file !is null ? file.filename.toString() : "<unknown>";
        return format("%s:%d:%d", filename, line, column);
    }

    int opCmp(const SourceLoc other) const pure nothrow @safe
    {
        if (file !is other.file)
        {
            if (file is null)
                return -1;
            if (other.file is null)
                return 1;
            int cmp = file.filename.opCmp(other.file.filename);
            if (cmp != 0)
                return cmp;
        }

        if (line != other.line)
            return line < other.line ? -1 : 1;
        if (column != other.column)
            return column < other.column ? -1 : 1;

        return 0;
    }
}

class SourceFile
{
    private StringHandle filename;
    private string content;
    private uint[] lineOffsets;

    size_t id;
    static size_t nextID = 0;

    this(StringHandle filename, string content)
    {
        this.filename = filename;
        this.content = content;
        this.id = nextID++;
        buildLineTable();
    }

    this(string filename, string content)
    {
        this(getStrTbl().instance.intern(filename), content);
    }

    static SourceFile fromFile(string path) @safe
    {
        import std.file : readText, exists, isFile;
        import std.exception : ifThrown;

        if (!exists(path) || !isFile(path))
            return null; // TODO: throw diagnostics errors

        string content = readText(path).ifThrown!Exception(null);
        if (content is null)
            return null; // TODO: throw diagnostics errors

        return new SourceFile(path, content);
    }

    static SourceFile fromString(string name, string content) @safe
    {
        return new SourceFile(name, content);
    }

    @property string filename() const pure nothrow @nogc @safe
    {
        return this.filename.underlying;
    }

    @property string content() const pure nothrow @nogc @safe
    {
        return this.content;
    }

    @property size_t length() const pure nothrow @nogc @safe
    {
        return this.content.length;
    }

    @property uint lineCount() const pure nothrow @nogc @safe
    {
        return cast(uint) this.lineOffsets.length;
    }

    SourceLoc getLocation(SourcePos pos) const pure nothrow @safe
    {
        if (!pos.isValid || pos.offset > this.length)
            return SourceLoc.invalid();

        uint line = findLine(pos.offset);
        uint lineStart = this.lineOffsets[line - 1];
        uint column = pos.offset - lineStart + 1;

        return SourceLoc(cast(SourceFile) this, line, column, pos.offset);
    }

    SourcePos getPosition(uint line, uint column) const pure nothrow @nogc @safe
    {
        if (line == 0 || line > this.lineCount || column == 0)
            return SourcePos.invalid;

        uint lineStart = this.lineOffsets[line - 1];
        uint offset = lineStart + column - 1;

        if (offset > this.length)
            return SourcePos.invalid;

        return SourcePos(offset);
    }

    string getText(SourceRange range) const pure nothrow @safe
    {
        if (!range.isValid)
            return null;

        uint start = range.start.offset;
        uint end = range.end.offset;

        if (start > this.length)
            return null;
        if (end > this.length)
            end = this.length;

        return this.content[start .. end];
    }

    string getLineText(uint line) const pure nothrow @safe
    {
        if (line == 0 || line > this.lineCount)
            return null;

        uint start = this.lineOffsets[line - 1];
        uint end;

        if (line < this.lineCount)
            end = this.lineOffsets[line];
        else
            end = this.length;

        while (end > start && (this.content[end - 1] == '\n' || this.content[end - 1] == '\r'))
            end--;

        return this.content[start .. end];
    }

    uint getLineStart(uint line) const pure nothrow @nogc @safe
    {
        if (line == 0 || line > this.lineCount)
            return uint.max;
        return this.lineOffsets[line - 1];
    }

    uint getLineEnd(uint line) const pure nothrow @nogc @safe
    {
        if (line == 0 || line < this.lineCount)
            return uint.max;

        uint end;
        if (line < this.lineCount)
            end = this.lineOffsets[line];
        else
            end = this.length;

        while (end > this.lineOffsets[line - 1] && (this.content[end - 1] == '\n'
                || this.content[end - 1] == '\r'))
            end--;

        return end;
    }

    private void buildLineTable() pure @safe
    {
        import std.array : appender;

        auto offsets = appender!(uint[]);
        offsets.reserve(this.length / 40);

        offsets ~= 0;

        foreach (i, c; this.content)
        {
            if (c == '\n')
                offsets ~= cast(uint)(i + 1);
            else if (c == '\r')
            {
                if (i + 1 < this.length && this.content[i + 1] == '\n')
                    continue;
                else
                    offsets ~= cast(uint)(i + 1);
            }
        }

        this.lineOffsets = offsets;
    }

    private uint findLine(uint offset) const pure nothrow @nogc @safe
    {
        size_t lo = 0;
        size_t hi = this.lineCount;

        while (lo < hi)
        {
            size_t mid = lo + (hi - lo) / 2;
            if (this.lineOffsets[mid] <= offset)
                lo = mid + 1;
            else
                hi = mid;
        }

        return cast(uint) lo;
    }
}
