import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared/utils/async_value_helper.dart';

void main() {
  group('AsyncValueHelper', () {
    group('combine2', () {
      test('returns loading when first is loading', () {
        final first = const AsyncValue.loading();
        final second = AsyncValue.data(2);

        final result = AsyncValueHelper.combine2(first, second);

        expect(result.isLoading, isTrue);
      });

      test('returns loading when second is loading', () {
        final first = AsyncValue.data(1);
        const second = AsyncValue.loading();

        final result = AsyncValueHelper.combine2(first, second);

        expect(result.isLoading, isTrue);
      });

      test('returns error when first has error', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;
        final first = AsyncValue.error(error, stackTrace);
        final second = AsyncValue.data(2);

        final result = AsyncValueHelper.combine2(first, second);

        expect(result.hasError, isTrue);
        expect(result.error, error);
      });

      test('returns error when second has error', () {
        final first = AsyncValue.data(1);
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;
        final second = AsyncValue.error(error, stackTrace);

        final result = AsyncValueHelper.combine2(first, second);

        expect(result.hasError, isTrue);
        expect(result.error, error);
      });

      test('returns data when both have data', () {
        final first = AsyncValue.data(1);
        final second = AsyncValue.data(2);

        final result = AsyncValueHelper.combine2(first, second);

        expect(result.hasValue, isTrue);
        expect(result.value?.first, 1);
        expect(result.value?.second, 2);
      });
    });

    group('combine3', () {
      test('returns loading when any is loading', () {
        final first = const AsyncValue.loading();
        final second = AsyncValue.data(2);
        final third = AsyncValue.data(3);

        final result = AsyncValueHelper.combine3(first, second, third);

        expect(result.isLoading, isTrue);
      });

      test('returns error when first has error', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;
        final first = AsyncValue.error(error, stackTrace);
        final second = AsyncValue.data(2);
        final third = AsyncValue.data(3);

        final result = AsyncValueHelper.combine3(first, second, third);

        expect(result.hasError, isTrue);
        expect(result.error, error);
      });

      test('returns data when all have data', () {
        final first = AsyncValue.data(1);
        final second = AsyncValue.data(2);
        final third = AsyncValue.data(3);

        final result = AsyncValueHelper.combine3(first, second, third);

        expect(result.hasValue, isTrue);
        expect(result.value?.first, 1);
        expect(result.value?.second, 2);
        expect(result.value?.third, 3);
      });
    });

    group('combine4', () {
      test('returns loading when any is loading', () {
        final first = const AsyncValue.loading();
        final second = AsyncValue.data(2);
        final third = AsyncValue.data(3);
        final fourth = AsyncValue.data(4);

        final result = AsyncValueHelper.combine4(
          first,
          second,
          third,
          fourth,
        );

        expect(result.isLoading, isTrue);
      });

      test('returns data when all have data', () {
        final first = AsyncValue.data(1);
        final second = AsyncValue.data(2);
        final third = AsyncValue.data(3);
        final fourth = AsyncValue.data(4);

        final result = AsyncValueHelper.combine4(
          first,
          second,
          third,
          fourth,
        );

        expect(result.hasValue, isTrue);
        expect(result.value?.first, 1);
        expect(result.value?.second, 2);
        expect(result.value?.third, 3);
        expect(result.value?.fourth, 4);
      });
    });

    group('combine5', () {
      test('returns loading when any is loading', () {
        final first = const AsyncValue.loading();
        final second = AsyncValue.data(2);
        final third = AsyncValue.data(3);
        final fourth = AsyncValue.data(4);
        final fifth = AsyncValue.data(5);

        final result = AsyncValueHelper.combine5(
          first,
          second,
          third,
          fourth,
          fifth,
        );

        expect(result.isLoading, isTrue);
      });

      test('returns data when all have data', () {
        final first = AsyncValue.data(1);
        final second = AsyncValue.data(2);
        final third = AsyncValue.data(3);
        final fourth = AsyncValue.data(4);
        final fifth = AsyncValue.data(5);

        final result = AsyncValueHelper.combine5(
          first,
          second,
          third,
          fourth,
          fifth,
        );

        expect(result.hasValue, isTrue);
        expect(result.value?.first, 1);
        expect(result.value?.second, 2);
        expect(result.value?.third, 3);
        expect(result.value?.fourth, 4);
        expect(result.value?.fifth, 5);
      });
    });
  });
}
