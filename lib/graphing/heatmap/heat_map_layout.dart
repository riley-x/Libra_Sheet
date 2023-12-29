import 'dart:math';
import 'dart:ui';

class _Score {
  final List<int> groups;
  int get nGroups => groups.length - 1;

  /// The sum of the min ratio in each group (smallest/largest entry).
  final double sumMinRatio;

  double get averageMinRatio => sumMinRatio / nGroups;

  _Score({
    required this.groups,
    required this.sumMinRatio,
  });

  /// Smaller score is better
  operator <(_Score other) {
    if (groups.length == other.groups.length) {
      assert(nGroups > 0 && other.nGroups > 0);
      return averageMinRatio > other.averageMinRatio;
    }
    return groups.length < other.groups.length;
  }

  _Score addGroupStart(int index, double minRatio) =>
      _Score(groups: [index] + groups, sumMinRatio: sumMinRatio + minRatio);
}

/// Helper for [groupValues]. Returns the optimal grouping given a subarray into [data] starting
/// from [iStart]. Records/fetches the value from [cache].
_Score _groupValuesHelper(
  List<double> data,
  double minSameGroupRatio,
  int iStart,
  Map<int, _Score> cache,
) {
  final score = cache[iStart];
  if (score != null) return score;
  assert(iStart <= data.length);

  _Score? out;
  if (iStart == data.length) {
    /// Recursion base case
    out = _Score(groups: [data.length], sumMinRatio: 0);
  } else {
    final startVal = data[iStart];

    /// Create a single group [iStart, iEnd) and recurse on [iEnd, last].
    for (int iEnd = iStart + 1; iEnd <= data.length; iEnd++) {
      final tailScore = _groupValuesHelper(data, minSameGroupRatio, iEnd, cache);
      final totalScore = tailScore.addGroupStart(iStart, data[iEnd - 1] / startVal);
      if (out == null || totalScore < out) {
        out = totalScore;
      }

      /// Stop expanding the group if we fall below [minSameGroupRatio]
      if (iEnd < data.length) {
        if (data[iEnd] / startVal < minSameGroupRatio) break;
      }
    }
  }

  cache[iStart] = out!;
  return out;
}

/// Groups values in [data] together such that
///     1. The ratio between the smallest and largest entry of each group is always greater than
///        [minSameGroupRatio].
///     2. The number of groups is minimized, and the above ratio is maximized.
/// Assumes [data] is in decreasing order. The returned list contains the indices of where each
/// group start (and is postpended with data.length).
List<int> groupValues(List<double> data, double minSameGroupRatio) {
  Map<int, _Score> cache = {};
  final best = _groupValuesHelper(data, minSameGroupRatio, 0, cache);
  // for (final entry in cache.entries) {
  //   print("${entry.key} ${entry.value.groups}");
  // }
  return best.groups;
}

/// Finds the reverse cumulative sum of [data].
/// `out[i] = sum(data.values[i:])` with 0 appended at the end.
List<double> reverseCumSum(List<double> data) {
  final out = <double>[0];
  for (var i = data.length - 1; i >= 0; i--) {
    final val = data[i];
    out.insert(0, val + out.first);
  }
  return out;
}

/// Helper class for creating a heatmap.
///
/// The algorithm first collects entries into groups using [groupValues]. The first group is
/// placed along the larger axis of [totalRect], such that it takes up the full cross-axis width;
/// see [layoutGroupAlongLargeAxis]. The unused portion of the rectangle is then passed to the next
/// group. Thus the groups tend to spiral from the top-left to the bottom-right.
///
/// Each group is laid out in its corresponding rectangle by [layoutGroupInRect], which tries to
/// keep each entry as square as possible.
class _HeatMapHelper {
  List<int>? groups;
  final Rect totalRect;
  final List<double> data;
  final double minSameAxisRatio;
  final double padding;
  double paddingX;
  double paddingY;

  List<double> cumValues = [];
  List<Rect> output = [];

  _HeatMapHelper({
    this.groups,
    required this.totalRect,
    required this.data,
    required this.minSameAxisRatio,
    required this.padding,
    required this.paddingX,
    required this.paddingY,
  }) {
    if (padding != 0) {
      paddingX = padding;
      paddingY = padding;
    }
    cumValues = reverseCumSum(data);
  }

  bool aprEq(double x, double y) {
    return (x - y).abs() < 1;
  }

  /// The min/max here make sure the padding doesn't cause the Rect to have negative size
  void add(Rect rect) {
    output.add(Rect.fromLTRB(
      (rect.left == totalRect.left) ? rect.left : min(rect.left + paddingX, rect.center.dx),
      (rect.top == totalRect.top) ? rect.top : min(rect.top + paddingY, rect.center.dy),
      (aprEq(rect.right, totalRect.right))
          ? rect.right
          : max(rect.right - paddingX, rect.center.dx),
      (aprEq(rect.bottom, totalRect.bottom))
          ? rect.bottom
          : max(rect.bottom - paddingY, rect.center.dy),
    ));
  }

  /// Returns the end index (exclusive) of the entry last large enough to be in the same as
  /// [start]. Assumes [data] is sorted by decreasing value.
  int getGroupEnd(int start) {
    final valStart = data[start];
    var end = start + 1;
    while (end < data.length) {
      final val = data[end];
      if (val < minSameAxisRatio * valStart) return end;
      end++;
    }
    return end;
  }

