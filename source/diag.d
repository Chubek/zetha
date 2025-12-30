module zetha.diag;

import zetha.strpool : StringHandle;
import zetha.source : SourceLoc, SourceSpan;

import std.array : appender, Appender;
import std.format : format;
import std.span : empty;

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

Severity defaultSeverity(DiagCode code) pure nothrow @nogc @safe
{
    final switch (code)
    {
    case DiagCode.MultiCharLiteral:
    case DiagCode.ImplicitConversion:
    case DiagCode.SignCompare:
    case DiagCode.UnusedVariable:
    case DiagCode.UnusedParameter:
    case DiagCode.ShadowedVariable:
    case DiagCode.UninitializedVariable:
        return Severity.Warning;

    case DiagCode.InternalError:
    case DiagCode.TooManyErrors:
        return Severity.Fatal;

    default:
        return Severity.Error;
    }
}

string diagTemplate(DiagCode code) pure nothrow @nogc @safe
{
    final switch (code)
    {
    case DiagCode.UnterminatedString:
        return "unterminated string literal";
    case DiagCode.UnterminatedCharLiteral:
        return "unterminated character literal";
    case DiagCode.UnterminatedComment:
        return "unterminated /* comment";
    case DiagCode.InvalidCharacter:
        return "invalid character '%s' (0x%02X)";
    case DiagCode.InvalidEscapeSequence:
        return "invalid escape sequence '\\%s'";
    case DiagCode.EmptyCharLiteral:
        return "empty character literal";
    case DiagCode.MultiCharLiteral:
        return "multi-character character literal";
    case DiagCode.InvalidNumericLiteral:
        return "invalid numeric literal";
    case DiagCode.NumericOverflow:
        return "numeric literal too large";
    case DiagCode.InvalidOctalDigit:
        return "invalid digit '%s' in octal literal";
    case DiagCode.InvalidHexDigit:
        return "invalid digit '%s' in hexadecimal literal";
    case DiagCode.InvalidSuffix:
        return "invalid suffix '%s' on %s literal";
    case DiagCode.StrayBackslash:
        return "stray '\\' in program";
    case DiagCode.NulInSource:
        return "null character in source file";

        // Parser
    case DiagCode.ExpectedToken:
        return "expected '%s'";
    case DiagCode.ExpectedExpression:
        return "expected expression";
    case DiagCode.ExpectedStatement:
        return "expected statement";
    case DiagCode.ExpectedDeclaration:
        return "expected declaration";
    case DiagCode.ExpectedTypeName:
        return "expected type name";
    case DiagCode.ExpectedIdentifier:
        return "expected identifier";
    case DiagCode.UnexpectedToken:
        return "unexpected token '%s'";
    case DiagCode.UnexpectedEOF:
        return "unexpected end of file";
    case DiagCode.MismatchedParen:
        return "mismatched parentheses";
    case DiagCode.MismatchedBracket:
        return "mismatched brackets";
    case DiagCode.MismatchedBrace:
        return "mismatched braces";
    case DiagCode.InvalidDeclarator:
        return "invalid declarator";
    case DiagCode.InvalidTypeSpecifier:
        return "invalid type specifier combination";
    case DiagCode.DuplicateStorageClass:
        return "duplicate storage class specifier";
    case DiagCode.DuplicateTypeQualifier:
        return "duplicate type qualifier";
    case DiagCode.InvalidArraySize:
        return "array size must be a positive integer";
    case DiagCode.InvalidParameterList:
        return "invalid parameter list";
    case DiagCode.InvalidInitializer:
        return "invalid initializer";
    case DiagCode.TooManyErrors:
        return "too many errors, stopping compilation";

    case DiagCode.UndeclaredIdentifier:
        return "undeclared identifier '%s'";
    case DiagCode.RedefinedIdentifier:
        return "redefinition of '%s'";
    case DiagCode.TypeMismatch:
        return "type mismatch: expected '%s', got '%s'";
    case DiagCode.IncompatibleTypes:
        return "incompatible types in %s";
    case DiagCode.InvalidOperands:
        return "invalid operands to %s ('%s' and '%s')";
    case DiagCode.InvalidLvalue:
        return "expression is not assignable";
    case DiagCode.InvalidConversion:
        return "cannot convert '%s' to '%s'";
    case DiagCode.InvalidCast:
        return "invalid cast from '%s' to '%s'";
    case DiagCode.IncompleteType:
        return "incomplete type '%s'";
    case DiagCode.VoidValue:
        return "void value not ignored as it ought to be";
    case DiagCode.InvalidArraySubscript:
        return "subscripted value is not an array or pointer";
    case DiagCode.InvalidFunctionCall:
        return "called object is not a function";
    case DiagCode.WrongArgumentCount:
        return "function expects %d arguments, got %d";
    case DiagCode.InvalidMemberAccess:
        return "member access on non-struct/union type";
    case DiagCode.InvalidIndirection:
        return "indirection requires pointer operand";
    case DiagCode.InvalidAddressOf:
        return "cannot take address of %s";
    case DiagCode.ConstAssignment:
        return "assignment to const variable";
    case DiagCode.UninitializedVariable:
        return "variable '%s' may be used uninitialized";
    case DiagCode.UnusedVariable:
        return "unused variable '%s'";
    case DiagCode.UnusedParameter:
        return "unused parameter '%s'";
    case DiagCode.UnreachableCode:
        return "unreachable code";
    case DiagCode.MissingReturn:
        return "non-void function does not return a value";
    case DiagCode.InvalidBreak:
        return "'break' statement not in loop or switch";
    case DiagCode.InvalidContinue:
        return "'continue' statement not in loop";
    case DiagCode.DuplicateCase:
        return "duplicate case value '%s'";
    case DiagCode.DuplicateDefault:
        return "multiple default labels in switch";
    case DiagCode.InvalidSwitchType:
        return "switch expression must have integer type";
    case DiagCode.DivisionByZero:
        return "division by zero";
    case DiagCode.ShiftOverflow:
        return "shift amount exceeds type width";
    case DiagCode.ImplicitConversion:
        return "implicit conversion from '%s' to '%s'";
    case DiagCode.SignCompare:
        return "comparison between signed and unsigned";
    case DiagCode.ShadowedVariable:
        return "declaration shadows variable '%s'";
    case DiagCode.InvalidSizeof:
        return "invalid application of 'sizeof' to %s";
    case DiagCode.FlexibleArrayMember:
        return "flexible array member not at end of struct";
    case DiagCode.BitfieldWidth:
        return "bit-field width exceeds type width";

    case DiagCode.UnsupportedFeature:
        return "unsupported feature: %s";
    case DiagCode.TargetLimitation:
        return "target limitation: %s";
    case DiagCode.InlineAsmError:
        return "inline assembly error: %s";
    case DiagCode.AlignmentError:
        return "alignment error: %s";
    case DiagCode.StackOverflow:
        return "stack frame too large";

    case DiagCode.FileNotFound:
        return "file not found: '%s'";
    case DiagCode.FileReadError:
        return "cannot read file: '%s'";
    case DiagCode.FileWriteError:
        return "cannot write file: '%s'";
    case DiagCode.InvalidOption:
        return "invalid option: '%s'";
    case DiagCode.InternalError:
        return "internal compiler error: %s";

    default:
        return "unknown error";
    }
}

