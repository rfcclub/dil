/++
  Author: Aziz Köksal
  License: GPL3
+/
module main;

import dil.parser.Parser;
import dil.lexer.Lexer,
       dil.lexer.Token;
import dil.ast.Declarations,
       dil.ast.Expressions,
       dil.ast.Node,
       dil.ast.Visitor;
import dil.semantic.Module;
import dil.semantic.Symbols;
import dil.semantic.Pass1,
       dil.semantic.Pass2,
       dil.semantic.Interpreter;
import dil.translator.German;
import dil.doc.Doc;
import dil.Messages;
import dil.CompilerInfo;
import dil.Information;
import dil.SourceText;
import dil.Compilation;

import cmd.Highlight;
import cmd.Statistics;
import cmd.ImportGraph;
import cmd.DDoc;

import Settings;
import SettingsLoader;
// import TypeRules;
import common;

import Integer = tango.text.convert.Integer;
import tango.stdc.stdio;
import tango.io.File;
import tango.text.Util;
import tango.time.StopWatch;
import tango.text.Ascii : icompare;

/// Entry function of dil.
void main(char[][] args)
{
  auto infoMan = new InfoManager();
  SettingsLoader.SettingsLoader(infoMan).load();
  if (infoMan.hasInfo)
    return printErrors(infoMan);

  if (args.length <= 1)
    return Stdout(helpMain()).newline;

  string command = args[1];
  switch (command)
  {
  case "c", "compile":
    if (args.length < 2)
      return printHelp("compile");

    string[] filePaths;
    auto context = newCompilationContext();
    foreach (arg; args[2..$])
    {
      if (parseDebugOrVersion(arg, context))
      {}
      else
        filePaths ~= arg;
    }

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

      void printSymbolTable(ScopeSymbol scopeSym, char[] indent)
      {
        foreach (member; scopeSym.members)
        {
          auto tokens = getDocTokens(member.node);
          char[] docText;
          foreach (token; tokens)
            docText ~= token.srcText;
          Stdout(indent).formatln("Id:{}, Symbol:{}, DocText:{}", member.name.str, member.classinfo.name, docText);
          if (auto s = cast(ScopeSymbol)member)
            printSymbolTable(s, indent ~ "→ ");
        }
      }

      printSymbolTable(mod, "");
    }

    infoMan.hasInfo && printErrors(infoMan);
    break;
  case "ddoc", "d":
    if (args.length < 4)
      return printHelp("ddoc");

    DDocCommand cmd;
    cmd.destDirPath = args[2];
    cmd.macroPaths = GlobalSettings.ddocFilePaths;
    cmd.context = newCompilationContext();
    cmd.infoMan = infoMan;

    // Parse arguments.
    foreach (arg; args[3..$])
    {
      if (parseDebugOrVersion(arg, cmd.context))
      {}
      else if (arg == "--xml")
        cmd.writeXML = true;
      else if (arg == "-i")
        cmd.includeUndocumented = true;
      else if (arg == "-v")
        cmd.verbose = true;
      else if (arg.length > 5 && icompare(arg[$-4..$], "ddoc") == 0)
        cmd.macroPaths ~= arg;
      else
        cmd.filePaths ~= arg;
    }
    cmd.run();
    infoMan.hasInfo && printErrors(infoMan);
    break;
  case "hl", "highlight":
    if (args.length < 3)
      return printHelp("hl");

    HighlightCommand cmd;
    cmd.infoMan = infoMan;

    foreach (arg; args[2..$])
    {
      switch (arg)
      {
      case "--syntax":
        cmd.add(HighlightCommand.Option.Syntax); break;
      case "--xml":
        cmd.add(HighlightCommand.Option.XML); break;
      case "--html":
        cmd.add(HighlightCommand.Option.HTML); break;
      case "--lines":
        cmd.add(HighlightCommand.Option.PrintLines); break;
      default:
        cmd.filePath = arg;
      }
    }
    cmd.run();
    infoMan.hasInfo && printErrors(infoMan);
    break;
  case "importgraph", "igraph":
    string filePath;
    string[] regexps;
    string siStyle = "dashed"; // static import style
    string piStyle = "bold";   // public import style
    uint levels;
    IGraphOption options;
    auto context = newCompilationContext();
    foreach (arg; args[2..$])
    {
      if (parseDebugOrVersion(arg, context))
      {}
      else if (strbeg(arg, "-I"))
        context.importPaths ~= arg[2..$];
      else if(strbeg(arg, "-r"))
        regexps ~= arg[2..$];
      else if(strbeg(arg, "-l"))
        levels = Integer.toInt(arg[2..$]);
      else if(strbeg(arg, "-si"))
        siStyle = arg[3..$];
      else if(strbeg(arg, "-pi"))
        piStyle = arg[3..$];
      else
        switch (arg)
        {
        case "--dot":
          options |= IGraphOption.PrintDot; break;
        case "--paths":
          options |= IGraphOption.PrintPaths; break;
        case "--list":
          options |= IGraphOption.PrintList; break;
        case "-i":
          options |= IGraphOption.IncludeUnlocatableModules; break;
        case "-hle":
          options |= IGraphOption.HighlightCyclicEdges; break;
        case "-hlv":
          options |= IGraphOption.HighlightCyclicVertices; break;
        case "-gbp":
          options |= IGraphOption.GroupByPackageNames; break;
        case "-gbf":
          options |= IGraphOption.GroupByFullPackageName; break;
        case "-m":
          options |= IGraphOption.MarkCyclicModules; break;
        default:
          filePath = arg;
        }
    }
    cmd.ImportGraph.execute(filePath, context, regexps, levels, siStyle, piStyle, options);
    break;
  case "stats", "statistics":
    char[][] filePaths;
    bool printTokensTable;
    bool printNodesTable;
    foreach (arg; args[2..$])
      if (arg == "--toktable")
        printTokensTable = true;
      else if (arg == "--asttable")
        printNodesTable = true;
      else
        filePaths ~= arg;
    cmd.Statistics.execute(filePaths, printTokensTable, printNodesTable);
    break;
  case "tok", "tokenize":
    SourceText sourceText;
    char[] filePath;
    char[] separator;
    bool ignoreWSToks;
    bool printWS;

    foreach (arg; args[2..$])
    {
      if (strbeg(arg, "-s"))
        separator = arg[2..$];
      else if (arg == "-")
        sourceText = new SourceText("stdin", readStdin());
      else if (arg == "-i")
        ignoreWSToks = true;
      else if (arg == "-ws")
        printWS = true;
      else
        filePath = arg;
    }

    separator || (separator = "\n");
    if (!sourceText)
      sourceText = new SourceText(filePath, true);

    infoMan = new InfoManager();
    auto lx = new Lexer(sourceText, infoMan);
    lx.scanAll();
    auto token = lx.firstToken();

    for (; token.kind != TOK.EOF; token = token.next)
    {
      if (token.kind == TOK.Newline || ignoreWSToks && token.isWhitespace)
        continue;
      if (printWS && token.ws)
        Stdout(token.wsChars);
      Stdout(token.srcText)(separator);
    }

    infoMan.hasInfo && printErrors(infoMan);
    break;
  case "trans", "translate":
    if (args.length < 3)
      return printHelp("trans");

    if (args[2] != "German")
      return Stdout.formatln("Error: unrecognized target language \"{}\"", args[2]);

    infoMan = new InfoManager();
    auto filePath = args[3];
    auto mod = new Module(filePath, infoMan);
    // Parse the file.
    mod.parse();
    if (!mod.hasErrors)
    { // Translate
      auto german = new GermanTranslator(Stdout, "  ");
      german.translate(mod.root);
    }
    printErrors(infoMan);
    break;
  case "profile":
    if (args.length < 3)
      break;
    char[][] filePaths;
    if (args[2] == "dstress")
    {
      auto text = cast(char[])(new File("dstress_files")).read();
      filePaths = split(text, "\0");
    }
    else
      filePaths = args[2..$];

    StopWatch swatch;
    swatch.start;

    foreach (filePath; filePaths)
      (new Lexer(new SourceText(filePath, true))).scanAll();

    Stdout.formatln("Scanned in {:f10}s.", swatch.stop);
    break;
  // case "parse":
  //   if (args.length == 3)
  //     parse(args[2]);
  //   break;
  case "?", "help":
    printHelp(args.length >= 3 ? args[2] : "");
    break;
  // case "typerules":
  //   genHTMLTypeRulesTables();
  //   break;
  default:
  }
}

