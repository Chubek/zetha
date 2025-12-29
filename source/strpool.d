module zetha.strpool;

import zetha.arena : getInternAllocator;
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

string StringPool
{

}