struct Diagnostic
{
    Severity severity;
    DiagCode code;
    SourceLoc location;
    SourceSpan span;
    string message;
    Diagnostic[] notes;

    string toString() const @safe
    {
        auto result = appender!string;
        formatTo(result, false);
        return result[];
    }

    string toColorString() const @safe
    {
        auto result = appender!string;
        formatTo(result, true);
        return result[];
    }

    private void formatTo(ref Out output, bool useColor) const @safe
    {
        enum REST = "\\033[0m";
        enum BOLD = "\\033[1m";
        enum WHITE = "\\033[37;1m";

        if (location.isValid)
        {
            if (useColor)
                output ~= BOLD;
            output ~= location.toString();
            output ~= "; ";
            if (useColor)
                output ~= RESET;
        }

        if (useColor)
        {
            output ~= BOLD;
            output ~= severityColor(this.severity);
        }
        output ~= severityToString(this.severity);
        output ~= "; ";
        if (useColor)
            output ~= RESET;

        if (useColor)
            output ~= WHITE;
        output ~= this.message;
        if (useColor)
            output ~= RESET;
        output ~= '\n';

        if (location.isValid && location.file !is null)
        {
            auto ctx = location.file.getContext(location, 0);
            if (ctx.isValid)
            {
                if (useColor)
                    output ~= ctx.toColorString();
                else
                    output ~= ctx.toString();

            }

        }

        foreach (note; notes)
            note.formatTo(output, useColor);
    }

    ref Diagnostic addNote(SourceLoc loc, string msg) return @safe
    {
        this.notes ~= Diagnostic(Severity.Note, DiagCode.Unknown, loc,
                SourceSpan.invalid, msg, null);
        return this;
    }

    ref Diagnostic addNote(string msg) return @safe
    {
        return addNote(SourceLoc.invalid(), msg);
    }

}