char[] readStdin()
{
  char[] text;
  while (1)
  {
    auto c = getc(stdin);
    if (c == EOF)
      break;
    text ~= c;
  }
  return text;
}

/// Available commands.
const char[] COMMANDS =
  "  compile (c)\n"
  "  ddoc (d)\n"
  "  help (?)\n"
  "  highlight (hl)\n"
  "  importgraph (igraph)\n"
  "  statistics (stats)\n"
  "  tokenize (tok)\n"
  "  translate (trans)\n";

bool strbeg(char[] str, char[] begin)
{
  if (str.length >= begin.length)
  {
    if (str[0 .. begin.length] == begin)
      return true;
  }
  return false;
}

/// Creates the global compilation context.
CompilationContext newCompilationContext()
{
  auto cc = new CompilationContext;
  cc.importPaths = GlobalSettings.importPaths;
  cc.addVersionId("dil");
  cc.addVersionId("all");
version(D2)
  cc.addVersionId("D_Version2");
  foreach (versionId; GlobalSettings.versionIds)
    if (!Lexer.isReservedIdentifier(versionId))
      cc.versionIds[versionId] = true;
  return cc;
}

bool parseDebugOrVersion(string arg, CompilationContext context)
{
  if (strbeg(arg, "-debug"))
  {
    if (arg.length > 7)
    {
      auto val = arg[7..$];
      if (isdigit(val[0]))
        context.debugLevel = Integer.toInt(val);
      else if (!Lexer.isReservedIdentifier(val))
        context.addDebugId(val);
    }
    else
      context.debugLevel = 1;
  }
  else if (arg.length > 9 && strbeg(arg, "-version="))
  {
    auto val = arg[9..$];
    if (isdigit(val[0]))
      context.versionLevel = Integer.toInt(val);
    else if (!Lexer.isReservedIdentifier(val))
      context.addVersionId(val);
  }
  else
    return false;
  return true;
}

