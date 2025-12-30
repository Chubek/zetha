module zetha.diag;

import zetha.strpool;
import zetha.source;

import std.array : appender, Appender;
import std.format : format;
import std.range : empty;

enum Severity
{
    Note,
    Warning,
    Error,
    Fatal,
}

string severityToString(Severity sev) pure nothrow @nogc @safe
{
    final switch (sev)
    {
    case Severity.Note:
        return "Note";
    case Severity.Warning:
        return "Warning";
    case Severity.Error:
        return "Error";
    case Severity.Fatal:
        return "Fatal";
    }
}

string severityColor(Severity sev) pure nothrow @nogc @safe
{
    final switch (sev)
    {
    case Severity.Note:
        return "\\033[36m";
    case Severity.Warning:
        return "\\033[35m";
    case Severity.Error:
        return "\\033[31m";
    case Severity.Fatal:
        return "\\033[31;1m";
    }
}

enum DiagCode : ushort
{
    UnterminatedString = 1001,
    UnterminatedCharLiteral,
    UnderminatedComment,
    InvalidCharacter,
    InvalidEscapeSequence,
    EmptyCharLiteral,
    MultiCharLiteral,
    InvalidNumericLiteral,
    NumericOverflow,
    InvalidOctalDigit,
    InvalidHexDigit,
    InvalidSuffix,
    StrayBackslash,
    NullInSource,

    ExpectedToken = 2001,
    ExpectedExpression,
    ExpectedStatement,
    ExpectedDeclaration,
    ExpectedTypename,
    ExpectedIdentifier,
    UnexpectedToken,
    UnexpectedEOF,
    MismatchedParen,
    MismathedBracket,
    MismatchedBrace,
    InvalidDeclrator,
    InvalidTypeSpecifier,
    DuplicateStorageClass,
    DuplicateTypeQualiifer,
    InvalidArraySize,
    InvalidParameterList,
    InvalidInitializer,
    TooManyErrors,

    UndeclaredIdentifier = 3001,
    RedefinedIdentifier,
    TypeMismatch,
    IncompatibleTypes,
    InvalidOperands,
    InvalidLValue,
    InvalidConversion,
    InvalidCast,
    IncompleteType,
    VoidValue,
    InvalidArraySubscript,
    InvalidFunctionCall,
    WrongArgumentCount,
    InvalidMemberAcces,
    InvalidIndirection,
    InvalidAddressOf,
    ConstAssignment,
    UninitializedVariable,
    UnusedVariable,
    UnusedParameter,
    UnreachableCode,
    MissingReturn,
    InvalidBreak,
    InvalidContinue,
    DuplicateCase,
    DuplicateDefault,
    InvalidSwitchType,
    DivisionByZero,
    ShiftOverflow,
    ImplicitConversion,
    SignCompare,
    ShadowVariable,
    InvalidSizeof,
    FlexibleArrayMember,
    BitfieldWidth,

    UnsupportedFeature = 4001,
    TargetLimitation,
    InlineAsmError,
    AlignmentError,
    StackOverflow,

    FileNotFound = 5001,
    FileReadError,
    FileWRiteError,
    InvalidOption,
    InternalError,

    Unknown = 0,

}
