import 'package:daylist/domain/filters/filter_node.dart';
import 'package:daylist/domain/filters/filter_parser.dart';
import 'package:daylist/domain/models/task_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('atoms', () {
    test('p1-p4', () {
      expect(parseFilterQuery('p1'), isA<FilterPriority>());
      final node = parseFilterQuery('p3') as FilterPriority;
      expect(node.priority, TaskPriority.p3);
    });

    test('today / overdue / 7 days / no date', () {
      expect(parseFilterQuery('today'), isA<FilterToday>());
      expect(parseFilterQuery('overdue'), isA<FilterOverdue>());
      expect(parseFilterQuery('7 days'), isA<FilterNext7Days>());
      expect(parseFilterQuery('no date'), isA<FilterNoDate>());
    });

    test('#Project and @Label capture their name', () {
      final project = parseFilterQuery('#Work') as FilterProject;
      expect(project.name, 'Work');
      final label = parseFilterQuery('@urgent') as FilterLabel;
      expect(label.name, 'urgent');
    });

    test('is case-insensitive for keywords', () {
      expect(parseFilterQuery('TODAY'), isA<FilterToday>());
      expect(parseFilterQuery('P1'), isA<FilterPriority>());
    });
  });

  group('operators', () {
    test('& produces FilterAnd', () {
      final node = parseFilterQuery('p1 & today') as FilterAnd;
      expect(node.left, isA<FilterPriority>());
      expect(node.right, isA<FilterToday>());
    });

    test('| produces FilterOr', () {
      final node = parseFilterQuery('today | overdue') as FilterOr;
      expect(node.left, isA<FilterToday>());
      expect(node.right, isA<FilterOverdue>());
    });

    test('! produces FilterNot, binding to the next atom only', () {
      final node = parseFilterQuery('!#Work & today') as FilterAnd;
      final not = node.left as FilterNot;
      expect(not.operand, isA<FilterProject>());
      expect(node.right, isA<FilterToday>());
    });

    test('& binds tighter than |', () {
      // Should parse as (p1 & today) | overdue, not p1 & (today | overdue).
      final node = parseFilterQuery('p1 & today | overdue') as FilterOr;
      expect(node.left, isA<FilterAnd>());
      expect(node.right, isA<FilterOverdue>());
    });

    test('parentheses override precedence', () {
      final node = parseFilterQuery('p1 & (today | overdue)') as FilterAnd;
      expect(node.left, isA<FilterPriority>());
      expect(node.right, isA<FilterOr>());
    });

    test('the blueprint example parses into the expected shape', () {
      final node = parseFilterQuery('p1 & (today | overdue) & !#Work');
      // ((p1 & (today|overdue)) & !#Work)
      final outerAnd = node as FilterAnd;
      expect(outerAnd.right, isA<FilterNot>());
      final innerAnd = outerAnd.left as FilterAnd;
      expect(innerAnd.left, isA<FilterPriority>());
      expect(innerAnd.right, isA<FilterOr>());
    });
  });

  group('errors', () {
    test('empty query', () {
      expect(() => parseFilterQuery(''), throwsA(isA<FilterParseException>()));
      expect(() => parseFilterQuery('   '), throwsA(isA<FilterParseException>()));
    });

    test('unrecognized text', () {
      expect(
        () => parseFilterQuery('p1 & banana'),
        throwsA(isA<FilterParseException>()),
      );
    });

    test('unbalanced parentheses', () {
      expect(
        () => parseFilterQuery('(p1 & today'),
        throwsA(isA<FilterParseException>()),
      );
      expect(
        () => parseFilterQuery('p1 & today)'),
        throwsA(isA<FilterParseException>()),
      );
    });

    test('dangling operator', () {
      expect(
        () => parseFilterQuery('p1 &'),
        throwsA(isA<FilterParseException>()),
      );
      expect(() => parseFilterQuery('& p1'), throwsA(isA<FilterParseException>()));
    });
  });
}
