#! /usr/bin/rdmd
/++
  Author: Aziz Köksal
  License: GPL3
+/
module TypeRulesGenerator;

import tango.io.File;
import tango.io.FilePath;
import common;

alias char[] string;

void main(char[][] args)
{
  char[] text = "/// Generated by TypeRulesGenerator.d\n"
                "module TypeRulesData;\n\n";
  text ~= Format(`const char[] compilerNameVersion = "{} {}.{,:d3}";`\n\n,
                 __VENDOR__, __VERSION__/1000, __VERSION__%1000);
  text ~= "char[][][] unaryExpsResults = [\n";
  foreach (results; unaryExpsResults)
  {
    text ~= "  [";
    foreach (result; results)
      text ~= '"' ~ result ~ `", `;
    text.length = text.length - 2;
    text ~= "],\n";
  }
  text.length = text.length - 2;
  text ~= "\n];\n\n";

  text ~= "char[][][][] binaryExpsResults = [\n";
  foreach (expResults; binaryExpsResults)
  {
    text ~= "  [\n";
    foreach (results; expResults)
    {
      text ~= "    [";
      foreach (result; results)
        text ~= '"' ~ result ~ `", `;
      text.length = text.length - 2;
      text ~= "],\n";
    }
    text.length = text.length - 2;
    text ~= "\n  ],\n";
  }
  text.length = text.length - 2;
  text ~= "\n];\n";

  // Write the text to a D module.
  auto file = new File("TypeRulesData.d");
  file.write(text);
}

template ExpressionType(alias x, alias y, char[] expression)
{
  static if(is(typeof(mixin(expression)) ResultType))
    const char[] result = ResultType.stringof;
  else
    const char[] result = "Error";
}
alias ExpressionType EType;

// pragma(msg, EType!("char", "int", "&x").result);

static const string[] basicTypes = [
  "char"[],   "wchar",   "dchar", "bool",
  "byte",   "ubyte",   "short", "ushort",
  "int",    "uint",    "long",  "ulong",
  /+"cent",   "ucent",+/
  "float",  "double",  "real",
  "ifloat", "idouble", "ireal",
  "cfloat", "cdouble", "creal"/+, "void"+/
];

char char_; wchar wchar_; dchar dchar_; bool bool_;
byte byte_; ubyte ubyte_; short short_; ushort ushort_;
int int_; uint uint_; long long_; ulong ulong_;
/+cent cent_;   ucent ucent_;+/
float float_; double double_; real real_;
ifloat ifloat_; idouble idouble_; ireal ireal_;
cfloat cfloat_; cdouble cdouble_; creal creal_;

static const string[] unaryExpressions = [
  "!x",
  "&x",
  "~x",
  "+x",
  "-x",
  "++x",
  "--x",
  "x++",
  "x--",
];

static const string[] binaryExpressions = [
  "x!<>=y",
  "x!<>y",
  "x!<=y",
  "x!<y",
  "x!>=y",
  "x!>y",
  "x<>=y",
  "x<>y",

  "x=y", "x==y", "x!=y",
  "x<=y", "x<y",
  "x>=y", "x>y",
  "x<<=y", "x<<y",
  "x>>=y","x>>y",
  "x>>>=y", "x>>>y",
  "x|=y", "x||y", "x|y",
  "x&=y", "x&&y", "x&y",
  "x+=y", "x+y",
  "x-=y", "x-y",
  "x/=y", "x/y",
  "x*=y", "x*y",
  "x%=y", "x%y",
  "x^=y", "x^y",
  "x~=y",
  "x~y",
  "x,y"
];

char[] genBinaryExpArray(char[] expression)
{
  char[] result = "[\n";
  foreach (t1; basicTypes)
  {
    result ~= "[\n";
    foreach (t2; basicTypes)
      result ~= `EType!(`~t1~`_, `~t2~`_, "`~expression~`").result,`\n;
    result[result.length-2] = ']'; // Overwrite last comma.
    result[result.length-1] = ','; // Overwrite last \n.
  }
  result[result.length-1] = ']'; // Overwrite last comma.
  return result;
}
// pragma(msg, mixin(genBinaryExpArray("x%y")).stringof);

char[] genBinaryExpsArray()
{
  char[] result = "[\n";
  foreach (expression; binaryExpressions)
  {
    result ~= genBinaryExpArray(expression);
    result ~= ",\n";
  }
  result[result.length-2] = ']';
  return result;
}

// pragma(msg, mixin(genBinaryExpsArray()).stringof);

char[] genUnaryExpArray(char[] expression)
{
  char[] result = "[\n";
  foreach (t1; basicTypes)
    result ~= `EType!(`~t1~`_, int_, "`~expression~`").result,`\n;
  result[result.length-2] = ']'; // Overwrite last comma.
  return result;
}

char[] genUnaryExpsArray()
{
  char[] result = "[\n";
  foreach (expression; unaryExpressions)
    result ~= genUnaryExpArray(expression) ~ ",\n";
  result[result.length-2] = ']';
  return result;
}

// pragma(msg, mixin(genUnaryExpsArray()).stringof);

auto unaryExpsResults = mixin(genUnaryExpsArray());
auto binaryExpsResults = mixin(genBinaryExpsArray());
