/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module dil.Information;

import dil.i18n.Messages;
import common;

public import dil.Location;

/// Information that can be displayed to the user.
class Information
{

}

/// For reporting a problem in the compilation process.
class Problem : Information
{
  Location location;
  uint column; /// Cache variable for column.
  cstring message;

  this(Location location, cstring message)
  {
    assert(location !is null);
    this.location = location;
    this.message = message;
  }

  /// Returns the message.
  cstring getMsg()
  {
    return this.message;
  }

  /// Returns the line of code.
  size_t loc()
  {
    return location.lineNum;
  }

  /// Returns the column.
  size_t col()
  {
    if (column == 0)
      column = location.calculateColumn();
    return column;
  }

  /// Returns the file path.
  cstring filePath()
  {
    return location.filePath;
  }
}

/// For DDoc reports.
class DDocProblem : Problem
{
  /// Enumeration of problems.
  enum Kind
  {
    UndocumentedSymbol, /// Undocumented symbol.
    EmptyComment,       /// Empty DDoc comment.
    NoParamsSection,    /// No params section for function parameters.
    UndocumentedParam   /// An undocumented function parameter.
  }
  Kind kind; /// The kind of problem.
  /// Constructs a DDocProblem object.
  this(Location location, Kind kind, cstring message)
  {
    super(location, message);
    this.kind = kind;
  }
}

/// For reporting warnings.
class Warning : Problem
{
  /// Constructs a Warning object.
  this(Location location, cstring message)
  {
    super(location, message);
  }
}

/// For reporting a compiler error.
class GeneralError : Problem
{
  this(Location location, cstring message)
  {
    super(location, message);
  }
}

/// An error reported by the Lexer.
class LexerError : GeneralError
{
  this(Location location, cstring message)
  {
    super(location, message);
  }
}

/// An error reported by the Parser.
class ParserError : GeneralError
{
  this(Location location, cstring message)
  {
    super(location, message);
  }
}

/// An error reported by a semantic analyzer.
class SemanticError : GeneralError
{
  this(Location location, cstring message)
  {
    super(location, message);
  }
}
