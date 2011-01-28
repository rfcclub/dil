/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module dil.ast.Expressions;

public import dil.ast.Expression;
import dil.ast.Node,
       dil.ast.Types,
       dil.ast.Declarations,
       dil.ast.Statements,
       dil.ast.Parameters,
       dil.ast.NodeCopier;
import dil.lexer.Identifier;
import dil.semantic.Types;
import dil.Float,
       dil.Complex;
import common;

class IllegalExpression : Expression
{
  this()
  {
    mixin(set_kind);
  }
  mixin(copyMethod);
}

/// The base class for every binary operator.
///
/// The copy method is mixed in here, not in any derived class.
/// If a derived class has other nodes than lhs and rhs, then it has
/// to have its own copy method which handles additional nodes.
abstract class BinaryExpression : Expression
{
  Expression lhs; /// Left-hand side expression.
  Expression rhs; /// Right-hand side expression.
  Token* optok;   /// The operator token.

  /// Constructs a BinaryExpression object.
  this(Expression lhs, Expression rhs, Token* optok)
  {
    addChildren([lhs, rhs]);
    this.lhs = lhs;
    this.rhs = rhs;
    this.optok = optok;
  }
  mixin(copyMethodBinaryExpression);
}

class CondExpression : BinaryExpression
{
  Expression condition;
  Token* ctok; // Colon token.
  this(Expression condition, Expression left, Expression right,
       Token* qtok, Token* ctok)
  {
    addChild(condition);
    super(left, right, qtok);
    mixin(set_kind);
    this.condition = condition;
    this.ctok = ctok;
  }
  mixin(copyMethod);
}

class CommaExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class OrOrExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class AndAndExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class OrExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class XorExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class AndExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

/// This class isn't strictly needed, just here for clarity.
abstract class CmpExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
  }
}

class EqualExpression : CmpExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

/// Expression "!"? "is" Expression
class IdentityExpression : CmpExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class RelExpression : CmpExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class InExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class LShiftExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class RShiftExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class URShiftExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class PlusExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class MinusExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class CatExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class MulExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class DivExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class ModExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

// D2
class PowExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

class AssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class LShiftAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class RShiftAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class URShiftAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class OrAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class AndAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class PlusAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class MinusAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class DivAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class MulAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class ModAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class XorAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
class CatAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}
// D2
class PowAssignExpression : BinaryExpression
{
  this(Expression left, Expression right, Token* optok)
  {
    super(left, right, optok);
    mixin(set_kind);
  }
}

/*++++++++++++++++++++
+ Unary Expressions: +
++++++++++++++++++++*/

abstract class UnaryExpression : Expression
{
  Expression una;
  this(Expression e)
  {
    addChild(e);
    this.una = e;
  }
  mixin(copyMethodUnaryExpression);
}

class AddressExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class PreIncrExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class PreDecrExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class PostIncrExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class PostDecrExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class DerefExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class SignExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }

  bool isPos()
  {
    assert(begin !is null);
    return begin.kind == TOK.Plus;
  }

  bool isNeg()
  {
    assert(begin !is null);
    return begin.kind == TOK.Minus;
  }
}

class NotExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class CompExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class CallExpression : UnaryExpression
{
  Expression[] args;
  this(Expression e, Expression[] args)
  {
    super(e);
    mixin(set_kind);
    addOptChildren(args);
    this.args = args;
  }
}

class NewExpression : Expression
{
  Expression frame; /// The frame or 'this' pointer.
  Expression[] newArgs;
  TypeNode type;
  Expression[] ctorArgs;
  this(Expression frame, Expression[] newArgs, TypeNode type,
    Expression[] ctorArgs)
  {
    mixin(set_kind);
    addOptChild(frame);
    addOptChildren(newArgs);
    addChild(type);
    addOptChildren(ctorArgs);
    this.newArgs = newArgs;
    this.type = type;
    this.ctorArgs = ctorArgs;
  }
  mixin(copyMethod);
}

