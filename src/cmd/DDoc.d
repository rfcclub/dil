/++
  Author: Aziz Köksal
  License: GPL3
+/
module cmd.DDoc;

import cmd.DDocXML;
import cmd.Highlight;
import dil.doc.Parser;
import dil.doc.Macro;
import dil.doc.Doc;
import dil.ast.Node;
import dil.ast.Declarations,
       dil.ast.Statements,
       dil.ast.Expression,
       dil.ast.Parameters,
       dil.ast.Types;
import dil.ast.DefaultVisitor;
import dil.lexer.Token;
import dil.lexer.Funcs;
import dil.semantic.Module;
import dil.semantic.Pass1;
import dil.semantic.Symbol;
import dil.semantic.Symbols;
import dil.Compilation;
import dil.Information;
import dil.Converter;
import dil.SourceText;
import dil.Enums;
import dil.Time;
import common;

import tango.text.Ascii : toUpper;
import tango.io.File;
import tango.io.FilePath;

/// The ddoc command.
struct DDocCommand
{
  string destDirPath; /// Destination directory.
  string[] macroPaths; /// Macro file paths.
  string[] filePaths; /// Module file paths.
  bool includeUndocumented; /// Whether to include undocumented symbols.
  bool writeXML; /// Whether to write XML instead of HTML docs.
  bool verbose; /// Whether to be verbose.

  CompilationContext context;
  InfoManager infoMan;
  TokenHighlighter tokenHL; /// For DDoc code sections.

  /// Executes the doc generation command.
  void run()
  {
    // Parse macro files and build macro table hierarchy.
    MacroTable mtable;
    MacroParser mparser;
    foreach (macroPath; macroPaths)
    {
      auto macros = mparser.parse(loadMacroFile(macroPath, infoMan));
      mtable = new MacroTable(mtable);
      mtable.insert(macros);
    }

    // For DDoc code sections.
    tokenHL = new TokenHighlighter(infoMan, writeXML == false);

    // Process D files.
    foreach (filePath; filePaths)
    {
      auto mod = new Module(filePath, infoMan);
      // Parse the file.
      mod.parse();
      if (mod.hasErrors)
        continue;

      // Start semantic analysis.
      auto pass1 = new SemanticPass1(mod, context);
      pass1.start();

      // Build destination file path.
      auto destPath = new FilePath(destDirPath);
      destPath.append(mod.getFQN() ~ (writeXML ? ".xml" : ".html"));

      if (verbose)
        Stdout.formatln("{} > {}", mod.filePath, destPath);

      // Write the document file.
      writeDocFile(destPath.toString(), mod, mtable);
    }
  }

  void writeDocFile(string destPath, Module mod, MacroTable mtable)
  {
    // Create this module's own macro environment.
    mtable = new MacroTable(mtable);
    // Define runtime macros.
    // MODPATH is an extension by dil.
    mtable.insert("MODPATH", mod.getFQNPath() ~ "." ~ mod.fileExtension());
    mtable.insert("TITLE", mod.getFQN());
    mtable.insert("DOCFILENAME", mod.getFQN() ~ (writeXML ? ".xml" : ".html"));
    auto timeStr = Time.toString();
    mtable.insert("DATETIME", timeStr);
    mtable.insert("YEAR", Time.year(timeStr));

    DDocEmitter docEmitter;
    if (writeXML)
      docEmitter = new DDocXMLEmitter(mod, mtable, includeUndocumented, tokenHL);
    else
      docEmitter = new DDocEmitter(mod, mtable, includeUndocumented, tokenHL);
    docEmitter.emit();

    // Set BODY macro to the text produced by the emitter.
    mtable.insert("BODY", docEmitter.text);
    // Do the macro expansion pass.
    auto fileText = MacroExpander.expand(mtable, "$(DDOC)",
                                         mod.filePath,
                                         verbose ? infoMan : null);
    // fileText ~= "\n<pre>\n" ~ doc.text ~ "\n</pre>";

    // Finally write the file out to the harddisk.
    scope file = new File(destPath);
    file.write(fileText);
  }