  /// Lays out the elements from [start, end) inside [rect] along the larger axis of [rect]. Each
  /// element uses the full cross-axis width. [rect] is fully covered.
  void layoutSideBySide(int start, int end, Rect rect) {
    final total = cumValues[start] - cumValues[end];
    if (rect.width >= rect.height) {
      /// x axis is longest
      var x = rect.topLeft.dx;
      for (var i = start; i < end; i++) {
        final thisWidth = rect.width * data[i] / total;
        final itemRect = Rect.fromLTWH(x, rect.topLeft.dy, thisWidth, rect.height);
        add(itemRect);
        x += thisWidth;
      }
    } else {
      /// y axis is longest
      var y = rect.topLeft.dy;
      for (var i = start; i < end; i++) {
        final thisHeight = rect.height * data[i] / total;
        final itemRect = Rect.fromLTWH(rect.topLeft.dx, y, rect.width, thisHeight);
        add(itemRect);
        y += thisHeight;
      }
    }
  }

  /// We want to layout the group given by [start, end) such that each element is as close to square
  /// as possible. We assume that each group entry is approximately the same size.
  void layoutGroupInRect(int start, int end, Rect rect) {
    final n = end - start;
    final affinity = rect.longestSide / rect.shortestSide;
    if (n == 1) {
      add(rect);
      return;
    } else if (n == 2) {
      layoutSideBySide(start, end, rect);
      return;
    } else if (affinity + 1 >= n) {
      /// The rectangle is super long, so just add the elements side by side
      layoutSideBySide(start, end, rect);
      return;
    } else if (n == 3) {
      /// Exceptional case for n == 3: here we want the largest element on the short side
      final newRect = layoutGroupAlongLargeAxis(start, start + 1, rect);
      layoutSideBySide(start + 1, end, newRect);
    } else {
      /// Here we hardcode to splitting the rectangle into two rows...this is pretty much universally
      /// optimal (?) with the exception of really large n...i.e. an affinity of 1 and n = 9 would
      /// optimally be placed into three rows.
      final newGroups = [start, start + n ~/ 2, end];
      final groupTotal = cumValues[start] - cumValues[end];
      var pos = rect.width > rect.height ? rect.top : rect.left;
      for (int i = 0; i < newGroups.length - 1; i++) {
        final rowStart = newGroups[i];
        final rowEnd = newGroups[i + 1];
        final rowTotal = cumValues[rowStart] - cumValues[rowEnd];

        final extent = min(rect.height, rect.width);
        final newPos = pos + extent * rowTotal / groupTotal;
        final rowRect = rect.width > rect.height
            ? Rect.fromLTRB(rect.left, pos, rect.right, newPos)
            : Rect.fromLTRB(pos, rect.top, newPos, rect.bottom);
        layoutSideBySide(rowStart, rowEnd, rowRect);
        pos = newPos;
      }
    }
  }

  /// Lays out a group indexed by [start, end) along the larger axis. The group will use the full
  /// width of the cross axis. Returns the new [Rect] of remaining space.
  Rect layoutGroupAlongLargeAxis(int start, int end, Rect rect) {
    final total = cumValues[start];
    final totalGroup = total - cumValues[end];
    if (rect.width >= rect.height) {
      /// x axis is longest
      final newX = rect.left + rect.width * totalGroup / total;
      final groupRect = Rect.fromPoints(rect.topLeft, Offset(newX, rect.bottom));
      layoutGroupInRect(start, end, groupRect);
      return Rect.fromPoints(groupRect.topRight, rect.bottomRight);
    } else {
      /// y axis is longest
      final newY = rect.top + rect.height * totalGroup / total;
      final groupRect = Rect.fromPoints(rect.topLeft, Offset(rect.right, newY));
      layoutGroupInRect(start, end, groupRect);
      return Rect.fromPoints(groupRect.bottomLeft, rect.bottomRight);
    }
  }

  void layout() {
    groups ??= groupValues(data, minSameAxisRatio);
    var rect = totalRect;
    for (int i = 0; i < groups!.length - 1; i++) {
      rect = layoutGroupAlongLargeAxis(groups![i], groups![i + 1], rect);
    }
  }
}

/// Returns a list of [Rect] positions for a heatmap. Each entry in [data] is given a rectangular
/// region proportional to its value from [valueMapper].
///
/// [data] should be sorted by decreasing value already. Values should all be positive.
///
/// [padding] is the amount of pixel padding to space between the boxes. It is a dumb padding that
/// simply removes space from the interior sides of each rectangle. As such for large values of
/// padding, the visible areas of the rectangles won't exactly be proportional to their values.
List<Rect> layoutHeatMapGrid({
  required Rect rect,
  required List<double> data,
  List<int>? groups,
  double minSameAxisRatio = 0.8,
  double padding = 0,
  double paddingX = 0,
  double paddingY = 0,
}) {
  if (data.isEmpty) return [];
  final helper = _HeatMapHelper(
    groups: groups,
    totalRect: rect,
    data: data,
    minSameAxisRatio: minSameAxisRatio,
    padding: padding,
    paddingX: paddingX,
    paddingY: paddingY,
  );
  helper.layout();
  assert(helper.output.length == data.length);
  return helper.output;
}