class NewClassExpression : Expression
{
  Expression frame; /// The frame or 'this' pointer.
  Expression[] newArgs;
  BaseClassType[] bases;
  Expression[] ctorArgs;
  CompoundDeclaration decls;
  this(Expression frame, Expression[] newArgs, BaseClassType[] bases,
    Expression[] ctorArgs, CompoundDeclaration decls)
  {
    mixin(set_kind);
    addOptChild(frame);
    addOptChildren(newArgs);
    addOptChildren(bases);
    addOptChildren(ctorArgs);
    addChild(decls);

    this.newArgs = newArgs;
    this.bases = bases;
    this.ctorArgs = ctorArgs;
    this.decls = decls;
  }
  mixin(copyMethod);
}

class DeleteExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class CastExpression : UnaryExpression
{
  TypeNode type;
  this(Expression e, TypeNode type)
  {
    version(D2)
    addOptChild(type);
    else
    addChild(type); // Add type before super().
    super(e);
    mixin(set_kind);
    this.type = type;
  }
  mixin(copyMethod);
}

class IndexExpression : UnaryExpression
{
  Expression[] args;
  this(Expression e, Expression[] args)
  {
    super(e);
    mixin(set_kind);
    addChildren(args);
    this.args = args;
  }
  mixin(copyMethod);
}

class SliceExpression : UnaryExpression
{
  Expression left, right;
  this(Expression e, Expression left, Expression right)
  {
    super(e);
    mixin(set_kind);
    assert(left ? (right !is null) : right is null);
    if (left)
      addChildren([left, right]);

    this.left = left;
    this.right = right;
  }
  mixin(copyMethod);
}

/*++++++++++++++++++++++
+ Primary Expressions: +
++++++++++++++++++++++*/

class IdentifierExpression : Expression
{
  Expression next;
  Identifier* ident;
  this(Identifier* ident, Expression next = null)
  {
    mixin(set_kind);
    addOptChild(next);
    this.next = next;
    this.ident = ident;
  }

  Token* idToken()
  {
    assert(begin !is null);
    return begin;
  }

  mixin(copyMethod);
}

/// Module scope operator:
/// $(BNF ModuleScopeExpression := ".")
class ModuleScopeExpression : Expression
{
  this()
  {
    mixin(set_kind);
  }
  mixin(copyMethod);
}

class TemplateInstanceExpression : Expression
{
  Expression next;
  Identifier* ident;
  TemplateArguments targs;
  this(Identifier* ident, TemplateArguments targs, Expression next = null)
  {
    mixin(set_kind);
    addOptChild(targs);
    addOptChild(next);
    this.next = next;
    this.ident = ident;
    this.targs = targs;
  }

  Token* idToken()
  {
    assert(begin !is null);
    return begin;
  }

  mixin(copyMethod);
}

class SpecialTokenExpression : Expression
{
  Token* specialToken;
  this(Token* specialToken)
  {
    mixin(set_kind);
    this.specialToken = specialToken;
  }

  Expression value; /// The expression created in the semantic phase.

  mixin(copyMethod);
}

class ThisExpression : Expression
{
  this()
  {
    mixin(set_kind);
  }
  mixin(copyMethod);
}

class SuperExpression : Expression
{
  this()
  {
    mixin(set_kind);
  }
  mixin(copyMethod);
}

class NullExpression : Expression
{
  this()
  {
    mixin(set_kind);
  }

  this(Type type)
  {
    this();
    this.type = type;
  }

  mixin(copyMethod);
}

class DollarExpression : Expression
{
  this()
  {
    mixin(set_kind);
  }
  mixin(copyMethod);
}

class BoolExpression : Expression
{
  IntExpression value; /// IntExpression of type bool.

  this(bool value)
  {
    mixin(set_kind);
    // Some semantic computation here.
    this.value = new IntExpression(value, Types.Bool);
    this.type = Types.Bool;
  }

  bool toBool()
  {
    assert(begin !is null);
    return begin.kind == TOK.True ? true : false;
  }

  mixin(copyMethod);
}

class IntExpression : Expression
{
  ulong number;

  this(ulong number, Type type)
  {
    mixin(set_kind);
    this.number = number;
    this.type = type;
  }

