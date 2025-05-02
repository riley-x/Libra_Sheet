import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/sankey/sankey_node.dart';
import 'package:libra_sheet/graphing/sankey/sankey_painter.dart';

class TieredSankeyPlot extends StatefulWidget {
  final List<List<SankeyNode>> nodes;
  final String? Function(double value)? valueToString;

  const TieredSankeyPlot({super.key, required this.nodes, this.valueToString});

  @override
  State<TieredSankeyPlot> createState() => _TieredSankeyPlotState();
}

class _TieredSankeyPlotState extends State<TieredSankeyPlot> {
  SankeyPainter? painter;

  void _calculateNodes() {}

  void _initPainter() {
    painter = SankeyPainter(
      theme: Theme.of(context),
      data: widget.nodes,
      valueToString: widget.valueToString,
    );
  }

  @override
  void initState() {
    super.initState();
    _calculateNodes();
  }

  // Need to init here and not [initState] because we access Theme.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initPainter();
  }

  // This is necessary to update the state when the parent rebuilds.
  // https://stackoverflow.com/questions/54759920/flutter-why-is-child-widgets-initstate-is-not-called-on-every-rebuild-of-pa
  @override
  void didUpdateWidget(TieredSankeyPlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateNodes();
    _initPainter();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: painter,
        size: Size.infinite,
      ),
    );
  }
}