  /// Loads a macro file. Converts any Unicode encoding to UTF-8.
  static string loadMacroFile(string filePath, InfoManager infoMan)
  {
    auto src = new SourceText(filePath);
    src.load(infoMan);
    auto text = src.data[0..$-1]; // Exclude '\0'.
    return sanitizeText(text);
  }
}

/// Traverses the syntax tree and writes DDoc macros to a string buffer.
class DDocEmitter : DefaultVisitor
{
  char[] text; /// The buffer that is written to.
  bool includeUndocumented;
  MacroTable mtable;
  Module modul;
  TokenHighlighter tokenHL;

  /// Constructs a DDocEmitter object.
  /// Params:
  ///   modul = the module to generate text for.
  ///   mtable = the macro table.
  ///   includeUndocumented = whether to include undocumented symbols.
  ///   tokenHL = used to highlight code sections.
  this(Module modul, MacroTable mtable, bool includeUndocumented,
       TokenHighlighter tokenHL)
  {
    this.mtable = mtable;
    this.includeUndocumented = includeUndocumented;
    this.modul = modul;
    this.tokenHL = tokenHL;
  }

  /// Entry method.
  char[] emit()
  {
    if (auto d = modul.moduleDecl)
    {
      if (ddoc(d))
      {
        if (auto copyright = cmnt.takeCopyright())
          mtable.insert(new Macro("COPYRIGHT", copyright.text));
        writeComment();
      }
    }
    MEMBERS("MODULE", { visitD(modul.root); });
    return text;
  }

  char[] textSpan(Token* left, Token* right)
  {
    //assert(left && right && (left.end <= right.start || left is right));
    //char[] result;
    //TODO: filter out whitespace tokens.
    return Token.textSpan(left, right);
  }

  TemplateParameters tparams; /// The template parameters of the current declaration.

  DDocComment cmnt; /// Current comment.
  DDocComment prevCmnt; /// Previous comment in scope.
  /// An empty comment. Used for undocumented symbols.
  static const DDocComment emptyCmnt;

  /// Initializes the empty comment.
  static this()
  {
    this.emptyCmnt = new DDocComment(null, null, null);
  }

  /// Keeps track of previous comments in each scope.
  scope class Scope
  {
    DDocComment saved_prevCmnt;
    bool saved_cmntIsDitto;
    uint saved_prevDeclOffset;
    this()
    { // Save the previous comment of the parent scope.
      saved_prevCmnt = this.outer.prevCmnt;
      saved_cmntIsDitto = this.outer.cmntIsDitto;
      saved_prevDeclOffset = this.outer.prevDeclOffset; 
      // Entering a new scope. Clear variables.
      this.outer.prevCmnt = null;
      this.outer.cmntIsDitto = false;
      this.outer.prevDeclOffset = 0;
    }

    ~this()
    { // Restore the previous comment of the parent scope.
      this.outer.prevCmnt = saved_prevCmnt;
      this.outer.cmntIsDitto = saved_cmntIsDitto;
      this.outer.prevDeclOffset = saved_prevDeclOffset;
    }
  }

  bool cmntIsDitto; /// True if current comment is "ditto".

  /// Returns the DDocComment for node.
  DDocComment ddoc(Node node)
  {
    auto c = getDDocComment(node);
    this.cmnt = null;
    if (c)
    {
      if (c.isDitto)
      {
        this.cmnt = this.prevCmnt;
        this.cmntIsDitto = true;
      }
      else
      {
        this.cmntIsDitto = false;
        this.cmnt = c;
        this.prevCmnt = c;
      }
    }
    else if (includeUndocumented)
      this.cmnt = this.emptyCmnt;
    return this.cmnt;
  }