  this(Token* token)
  {
    // Some semantic computation here.
    auto type = Types.Int32; // Should be most common case.
    ulong number = token.uint_;
    switch (token.kind)
    {
    // case TOK.Int32:
    //   type = Types.Int32; break;
    case TOK.Uint32:
      type = Types.UInt32; break;
    case TOK.Int64:
      type = Types.Int64;  number = token.intval.ulong_; break;
    case TOK.Uint64:
      type = Types.UInt64; number = token.intval.ulong_; break;
    default:
      assert(token.kind == TOK.Int32);
    }
    this(number, type);
  }

  mixin(copyMethod);
}

class RealExpression : Expression
{
  Float number;

  this(Float number, Type type)
  {
    mixin(set_kind);
    this.number = number;
    this.type = type;
  }

  this(Token* token)
  {
    // Some semantic computation here.
    auto type = Types.fromTOK(token.kind);
    this(token.mpfloat, type);
  }

  mixin(copyMethod);
}


/// This expression holds a complex number.
/// It is only created in the semantic phase.
class ComplexExpression : Expression
{
  Complex number;

  this(Complex number, Type type)
  {
    mixin(set_kind);
    this.number = number;
    this.type = type;
  }

  Float re()
  {
    return number.re;
  }
  Float im()
  {
    return number.im;
  }

  mixin(copyMethod);
}

class CharExpression : Expression
{
  IntExpression value; // IntExpression of type Char/Wchar/Dchar.
//  dchar character; // Replaced by value.
  this(dchar character)
  {
    mixin(set_kind);
//    this.character = character;
    // Some semantic computation here.
    if (character <= 0xFF)
      this.type = Types.Char;
    else if (character <= 0xFFFF)
      this.type = Types.WChar;
    else
      this.type = Types.DChar;

    this.value = new IntExpression(character, this.type);
  }
  mixin(copyMethod);
}

class StringExpression : Expression
{
  ubyte[] str;   /// The string data.
  Type charType; /// The character type of the string.

  this(ubyte[] str, Type charType)
  {
    mixin(set_kind);
    this.str = str;
    this.charType = charType;
    this.type = charType.arrayOf(str.length/charType.sizeOf());
  }

  this(ubyte[] str, char kind)
  {
    Type t = Types.Char;
    if (kind == 'w') t = Types.WChar;
    else if (kind == 'd') t = Types.DChar;
    this(str, t);
  }

  this(char[] str)
  {
    this(cast(ubyte[])str, Types.Char);
  }

  this(wchar[] str)
  {
    this(cast(ubyte[])str, Types.WChar);
  }

  this(dchar[] str)
  {
    this(cast(ubyte[])str, Types.DChar);
  }

  /// Returns the string excluding the terminating 0.
  char[] getString()
  {
    // TODO: convert to char[] if charType !is Types.Char.
    return cast(char[])str[0..$-1];
  }

  mixin(copyMethod);
}

class ArrayLiteralExpression : Expression
{
  Expression[] values;
  this(Expression[] values)
  {
    mixin(set_kind);
    addOptChildren(values);
    this.values = values;
  }
  mixin(copyMethod);
}

class AArrayLiteralExpression : Expression
{
  Expression[] keys, values;
  this(Expression[] keys, Expression[] values)
  {
    assert(keys.length == values.length);
    mixin(set_kind);
    foreach (i, key; keys)
      addChildren([key, values[i]]);
    this.keys = keys;
    this.values = values;
  }
  mixin(copyMethod);
}

class AssertExpression : Expression
{
  Expression expr, msg;
  this(Expression expr, Expression msg)
  {
    mixin(set_kind);
    addChild(expr);
    addOptChild(msg);
    this.expr = expr;
    this.msg = msg;
  }
  mixin(copyMethod);
}

class MixinExpression : Expression
{
  Expression expr;
  this(Expression expr)
  {
    mixin(set_kind);
    addChild(expr);
    this.expr = expr;
  }
  mixin(copyMethod);
}

class ImportExpression : Expression
{
  Expression expr;
  this(Expression expr)
  {
    mixin(set_kind);
    addChild(expr);
    this.expr = expr;
  }
  mixin(copyMethod);
}

class TypeofExpression : Expression
{
  TypeNode type;
  this(TypeNode type)
  {
    mixin(set_kind);
    addChild(type);
    this.type = type;
  }
  mixin(copyMethod);
}

class TypeDotIdExpression : Expression
{
  TypeNode type;
  Identifier* ident;
  this(TypeNode type, Identifier* ident)
  {
    mixin(set_kind);
    addChild(type);
    this.type = type;
    this.ident = ident;
  }
  mixin(copyMethod);
}

