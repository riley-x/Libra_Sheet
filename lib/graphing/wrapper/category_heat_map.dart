import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/heatmap/heat_map_hover.dart';
import 'package:libra_sheet/graphing/heatmap/heat_map_painter.dart';
import 'package:provider/provider.dart';

/// Paints a list of [categories] as a heatmap based on their values. This is a StatefulWidget
/// that wraps [HeatMapPainter] to paint either the top-level categories or the nested categories.
/// It also handles tap detection.
///
/// [individualValues] is a map category.key: int_value for each category on its own, while
/// [aggregateValues] aggregates subcat totals into the parent level = 1 categories.
///
/// The latter is used when not [showSubCategories], while for former is needed to show the
/// "un-sub-categorized" leftovers when [showSubCategories].
///
/// P.S. remember this is used to paint level = 1 nested heatmaps too...which doesn't need
/// aggregateValues.
///
/// TODO maybe also better to switch to accepting a single parent instead of [categories].
class CategoryHeatMap extends StatefulWidget {
  final Function(Category)? onSelect;
  final bool showSubCategories;
  final List<Category> categories;
  final Map<int, int> aggregateValues;
  final Map<int, int> individualValues;

  const CategoryHeatMap({
    required this.categories,
    required this.aggregateValues,
    required this.individualValues,
    super.key,
    this.onSelect,
    this.showSubCategories = false,
  });

  @override
  State<CategoryHeatMap> createState() => _CategoryHeatMapState();
}

class _CategoryHeatMapState extends State<CategoryHeatMap> {
  int? hoverLoc;
  HeatMapPainter? painter;

  int _getValue(Category cat, int depth) {
    int? val;
    if (depth == 0) {
      val = widget.aggregateValues[cat.key];
    } else {
      val = widget.individualValues[cat.key];
    }
    return val?.abs() ?? 0;
  }

  List<Category>? _getNested(Category cat, int depth) {
    if (depth == 0 && cat.level == 1 && cat.subCats.isNotEmpty) {
      return List.of(cat.subCats) + [cat];
    } else {
      return null;
    }
  }

  String _labelMapper(Category cat, int depth) {
    String name;
    if (cat.level == 0) {
      name = "Uncategorized";
    } else {
      name = cat.name;
    }
    return "$name\n${_getValue(cat, depth).dollarString()}";
  }

  void _initPainter() {
    final isDarkMode = context.read<LibraAppState>().isDarkMode;
    painter = HeatMapPainter<Category>(
      widget.categories,
      valueMapper: (it, depth) => _getValue(it, depth).asDollarDouble(),
      colorMapper: (it, depth) => (isDarkMode) ? it.color.withAlpha(210) : it.color,
      labelMapper: _labelMapper,
      nestedData: (widget.showSubCategories) ? _getNested : null,
      textStyle: Theme.of(context).textTheme.labelLarge,
      paddingMapper: (depth) => (!widget.showSubCategories)
          ? (2, 2)
          : (depth == 0)
              ? (2, 2)
              : (1, 1),
    );
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
  void didUpdateWidget(CategoryHeatMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showSubCategories != widget.showSubCategories ||
        oldWidget.categories != widget.categories ||
        oldWidget.aggregateValues != widget.aggregateValues ||
        oldWidget.individualValues != widget.individualValues) {
      _initPainter();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (painter == null) return;
    if (widget.onSelect == null) return;
    final res = painter!.hitTestUser(details.localPosition);
    if (res != null) {
      widget.onSelect!(res.$2.item);
    }
  }

  void onHover(PointerHoverEvent event) {
    if (painter == null) return;
    if (painter!.currentSize == Size.zero) return;
    final res = painter!.hitTestUser(event.localPosition);
    final loc = (res?.$2.labelDrawn == true) ? null : res?.$1;
    if (loc == hoverLoc) return;
    setState(() {
      hoverLoc = res?.$1;
    });
  }

  void onExit(PointerExitEvent event) {
    if (hoverLoc == null) return;
    setState(() {
      hoverLoc = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (painter == null) return const SizedBox();
    return MouseRegion(
      onHover: onHover,
      onExit: onExit,
      child: GestureDetector(
        onTapUp: _onTapUp,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: painter,
                // foregroundPainter: ,
                size: Size.infinite,
              ),
            ),
            RepaintBoundary(
              child: HeatMapHover(
                mainGraph: painter!,
                hoverLoc: hoverLoc,
                child: _CategoryHeatMapHover(
                  hoverLoc == null ? null : painter!.positions.elementAtOrNull(hoverLoc!)?.item,
                  labelMapper: (cat) => _labelMapper(cat, widget.showSubCategories ? 1 : 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeatMapHover extends StatelessWidget {
  final Category? category;
  final String Function(Category cat) labelMapper;

  const _CategoryHeatMapHover(this.category, {super.key, required this.labelMapper});

  @override
  Widget build(BuildContext context) {
    if (category == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 3, bottom: 4),
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onInverseSurface.withAlpha(210),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labelMapper(category!),
        style: Theme.of(context).textTheme.labelLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}