  /// List of predefined, special sections.
  static char[][char[]] specialSections;
  static this()
  {
    foreach (name; ["AUTHORS", "BUGS", "COPYRIGHT", "DATE", "DEPRECATED",
                    "EXAMPLES", "HISTORY", "LICENSE", "RETURNS", "SEE_ALSO",
                    "STANDARDS", "THROWS", "VERSION"])
      specialSections[name] = name;
  }

  /// Writes the DDoc comment to the text buffer.
  void writeComment()
  {
    auto c = this.cmnt;
    assert(c !is null);
    if (c.sections.length == 0)
      return;
    write("$(DDOC_SECTIONS ");
      foreach (s; c.sections)
      {
        if (s is c.summary)
          write("\n$(DDOC_SUMMARY ");
        else if (s is c.description)
          write("\n$(DDOC_DESCRIPTION ");
        else if (auto name = toUpper(s.name.dup) in specialSections)
          write("\n$(DDOC_" ~ *name ~ " ");
        else if (s.Is("params"))
        { // Process parameters section.
          auto ps = new ParamsSection(s.name, s.text);
          write("\n$(DDOC_PARAMS ");
          foreach (i, paramName; ps.paramNames)
            write("\n$(DDOC_PARAM_ROW ",
                    "$(DDOC_PARAM_ID $(DDOC_PARAM ", paramName, "))",
                    "$(DDOC_PARAM_DESC ", ps.paramDescs[i], ")",
                  ")");
          write(")");
          continue;
        }
        else if (s.Is("macros"))
        { // Declare the macros in this section.
          auto ms = new MacrosSection(s.name, s.text);
          mtable.insert(ms.macroNames, ms.macroTexts);
          continue;
        }
        else
          write("\n$(DDOC_SECTION $(DDOC_SECTION_H " ~ s.name ~ ":)");
        write(scanCommentText(s.text), ")");
      }
    write(")");
  }

  /// Scans the comment text and:
  /// $(UL
  /// $(LI skips and leaves macro invocations unchanged)
  /// $(LI skips HTML tags)
  /// $(LI escapes '(', ')', '<', '>' and '&')
  /// $(LI inserts $&#40;DDOC_BLANKLINE&#41; in place of \n\n)
  /// $(LI highlights code in code sections)
  /// )
  char[] scanCommentText(char[] text)
  {
    char* p = text.ptr;
    char* end = p + text.length;
    char[] result = new char[text.length]; // Reserve space.
    result.length = 0;

    while (p < end)
    {
      switch (*p)
      {
      case '$':
        if (auto macroEnd = MacroParser.scanMacro(p, end))
        {
          result ~= makeString(p, macroEnd); // Copy macro invocation as is.
          p = macroEnd;
          continue;
        }
        goto default;
      case '<':
        auto begin = p;
        p++;
        if (p+2 < end && *p == '!' && p[1] == '-' && p[2] == '-') // <!--
        {
          p += 2; // Point to 2nd '-'.
          // Scan to closing "-->".
          while (++p < end)
            if (p+2 < end && *p == '-' && p[1] == '-' && p[2] == '>')
            {
              p += 3; // Point one past '>'.
              break;
            }
          result ~= makeString(begin, p);
        } // <tag ...> or </tag>
        else if (p < end && (isalpha(*p) || *p == '/'))
        {
          while (++p < end && *p != '>') // Skip to closing '>'.
          {}
          if (p == end)
          { // No closing '>' found.
            p = begin + 1;
            result ~= "&lt;";
            continue;
          }
          p++; // Skip '>'.
          result ~= makeString(begin, p);
        }
        else
          result ~= "&lt;";
        continue;
      case '(': result ~= "&#40;"; break;
      case ')': result ~= "&#41;"; break;
      // case '\'': result ~= "&apos;"; break; // &#39;
      // case '"': result ~= "&quot;"; break;
      case '>': result ~= "&gt;"; break;
      case '&':
        if (p+1 < end && (isalpha(p[1]) || p[1] == '#'))
          goto default;
        result ~= "&amp;";
        break;
      case '\n':
        if (!(p+1 < end && p[1] == '\n'))
          goto default;
        ++p;
        result ~= "$(DDOC_BLANKLINE)";
        break;
      case '-':
        if (p+2 < end && p[1] == '-' && p[2] == '-')
        {
          while (p < end && *p == '-')
            p++;
          auto codeBegin = p;
          p--;
          while (++p < end)
            if (p+2 < end && *p == '-' && p[1] == '-' && p[2] == '-')
              break;
          auto codeText = makeString(codeBegin, p);
          result ~= tokenHL.highlight(codeText, modul.filePath);
          while (p < end && *p == '-')
            p++;
          continue;
        }
        //goto default;
      default:
        result ~= *p;
      }
      p++;
    }
    return result;
  }

