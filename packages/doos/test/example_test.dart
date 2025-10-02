// ignore_for_file: avoid_redundant_argument_values

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Example classes and dependencies

class SomeClass {
  SomeClass({
    required this.someDependency,
    required this.someValue,
  });

  final SomeDependency someDependency;
  final bool someValue;

  bool doSomething1() {
    final value = someDependency.returnBool();
    someDependency.sideEffect();
    return value;
  }

  // ignore: avoid_positional_boolean_parameters
  void doSomething2(bool value) {
    if (value && someValue) {
      someDependency.doThing1();
    } else {
      someDependency.doThing2();
    }
  }
}

class SomeDependency {
  SomeDependency({required this.someValue});
  final String someValue;

  void sideEffect() {}

  void doThing1() {}

  Future<void> doThing2() async {}

  bool returnBool() {
    return true;
  }

  Future<int> returnInt() async {
    return 1;
  }
}

// Example tests for SomeClass

class MockSomeDependency extends Mock implements SomeDependency {}

void main() {
  group('SomeClass', () {
    late SomeDependency someDependency;

    setUp(() {
      someDependency = MockSomeDependency();
      when(() => someDependency.doThing1()).thenReturn(null);
      when(() => someDependency.doThing2()).thenAnswer((_) async {});
      when(() => someDependency.returnBool()).thenReturn(true);
      when(() => someDependency.returnInt()).thenAnswer((_) async => 1);
    });

    SomeClass buildSubject({
      bool someValue = true,
    }) {
      return SomeClass(
        someDependency: someDependency,
        someValue: someValue,
      );
    }

    group('doSomething1', () {
      test('returns true when someValue is true', () {
        when(() => someDependency.returnBool()).thenReturn(true);
        final subject = buildSubject();
        expect(subject.doSomething1(), isTrue);
      });

      test('returns false when someValue is false', () {
        when(() => someDependency.returnBool()).thenReturn(false);
        final subject = buildSubject();
        expect(subject.doSomething1(), isFalse);
      });

      test('calls sideEffect', () {
        buildSubject().doSomething1();

        verify(() => someDependency.sideEffect()).called(1);
      });
    });

    group('doSomething2', () {
      test('calls doThing1 when given value and someValue are true', () {
        buildSubject(someValue: true).doSomething2(true);

        verify(() => someDependency.doThing1()).called(1);
        verifyNever(() => someDependency.doThing2());
      });

      test('calls doThing2 when given value is false', () {
        buildSubject(someValue: true).doSomething2(false);

        verify(() => someDependency.doThing2()).called(1);
        verifyNever(() => someDependency.doThing1());
      });

      test('calls doThing2 when someValue is false', () {
        buildSubject(someValue: false).doSomething2(true);

        verify(() => someDependency.doThing2()).called(1);
        verifyNever(() => someDependency.doThing1());
      });
    });
  });
}
