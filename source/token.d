module zetha.token;

import zetha.strtbl : StringHandle;
import zetha.source : SourceLoc, SourceRange;

enum TokenKind : ubyte
{
    INVALID,
    EOF,

    IDENTIFIER,
    INT_LITERAL,
    REAL_LITERAL,
    CHAR_LITERAL,
    STRING_LITERAL,

    KW_AUTO,
    KW_BREAK,
    KW_CASE,
    KW_CHAR,
    KW_CONST,
    KW_CONTINUE,
    KW_DEFAULT,
    KW_DO,
    KW_DOUBLE,
    KW_ELSE,
    KW_ENUM,
    KW_EXTERN,
    KW_FLOAT,
    KW_FOR,
    KW_GOTO,
    KW_IF,
    KW_INT,
    KW_LONG,
    KW_REGISTER,
    KW_RETURN,
    KW_SHORT,
    KW_SIGNED,
    KW_SIZEOF,
    KW_STATIC,
    KW_STRUCT,
    KW_SWITCH,
    KW_TYPEDEF,
    KW_UNION,
    KW_UNSIGNED,
    KW_VOID,
    KW_VOLATILE,
    KW_WHILE,

    LPAREN,
    RPAREN,
    LBRACK,
    BBRACK,
    LCURLY,
    RCURLY,

    SEMICOLON,
    COMMA,
    COLON,
    QMARK,
    TILDE,
    DOT,

    PLUS,
    MINUS,
    STAR,
    SLASH,
    PERCENT,
    AMPR,
    PIPE,
    CARET,
    BANG,
    ASSIGN,
    LESS,
    GREATER,

    PLUS_PLUS,
    MINUS_MINUS,
    ARROW,
    LESS_LESS,
    GREATER_GREATER,
    LESS_EQUAL,
    GREATER_EQUAL,
    EQUAL_EQUAL,
    BANG_EQUAL,
    AMPR_AMPR,
    PIPE_PIPE,

    PLUS_ASSIGN,
    MINUS_ASSIGN,
    STAR_ASSIGN,
    SLASH_ASSIGN,
    PERCENT_ASSIGN,
    AMPR_ASSIGN,
    AMPR_AMPR_ASSIGN,
    PIPE_ASSIGN,
    PIPE_PIPE_ASSIGN,
    CARET_ASSIGN,
    LESS_LESS_ASSIGN,
    GREATER_GREATER_ASSIGN,
    ELLIPSES,

}

bool isKeyword(TokenKind kind) pure nothrow @nogc @safe
{
    return kind >= TokenKind.KW_AUTO && kind <= TokenKind.While;
}

bool isTypeSpecifier(TokenKind kind) pure nothrow @nogc @safe
{
    final switch (kind)
    {
    case TokenKind.VOID:
    case TokenKind.CHAR:
    case TokenKind.SHORT:
    case TokenKind.INT:
    case TokenKind.LONG:
    case TokenKind.FLOAT:
    case TokenKind.DOUBLE:
    case TokenKind.SIGNED:
    case TokenKind.UNSIGNED:
    case TokenKind.STRUCT:
    case TokenKind.UNION:
    case TokenKind.ENUM:
        return true;
    default:
        return false;
    }
}

bool isStorageClass(TokenKind kind) pure nothrow @nogc @safe
{
    final switch (kind)
    {
    case TokenKind.AUTO:
    case TokenKind.REGISTER:
    case TokenKind.STATIC:
    case TokenKind.EXTERN:
    case TokenKind.TYPEDEF:
        return true;
    default:
        return false;
    }
}

bool isAssignmentOp(TokenKind kind) pure nothrow @nogc @safe
{
    final switch (kind)
    {
    case TokenKind.ASSIGN:
    case TokenKind.PLUS_ASSIGN:
    case TokenKind.MINUS_ASSIGN:
    case TokenKind.STAR_ASSIGN:
    case TokenKind.SLASH_ASSIGN:
    case TokenKind.PERCENT_ASSIGN:
    case TokenKind.AMPR_ASSIGN:
    case TokenKind.AMPR_AMPR_ASSIGN:
    case TokenKind.PIPE_ASSIGN:
    case TokenKind.PIPE_PIPE_ASSIGN:
    case TokenKind.CARET_ASSIGN:
    case TokenKind.LESS_LESS_ASSIGN:
    case TokenKind.GREATER_GREATER_ASSIGN:
        return true;
    default:
        return false;
    }
}

bool isUnaryOp(TokenKind kind) pure nothrow @nogc @safe
{
    final switch (kind)
    {
    case TokenKind.AMPR:
    case TokenKind.STAR:
    case TokenKind.PLUS:
    case TokenKind.MINUS:
    case TokenKind.BANG:
    case TokenKind.PLUS_PLUS:
    case TokenKind.MINUS_MINUS:
    case TokenKind.SIZEOF:
        return true;
    default:
        return false;
    }
}

enum IntSuffix : ubyte
{
    NONE,
    U,
    L,
    LL,
    UL,
    ULL,
}

enum RealSuffix : ubyte
{
    NONE,
    F,
    L,
    LD,
}

struct Token
{
    TokenKind kind;
    SourceLoc loc;
    SourceRange range;
    StringHandle lexeme;

    union
    {
        string strValue;
        ulong intValue;
        real realValue;
        char charValue;
    }

    union
    {
        IntSuffix intSuffix;
        RealSuffix realSuffix;
	bool wideChar;
    }

    @property isValid() const pure nothrow @nogc @safe
    {
        return this.kind != TokenKind.INVALID;
    }

    @property isEOF() const pure nothrow @nogc @safe
    {
        return this.kind != TokenKind.EOF;
    }
}

public immutable TokenKind[string] gKeywordsTable;

shared static this()
{
    gKeywordsTable = [
        "auto": TokenKind.KW_AUTO,
        "break": TokenKind.KW_BREAK,
        "case": TokenKind.KW_CASE,
        "char": TokenKind.KW_CHAR,
        "const": TokenKind.KW_CONST,
        "continue": TokenKind.KW_CONTINUE,
        "default": TokenKind.KW_DEFAULT,
        "do": TokenKind.KW_DO,
        "double": TokenKind.KW_DOUBLE,
        "else": TokenKind.KW_ELSE,
        "enum": TokenKind.KW_ENUM,
        "extern": TokenKind.KW_EXTERN,
        "float": TokenKind.KW_FLOAT,
        "for": TokenKind.KW_FOR,
        "goto": TokenKind.KW_GOTO,
        "if": TokenKind.KW_IF,
        "int": TokenKind.KW_INT,
        "long": TokenKind.KW_LONG,
        "register": TokenKind.KW_REGISTER,
        "return": TokenKind.KW_RETURN,
        "short": TokenKind.KW_SHORT,
        "signed": TokenKind.KW_SIGNED,
        "sizeof": TokenKind.KW_SIZEOF,
        "static": TokenKind.KW_STATIC,
        "struct": TokenKind.KW_STRUCT,
        "switch": TokenKind.KW_SWITCH,
        "typedef": TokenKind.KW_TYPEDEF,
        "union": TokenKind.KW_UNION,
        "unsigned": TokenKind.KW_UNSIGNED,
        "void": TokenKind.KW_VOID,
        "volatile": TokenKind.KW_VOLATILE,
        "while": TokenKind.KW_WHILE,
    ];
}
