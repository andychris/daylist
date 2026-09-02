import 'package:flutter/material.dart';

import '../../domain/quick_add/task_input_parser.dart';

/// A [TextEditingController] that bolds/colors every substring
/// [findHighlightRanges] recognizes (dates, times, recurrence phrases,
/// `pN`, `#project`, `@label`) as the user types.
class QuickAddTextController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final ranges = [...findHighlightRanges(text)]
      ..sort((a, b) => a.start.compareTo(b.start));
    final highlightStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      // Two recognizers can claim overlapping text (e.g. "at 4pm" matched
      // by both the 12h and "at "-prefixed patterns) — keep the first and
      // skip anything that starts before it ends.
      if (range.start < cursor) continue;
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      spans.add(
        TextSpan(text: text.substring(range.start, range.end), style: highlightStyle),
      );
      cursor = range.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(style: style, children: spans);
  }
}
