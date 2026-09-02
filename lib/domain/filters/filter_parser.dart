import '../models/task_priority.dart';
import 'filter_node.dart';

/// Thrown by [parseFilterQuery] when [query] isn't a valid expression.
class FilterParseException implements Exception {
  FilterParseException(this.message);
  final String message;

  @override
  String toString() => 'FilterParseException: $message';
}

enum _TokenType {
  and,
  or,
  not,
  lparen,
  rparen,
  priority,
  today,
  overdue,
  next7Days,
  noDate,
  project,
  label,
}

class _Token {
  const _Token(this.type, [this.value]);
  final _TokenType type;
  final String? value;
}

final _tokenPattern = RegExp(
  r'7\s*days'
  r'|no\s*date'
  r'|\boverdue\b'
  r'|\btoday\b'
  r'|\bp([1-4])\b'
  r'|#([A-Za-z0-9_-]+)'
  r'|@([A-Za-z0-9_-]+)'
  r'|&'
  r'|\|'
  r'|!'
  r'|\('
  r'|\)',
  caseSensitive: false,
);

List<_Token> _tokenize(String query) {
  final tokens = <_Token>[];
  var cursor = 0;
  for (final match in _tokenPattern.allMatches(query)) {
    if (match.start != cursor) {
      final skipped = query.substring(cursor, match.start).trim();
      if (skipped.isNotEmpty) {
        throw FilterParseException('Unrecognized text: "$skipped"');
      }
    }
    cursor = match.end;

    final text = match.group(0)!.toLowerCase();
    if (text.startsWith('7')) {
      tokens.add(const _Token(_TokenType.next7Days));
    } else if (text.startsWith('no')) {
      tokens.add(const _Token(_TokenType.noDate));
    } else if (text == 'overdue') {
      tokens.add(const _Token(_TokenType.overdue));
    } else if (text == 'today') {
      tokens.add(const _Token(_TokenType.today));
    } else if (match.group(1) != null) {
      tokens.add(_Token(_TokenType.priority, match.group(1)));
    } else if (match.group(2) != null) {
      tokens.add(_Token(_TokenType.project, match.group(2)));
    } else if (match.group(3) != null) {
      tokens.add(_Token(_TokenType.label, match.group(3)));
    } else if (text == '&') {
      tokens.add(const _Token(_TokenType.and));
    } else if (text == '|') {
      tokens.add(const _Token(_TokenType.or));
    } else if (text == '!') {
      tokens.add(const _Token(_TokenType.not));
    } else if (text == '(') {
      tokens.add(const _Token(_TokenType.lparen));
    } else if (text == ')') {
      tokens.add(const _Token(_TokenType.rparen));
    }
  }
  final trailing = query.substring(cursor).trim();
  if (trailing.isNotEmpty) {
    throw FilterParseException('Unrecognized text: "$trailing"');
  }
  return tokens;
}

class _Parser {
  _Parser(this._tokens);
  final List<_Token> _tokens;
  var _pos = 0;

  _Token? get _peek => _pos < _tokens.length ? _tokens[_pos] : null;

  _Token _consume() {
    final token = _peek;
    if (token == null) {
      throw FilterParseException('Unexpected end of query');
    }
    _pos++;
    return token;
  }

  FilterNode parse() {
    final node = _parseOr();
    if (_peek != null) {
      throw FilterParseException('Unexpected token after expression');
    }
    return node;
  }

  // Lowest precedence: `|` (OR), then `&` (AND), then unary `!`, then atoms.
  FilterNode _parseOr() {
    var left = _parseAnd();
    while (_peek?.type == _TokenType.or) {
      _consume();
      left = FilterOr(left, _parseAnd());
    }
    return left;
  }

  FilterNode _parseAnd() {
    var left = _parseUnary();
    while (_peek?.type == _TokenType.and) {
      _consume();
      left = FilterAnd(left, _parseUnary());
    }
    return left;
  }

  FilterNode _parseUnary() {
    if (_peek?.type == _TokenType.not) {
      _consume();
      return FilterNot(_parseUnary());
    }
    return _parseAtom();
  }

  FilterNode _parseAtom() {
    final token = _consume();
    switch (token.type) {
      case _TokenType.lparen:
        final inner = _parseOr();
        if (_peek?.type != _TokenType.rparen) {
          throw FilterParseException('Missing closing ")"');
        }
        _consume();
        return inner;
      case _TokenType.priority:
        return FilterPriority(TaskPriority.values[int.parse(token.value!) - 1]);
      case _TokenType.today:
        return const FilterToday();
      case _TokenType.overdue:
        return const FilterOverdue();
      case _TokenType.next7Days:
        return const FilterNext7Days();
      case _TokenType.noDate:
        return const FilterNoDate();
      case _TokenType.project:
        return FilterProject(token.value!);
      case _TokenType.label:
        return FilterLabel(token.value!);
      case _TokenType.and:
      case _TokenType.or:
      case _TokenType.not:
      case _TokenType.rparen:
        throw FilterParseException('Unexpected token');
    }
  }
}

/// Parses a filter query like `p1 & (today | overdue) & !#Work` into a
/// [FilterNode] tree — see `filter_evaluator.dart` to match it against
/// tasks. Operators: `&` (and), `|` (or), `!` (not, prefix), `( )`;
/// `&` binds tighter than `|`. Atoms: `p1`-`p4`, `today`, `overdue`,
/// `7 days`, `no date`, `#Project`, `@Label`.
FilterNode parseFilterQuery(String query) {
  final tokens = _tokenize(query);
  if (tokens.isEmpty) {
    throw FilterParseException('Empty query');
  }
  return _Parser(tokens).parse();
}
