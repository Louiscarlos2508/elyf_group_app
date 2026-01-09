import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/features/administration/domain/services/pagination_service.dart';

void main() {
  group('PaginationService', () {
    late PaginationService service;

    setUp(() {
      service = PaginationService();
    });

    group('calculatePagination', () {
      test('should calculate pagination info correctly', () {
        final info = service.calculatePagination(
          totalItems: 100,
          currentPage: 0,
          itemsPerPage: 50,
        );

        expect(info.currentPage, equals(0));
        expect(info.totalPages, equals(2));
        expect(info.totalItems, equals(100));
        expect(info.itemsPerPage, equals(50));
        expect(info.startIndex, equals(0));
        expect(info.endIndex, equals(50));
        expect(info.hasNextPage, isTrue);
        expect(info.hasPreviousPage, isFalse);
      });

      test('should handle last page correctly', () {
        final info = service.calculatePagination(
          totalItems: 100,
          currentPage: 1,
          itemsPerPage: 50,
        );

        expect(info.currentPage, equals(1));
        expect(info.totalPages, equals(2));
        expect(info.hasNextPage, isFalse);
        expect(info.hasPreviousPage, isTrue);
        expect(info.startIndex, equals(50));
        expect(info.endIndex, equals(100));
      });

      test('should handle empty list', () {
        final info = service.calculatePagination(
          totalItems: 0,
          currentPage: 0,
          itemsPerPage: 50,
        );

        expect(info.totalPages, equals(0));
        expect(info.hasNextPage, isFalse);
        expect(info.hasPreviousPage, isFalse);
      });

      test('should handle partial last page', () {
        final info = service.calculatePagination(
          totalItems: 75,
          currentPage: 1,
          itemsPerPage: 50,
        );

        expect(info.totalPages, equals(2));
        expect(info.startIndex, equals(50));
        expect(info.endIndex, equals(75));
      });
    });

    group('getPageItems', () {
      test('should return correct page items', () {
        final items = List.generate(100, (i) => 'Item $i');
        final pageItems = service.getPageItems<String>(
          allItems: items,
          page: 0,
          itemsPerPage: 50,
        );

        expect(pageItems.length, equals(50));
        expect(pageItems.first, equals('Item 0'));
        expect(pageItems.last, equals('Item 49'));
      });

      test('should return last page items correctly', () {
        final items = List.generate(75, (i) => 'Item $i');
        final pageItems = service.getPageItems<String>(
          allItems: items,
          page: 1,
          itemsPerPage: 50,
        );

        expect(pageItems.length, equals(25));
        expect(pageItems.first, equals('Item 50'));
        expect(pageItems.last, equals('Item 74'));
      });

      test('should return empty list for page beyond range', () {
        final items = List.generate(50, (i) => 'Item $i');
        final pageItems = service.getPageItems<String>(
          allItems: items,
          page: 2,
          itemsPerPage: 50,
        );

        expect(pageItems, isEmpty);
      });

      test('should handle empty items list', () {
        final pageItems = service.getPageItems<String>(
          allItems: [],
          page: 0,
          itemsPerPage: 50,
        );

        expect(pageItems, isEmpty);
      });
    });
  });
}