/// Prints the errors collected in infoMan.
void printErrors(InfoManager infoMan)
{
  foreach (info; infoMan.info)
  {
    char[] errorFormat;
    if (info.classinfo is LexerError.classinfo)
      errorFormat = GlobalSettings.lexerErrorFormat;
    else if (info.classinfo is ParserError.classinfo)
      errorFormat = GlobalSettings.parserErrorFormat;
    else if (info.classinfo is SemanticError.classinfo)
      errorFormat = GlobalSettings.semanticErrorFormat;
    else if (info.classinfo is Warning.classinfo)
      errorFormat = "{0}: Warning: {3}";
    else
      continue;
    auto err = cast(Problem)info;
    Stderr.formatln(errorFormat, err.filePath, err.loc, err.col, err.getMsg);
  }
}

/// Prints the compiler's main help message.
char[] helpMain()
{
  auto COMPILED_WITH = __VENDOR__;
  auto COMPILED_VERSION = Format("{}.{,:d3}", __VERSION__/1000, __VERSION__%1000);
  auto COMPILED_DATE = __TIMESTAMP__;
  return FormatMsg(MID.HelpMain, VERSION, COMMANDS, COMPILED_WITH,
                   COMPILED_VERSION, COMPILED_DATE);
}

/// Prints a help message for command.
void printHelp(char[] command)
{
  char[] msg;
  switch (command)
  {
  case "c", "compile":
    msg = `Compile D source files.
Usage:
  dil compile file.d [file2.d, ...] [Options]

  This command only parses the source files and does little semantic analysis.
  Errors are printed to standard error output.

Options:
  -debug           : include debug code
  -debug=level     : include debug(l) code where l <= level
  -debug=ident     : include debug(ident) code
  -version=level   : include version(l) code where l >= level
  -version=ident   : include version(ident) code

Example:
  dil c src/main.d`;
    break;
  case "ddoc", "d":
    msg = `Generate documentation from DDoc comments in D source files.
Usage:
  dil ddoc Destination file.d [file2.d, ...] [Options]

  Destination is the folder where the documentation files are written to.
  Files with the extension .ddoc are recognized as macro definition files.

Options:
  --xml            : write XML instead of HTML documents
  -i               : include undocumented symbols
  -v               : verbose output

Example:
  dil d doc/ src/main.d src/macros_dil.ddoc -i`;
    break;
  case "hl", "highlight":
//     msg = GetMsg(MID.HelpGenerate);
    msg = `Highlight a D source file with XML or HTML tags.
Usage:
  dil hl file.d [Options]

Options:
  --syntax         : generate tags for the syntax tree
  --xml            : use XML format (default)
  --html           : use HTML format
  --lines          : print line numbers

Example:
  dil hl Parser.d --html --syntax > Parser.html`;
    break;
  case "importgraph", "igraph":
//     msg = GetMsg(MID.HelpImportGraph);
    msg = `Parse a module and build a module dependency graph based on its imports.
Usage:
  dil igraph file.d Format [Options]

  The directory of file.d is implicitly added to the list of import paths.

Format:
  --dot            : generate a dot document (default)
  Options related to --dot:
  -gbp             : Group modules by package names
  -gbf             : Group modules by full package name
  -hle             : highlight cyclic edges in the graph
  -hlv             : highlight modules in cyclic relationships
  -siSTYLE         : the edge style to use for static imports
  -piSTYLE         : the edge style to use for public imports
  STYLE can be: "dashed", "dotted", "solid", "invis" or "bold"

  --paths          : print the file paths of the modules in the graph

  --list           : print the names of the module in the graph
  Options common to --paths and --list:
  -lN              : print N levels.
  -m               : use '*' to mark modules in cyclic relationships

Options:
  -Ipath           : add 'path' to the list of import paths where modules are
                     looked for
  -rREGEXP         : exclude modules whose names match the regular expression
                     REGEXP
  -i               : include unlocatable modules

Example:
  dil igraph src/main.d --list
  dil igraph src/main.d | dot -Tpng > main.png`;
    break;
  case "tok", "tokenize":
    msg = `Print the tokens of a D source file.
Usage:
  dil tok file.d [Options]

Options:
  -               : reads text from the standard input.
  -sSEPARATOR     : print SEPARATOR instead of newline between tokens.
  -i              : ignore whitespace tokens (e.g. comments, shebang etc.)
  -ws             : print a token's preceding whitespace characters.

Example:
  echo "module foo; void func(){}" | dil tok -
  dil tok main.d | grep ^[0-9]`;
    break;
  case "stats", "statistics":
    msg = "Gather statistics about D source files.
Usage:
  dil stat file.d [file2.d, ...] [Options]

Options:
  --toktable      : print the count of all kinds of tokens in a table.
  --asttable      : print the count of all kinds of nodes in a table.

Example:
  dil stat src/dil/Parser.d src/dil/Lexer.d";
    break;
  case "trans", "translate":
    msg = `Translate a D source file to another language.
Usage:
  dil translate Language file.d

  Languages that are supported:
    *) German

Example:
  dil trans German src/main.d`;
    break;
  default:
    msg = helpMain();
  }
  Stdout(msg).newline;
}

/+void parse(string fileName)
{
  auto mod = new Module(fileName);
  mod.parse();

  void print(Node[] decls, char[] indent)
  {
    foreach(decl; decls)
    {
      assert(decl !is null);
      Stdout.formatln("{}{}: begin={} end={}", indent, decl.classinfo.name, decl.begin ? decl.begin.srcText : "\33[31mnull\33[0m", decl.end ? decl.end.srcText : "\33[31mnull\33[0m");
      print(decl.children, indent ~ "  ");
    }
  }
  print(mod.root.children, "");
}+/