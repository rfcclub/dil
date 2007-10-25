/**
 * Author: Aziz Köksal & Jari-Matti Mäkelä
 * License: GPL3
 */
module docgen.graphutils.dotwriter;
import docgen.graphutils.writer;

import tango.io.Print: Print;
import tango.text.convert.Layout : Layout;
import tango.io.FilePath;
import tango.text.Util;

/**
 * Creates a graph rule file for the dot utility.
 */
class DotWriter : AbstractGraphWriter {
  this(GraphWriterFactory factory, DocumentWriter writer) {
    super(factory, writer);
  }

  void generateDepGraph(Vertex[] vertices, Edge[] edges, OutputStream imageFile) {
    auto image = new Print!(char)(new Layout!(char), imageFile);

    Vertex[][char[]] verticesByPckgName;
    if (factory.options.graph.groupByFullPackageName ||
        factory.options.graph.groupByPackageNames) {
      foreach (mod; vertices) {
        auto parts = mod.name.delimit(".");

        if (parts.length>1) {
          auto pkg = parts[0..$-1].join(".");
          verticesByPckgName[pkg] ~= mod;
        }
      }
    }

    if (factory.options.graph.highlightCyclicVertices ||
        factory.options.graph.highlightCyclicEdges)
      findCycles(vertices, edges);

    // name of the .dot file
    char[] fn = (cast(Object)imageFile.conduit).toUtf8();
    fn = FilePath(fn).file;

    fn = fn[0..$-3] ~ imageFormatExts[factory.options.graph.imageFormat];
    
    writer.addGraphics(fn);
    
    image("Digraph ModuleDependencies {\n");

    foreach (module_; vertices) {
      auto nodeName = 
        factory.options.graph.groupByPackageNames ?
        module_.name.split(".")[$-1] :
        module_.name;

      image.format(
        `  n{0} [label="{1}"{2}];`\n,
        module_.id,
        nodeName,
        (module_.isCyclic && factory.options.graph.highlightCyclicVertices ?
          ",style=filled,fillcolor=" ~ factory.options.graph.nodeColor :
          (module_.type == VertexType.UnlocatableModule ?
            ",style=filled,fillcolor=" ~ factory.options.graph.unlocatableNodeColor :
            ""
          )
        )
      );
    }

    foreach (edge; edges)
      image.format(
        `  n{0} -> n{1}{2};`\n,
        edge.outgoing.id,
        edge.incoming.id,
        (edge.isCyclic ? "[color=" ~ factory.options.graph.cyclicNodeColor ~ "]" : "")
      );

    if (factory.options.graph.groupByPackageNames)

      if (!factory.options.graph.groupByFullPackageName) {
        foreach (packageName, vertices; verticesByPckgName) {
          auto name = packageName.split(".");

          if (name.length > 1) {
            char[] pkg;
            foreach(part; name) {
              pkg ~= part ~ ".";
              image.format(
                `subgraph "cluster_{0}" {{`\n`  label="{0}"`\n,
                pkg[0..$-1],
                pkg[0..$-1]
              );
            }
            for (int i=0; i< name.length; i++) {
              image("}\n");
            }
          }
        }
      }
      foreach (packageName, vertices; verticesByPckgName) {
        image.format(
          `  subgraph "cluster_{0}" {{`\n`  label="{0}";color=`
          ~ factory.options.graph.clusterColor ~ `;`\n`  `,
          packageName,
          packageName
        );

        foreach (module_; vertices)
          image.format(`n{0};`, module_.id);
        image("\n  }\n");
      }

    image("}");
  }
}