class TypeidExpression : Expression
{
  TypeNode type;
  this(TypeNode type)
  {
    mixin(set_kind);
    addChild(type);
    this.type = type;
  }
  mixin(copyMethod);
}

class IsExpression : Expression
{
  TypeNode type;
  Token* ident;
  Token* opTok, specTok;
  TypeNode specType;
  TemplateParameters tparams; // D 2.0
  this(TypeNode type, Token* ident, Token* opTok, Token* specTok,
       TypeNode specType, typeof(tparams) tparams)
  {
    mixin(set_kind);
    addChild(type);
    addOptChild(specType);
  version(D2)
    addOptChild(tparams);
    this.type = type;
    this.ident = ident;
    this.opTok = opTok;
    this.specTok = specTok;
    this.specType = specType;
    this.tparams = tparams;
  }
  mixin(copyMethod);
}

class FunctionLiteralExpression : Expression
{
  TypeNode returnType;
  Parameters params;
  FuncBodyStatement funcBody;

  this()
  {
    mixin(set_kind);
    addOptChild(returnType);
    addOptChild(params);
    addChild(funcBody);
  }

  this(TypeNode returnType, Parameters params, FuncBodyStatement funcBody)
  {
    this.returnType = returnType;
    this.params = params;
    this.funcBody = funcBody;
    this();
  }

  this(FuncBodyStatement funcBody)
  {
    this.funcBody = funcBody;
    this();
  }

  mixin(copyMethod);
}

/// ParenthesisExpression := "(" Expression ")"
class ParenExpression : Expression
{
  Expression next;
  this(Expression next)
  {
    mixin(set_kind);
    addChild(next);
    this.next = next;
  }
  mixin(copyMethod);
}

// version(D2)
// {
class TraitsExpression : Expression
{
  Token* ident;
  TemplateArguments targs;
  this(typeof(ident) ident, typeof(targs) targs)
  {
    mixin(set_kind);
    addOptChild(targs);
    this.ident = ident;
    this.targs = targs;
  }
  mixin(copyMethod);
}
// }

class VoidInitExpression : Expression
{
  this()
  {
    mixin(set_kind);
  }
  mixin(copyMethod);
}

class ArrayInitExpression : Expression
{
  Expression[] keys;
  Expression[] values;
  this(Expression[] keys, Expression[] values)
  {
    assert(keys.length == values.length);
    mixin(set_kind);
    foreach (i, key; keys)
    {
      addOptChild(key); // The key is optional in ArrayInitializers.
      addChild(values[i]);
    }
    this.keys = keys;
    this.values = values;
  }
  mixin(copyMethod);
}

class StructInitExpression : Expression
{
  Token*[] idents;
  Expression[] values;
  this(Token*[] idents, Expression[] values)
  {
    assert(idents.length == values.length);
    mixin(set_kind);
    addOptChildren(values);
    this.idents = idents;
    this.values = values;
  }
  mixin(copyMethod);
}

class AsmTypeExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class AsmOffsetExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class AsmSegExpression : UnaryExpression
{
  this(Expression e)
  {
    super(e);
    mixin(set_kind);
  }
}

class AsmPostBracketExpression : UnaryExpression
{
  Expression index; /// Expression in brackets: una [ index ]
  this(Expression e, Expression index)
  {
    super(e);
    mixin(set_kind);
    addChild(index);
    this.index = index;
  }
  mixin(copyMethod);
}

class AsmBracketExpression : Expression
{
  Expression expr;
  this(Expression e)
  {
    mixin(set_kind);
    addChild(e);
    this.expr = e;
  }
  mixin(copyMethod);
}

class AsmLocalSizeExpression : Expression
{
  this()
  {
    mixin(set_kind);
  }
  mixin(copyMethod);
}

class AsmRegisterExpression : Expression
{
  Identifier* register; /// Name of the register.
  Expression number; /// ST(0) - ST(7) or FS:0, FS:4, FS:8
  this(Identifier* register, Expression number = null)
  {
    mixin(set_kind);
    addOptChild(number);
    this.register = register;
    this.number = number;
  }
  mixin(copyMethod);
}
