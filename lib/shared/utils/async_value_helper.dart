import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper pour combiner plusieurs AsyncValue en un seul.
///
/// Utile pour simplifier le code quand on a besoin de combiner plusieurs
/// sources de données asynchrones.
class AsyncValueHelper {
  const AsyncValueHelper._();

  /// Combine 2 AsyncValues en un seul.
  ///
  /// Retourne:
  /// - `loading` si l'un ou l'autre est en chargement
  /// - `error` si l'un ou l'autre a une erreur (priorité à la première erreur)
  /// - `data` avec un record contenant les deux valeurs si tout est chargé
  static AsyncValue<({T1 first, T2 second})> combine2<T1, T2>(
    AsyncValue<T1> first,
    AsyncValue<T2> second,
  ) {
    if (first.isLoading || second.isLoading) {
      return const AsyncValue.loading();
    }

    if (first.hasError) {
      return AsyncValue.error(
        first.error!,
        first.stackTrace ?? StackTrace.empty,
      );
    }
    if (second.hasError) {
      return AsyncValue.error(
        second.error!,
        second.stackTrace ?? StackTrace.empty,
      );
    }

    return AsyncValue.data((
      first: first.value!,
      second: second.value!,
    ));
  }

  /// Combine 3 AsyncValues en un seul.
  static AsyncValue<({T1 first, T2 second, T3 third})> combine3<T1, T2, T3>(
    AsyncValue<T1> first,
    AsyncValue<T2> second,
    AsyncValue<T3> third,
  ) {
    if (first.isLoading || second.isLoading || third.isLoading) {
      return const AsyncValue.loading();
    }

    if (first.hasError) {
      return AsyncValue.error(
        first.error!,
        first.stackTrace ?? StackTrace.empty,
      );
    }
    if (second.hasError) {
      return AsyncValue.error(
        second.error!,
        second.stackTrace ?? StackTrace.empty,
      );
    }
    if (third.hasError) {
      return AsyncValue.error(
        third.error!,
        third.stackTrace ?? StackTrace.empty,
      );
    }

    return AsyncValue.data((
      first: first.value!,
      second: second.value!,
      third: third.value!,
    ));
  }

  /// Combine 4 AsyncValues en un seul.
  static AsyncValue<({T1 first, T2 second, T3 third, T4 fourth})> combine4<
      T1, T2, T3, T4>(
    AsyncValue<T1> first,
    AsyncValue<T2> second,
    AsyncValue<T3> third,
    AsyncValue<T4> fourth,
  ) {
    if (first.isLoading ||
        second.isLoading ||
        third.isLoading ||
        fourth.isLoading) {
      return const AsyncValue.loading();
    }

    if (first.hasError) {
      return AsyncValue.error(
        first.error!,
        first.stackTrace ?? StackTrace.empty,
      );
    }
    if (second.hasError) {
      return AsyncValue.error(
        second.error!,
        second.stackTrace ?? StackTrace.empty,
      );
    }
    if (third.hasError) {
      return AsyncValue.error(
        third.error!,
        third.stackTrace ?? StackTrace.empty,
      );
    }
    if (fourth.hasError) {
      return AsyncValue.error(
        fourth.error!,
        fourth.stackTrace ?? StackTrace.empty,
      );
    }

    return AsyncValue.data((
      first: first.value!,
      second: second.value!,
      third: third.value!,
      fourth: fourth.value!,
    ));
  }

  /// Combine 5 AsyncValues en un seul.
  static AsyncValue<
          ({
            T1 first,
            T2 second,
            T3 third,
            T4 fourth,
            T5 fifth,
          })>
      combine5<T1, T2, T3, T4, T5>(
    AsyncValue<T1> first,
    AsyncValue<T2> second,
    AsyncValue<T3> third,
    AsyncValue<T4> fourth,
    AsyncValue<T5> fifth,
  ) {
    if (first.isLoading ||
        second.isLoading ||
        third.isLoading ||
        fourth.isLoading ||
        fifth.isLoading) {
      return const AsyncValue.loading();
    }

    if (first.hasError) {
      return AsyncValue.error(
        first.error!,
        first.stackTrace ?? StackTrace.empty,
      );
    }
    if (second.hasError) {
      return AsyncValue.error(
        second.error!,
        second.stackTrace ?? StackTrace.empty,
      );
    }
    if (third.hasError) {
      return AsyncValue.error(
        third.error!,
        third.stackTrace ?? StackTrace.empty,
      );
    }
    if (fourth.hasError) {
      return AsyncValue.error(
        fourth.error!,
        fourth.stackTrace ?? StackTrace.empty,
      );
    }
    if (fifth.hasError) {
      return AsyncValue.error(
        fifth.error!,
        fifth.stackTrace ?? StackTrace.empty,
      );
    }

    return AsyncValue.data((
      first: first.value!,
      second: second.value!,
      third: third.value!,
      fourth: fourth.value!,
      fifth: fifth.value!,
    ));
  }
}