  /// Escapes '<', '>' and '&' with named HTML entities.
  char[] escape(char[] text)
  {
    char[] result = new char[text.length]; // Reserve space.
    result.length = 0;
    foreach(c; text)
      switch(c)
      {
        case '<': result ~= "&lt;";  break;
        case '>': result ~= "&gt;";  break;
        case '&': result ~= "&amp;"; break;
        default:  result ~= c;
      }
    if (result.length != text.length)
      return result;
    // Nothing escaped. Return original text.
    delete result;
    return text;
  }

  /// Writes an array of strings to the text buffer.
  void write(char[][] strings...)
  {
    foreach (s; strings)
      text ~= s;
  }

  /// Writes params to the text buffer.
  void writeParams(Parameters params)
  {
    if (!params.items.length)
      return write("()");
    write("(");
    auto lastParam = params.items[$-1];
    foreach (param; params.items)
    {
      if (param.isCVariadic)
        write("...");
      else
      {
        assert(param.type);
        // Write storage classes.
        auto typeBegin = param.type.baseType.begin;
        if (typeBegin !is param.begin) // Write storage classes.
          write(textSpan(param.begin, typeBegin.prevNWS), " ");
        write(escape(textSpan(typeBegin, param.type.end))); // Write type.
        if (param.name)
          write(" $(DDOC_PARAM ", param.name.str, ")");
        if (param.isDVariadic)
          write("...");
        if (param.defValue)
          write(" = ", escape(textSpan(param.defValue.begin, param.defValue.end)));
      }
      if (param !is lastParam)
        write(", ");
    }
    write(")");
  }

  /// Writes the current template parameters to the text buffer.
  void writeTemplateParams()
  {
    if (!tparams)
      return;
    write(escape(textSpan(tparams.begin, tparams.end)));
    tparams = null;
  }

  /// Writes bases to the text buffer.
  void writeInheritanceList(BaseClassType[] bases)
  {
    if (bases.length == 0)
      return;
    auto basesBegin = bases[0].begin.prevNWS;
    if (basesBegin.kind == TOK.Colon)
      basesBegin = bases[0].begin;
    write(" : ", escape(textSpan(basesBegin, bases[$-1].end)));
  }

  /// Writes a symbol to the text buffer. E.g: $&#40;SYMBOL Buffer, 123&#41;
  void SYMBOL(char[] name, Declaration d)
  {
    auto loc = d.begin.getRealLocation();
    auto str = Format("$(SYMBOL {}, {})", name, loc.lineNum);
    write(str);
    // write("$(DDOC_PSYMBOL ", name, ")");
  }

  /// Offset at which to insert a declaration which have a "ditto" comment.
  uint prevDeclOffset;

  /// Writes a declaration to the text buffer.
  void DECL(void delegate() dg, Declaration d, bool writeSemicolon = true)
  {
    if (cmntIsDitto)
    { alias prevDeclOffset offs;
      assert(offs != 0);
      auto savedText = text;
      text = "";
      write("\n$(DDOC_DECL ");
      dg();
      writeSemicolon && write(";");
      writeAttributes(d);
      write(")");
      // Insert text at offset.
      auto len = text.length;
      text = savedText[0..offs] ~ text ~ savedText[offs..$];
      offs += len; // Add length of the inserted text to the offset.
      return;
    }
    write("\n$(DDOC_DECL ");
    dg();
    writeSemicolon && write(";");
    writeAttributes(d);
    write(")");
    prevDeclOffset = text.length;
  }

  /// Wraps the DDOC_DECL_DD macro around the text written by dg().
  void DESC(void delegate() dg)
  {
    if (cmntIsDitto)
      return;
    write("\n$(DDOC_DECL_DD ");
    dg();
    write(")");
  }

  /// Wraps the DDOC_kind_MEMBERS macro around the text written by dg().
  void MEMBERS(char[] kind, void delegate() dg)
  {
    write("\n$(DDOC_"~kind~"_MEMBERS ");
    dg();
    write(")");
  }

  /// Writes a class or interface declaration.
  void writeClassOrInterface(T)(T d)
  {
    if (!ddoc(d))
      return d;
    DECL({
      write(d.begin.srcText, " ");
      SYMBOL(d.name.str, d);
      writeTemplateParams();
      writeInheritanceList(d.bases);
    }, d);
    DESC({
      writeComment();
      MEMBERS(is(T == ClassDeclaration) ? "CLASS" : "INTERFACE", {
        scope s = new Scope();
        d.decls && super.visit(d.decls);
      });
    });
  }

  // templated decls are not virtual so we need these:

  /// Writes a class declaration.
  void writeClass(ClassDeclaration d) {
    writeClassOrInterface(d);
  }

  /// Writes an interface declaration.
  void writeInterface(InterfaceDeclaration d) {
    writeClassOrInterface(d);
  }

  /// Writes a struct or union declaration.
  void writeStructOrUnion(T)(T d)
  {
    if (!ddoc(d))
      return d;
    DECL({
      write(d.begin.srcText, d.name ? " " : "");
      if (d.name)
        SYMBOL(d.name.str, d);
      writeTemplateParams();
    }, d);
    DESC({
      writeComment();
      MEMBERS(is(T == StructDeclaration) ? "STRUCT" : "UNION", {
        scope s = new Scope();
        d.decls && super.visit(d.decls);
      });
    });
  }

  // templated decls are not virtual so we need these:

  /// Writes a struct declaration.
  void writeStruct(StructDeclaration d) {
    writeStructOrUnion(d);
  }

  /// Writes a union declaration.
  void writeUnion(UnionDeclaration d) {
    writeStructOrUnion(d);
  }

  /// Writes an alias or typedef declaration.
  void writeAliasOrTypedef(T)(T d)
  {
    auto prefix = is(T == AliasDeclaration) ? "alias " : "typedef ";
    if (auto vd = d.decl.Is!(VariablesDeclaration))
    {
      auto type = textSpan(vd.typeNode.baseType.begin, vd.typeNode.end);
      foreach (name; vd.names)
        DECL({ write(prefix); write(escape(type), " "); SYMBOL(name.str, d); }, d);
    }
    else if (auto fd = d.decl.Is!(FunctionDeclaration))
    {}
    // DECL({ write(textSpan(d.begin, d.end)); }, false);
    DESC({ writeComment(); });
  }

  /// Writes the attributes of a declaration in brackets.
  void writeAttributes(Declaration d)
  {
    char[][] attributes;

    if (d.prot != Protection.None)
      attributes ~= "$(PROT " ~ .toString(d.prot) ~ ")";

    auto stc = d.stc;
    stc &= ~StorageClass.Auto; // Ignore auto.
    foreach (stcStr; .toStrings(stc))
      attributes ~= "$(STC " ~ stcStr ~ ")";

    LinkageType ltype;
    if (auto vd = d.Is!(VariablesDeclaration))
      ltype = vd.linkageType;
    else if (auto fd = d.Is!(FunctionDeclaration))
      ltype = fd.linkageType;

    if (ltype != LinkageType.None)
      attributes ~= "$(LINKAGE extern(" ~ .toString(ltype) ~ "))";

    if (!attributes.length)
      return;

    write(" $(ATTRIBUTES ");
    write(attributes[0]);
    foreach (attribute; attributes[1..$])
      write(", ", attribute);
    write(")");
  }

  alias Declaration D;

override:
  D visit(AliasDeclaration d)
  {
    if (!ddoc(d))
      return d;
    writeAliasOrTypedef(d);
    return d;
  }

  D visit(TypedefDeclaration d)
  {
    if (!ddoc(d))
      return d;
    writeAliasOrTypedef(d);
    return d;
  }

  D visit(EnumDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({
      write("enum", d.name ? " " : "");
      d.name && SYMBOL(d.name.str, d);
    }, d);
    DESC({
      writeComment();
      MEMBERS("ENUM", { scope s = new Scope(); super.visit(d); });
    });
    return d;
  }

  D visit(EnumMemberDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL(d.name.str, d); }, d, false);
    DESC({ writeComment(); });
    return d;
  }

  D visit(TemplateDeclaration d)
  {
    this.tparams = d.tparams;
    if (d.begin.kind != TOK.Template)
    { // This is a templatized class/interface/struct/union/function.
      super.visit(d.decls);
      this.tparams = null;
      return d;
    }
    if (!ddoc(d))
      return d;
    DECL({
      write("template ");
      SYMBOL(d.name.str, d);
      writeTemplateParams();
    }, d);
    DESC({
      writeComment();
      MEMBERS("TEMPLATE", {
        scope s = new Scope();
        super.visit(d.decls);
      });
    });
    return d;
  }

  D visit(ClassDeclaration d)
  {
    writeClass(d);
    return d;
  }

  D visit(InterfaceDeclaration d)
  {
    writeInterface(d);
    return d;
  }

  D visit(StructDeclaration d)
  {
    writeStruct(d);
    return d;
  }

  D visit(UnionDeclaration d)
  {
    writeUnion(d);
    return d;
  }

  D visit(ConstructorDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("this", d); writeParams(d.params); }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(StaticConstructorDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({ write("static "); SYMBOL("this", d); write("()"); }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(DestructorDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({ write("~"); SYMBOL("this", d); write("()"); }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(StaticDestructorDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({ write("static ~"); SYMBOL("this", d); write("()"); }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(FunctionDeclaration d)
  {
    if (!ddoc(d))
      return d;
    auto type = textSpan(d.returnType.baseType.begin, d.returnType.end);
    DECL({
      write(escape(type), " ");
      SYMBOL(d.name.str, d);
      writeTemplateParams();
      writeParams(d.params);
    }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(NewDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("new", d); writeParams(d.params); }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(DeleteDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("delete", d); writeParams(d.params); }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(VariablesDeclaration d)
  {
    if (!ddoc(d))
      return d;
    char[] type = "auto";
    if (d.typeNode)
      type = textSpan(d.typeNode.baseType.begin, d.typeNode.end);
    foreach (name; d.names)
      DECL({ write(escape(type), " "); SYMBOL(name.str, d); }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(InvariantDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("invariant", d); }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(UnittestDeclaration d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("unittest", d); }, d);
    DESC({ writeComment(); });
    return d;
  }

  D visit(DebugDeclaration d)
  {
    d.compiledDecls && visitD(d.compiledDecls);
    return d;
  }

  D visit(VersionDeclaration d)
  {
    d.compiledDecls && visitD(d.compiledDecls);
    return d;
  }

  D visit(StaticIfDeclaration d)
  {
    d.ifDecls && visitD(d.ifDecls);
    return d;
  }
}