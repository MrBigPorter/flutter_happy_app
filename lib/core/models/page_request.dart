/// Description: A generic class to represent paginated results.
/// It includes a list of items, total count, current page, and page size.
///
/// Usage:
/// ```dart
/// final pageResult = PageResult<ItemType>(
///  list: [...],
///  total: 100,
///  page: 1,
///  pageSize: 10,
///  );
/// ```
class PageResult<T> {
  final List<T> list;
  final int total;
  final int page;
  final int count;
  final int size;

  const PageResult({
    required this.list,
    required this.total,
    required this.page,
    required this.count,
    required this.size,
  });
}

/// Description: A class to encapsulate a paginated request function.
/// It takes a function that accepts page size and current page as parameters
typedef PageRequest<T> = Future<PageResult<T>> Function({required int pageSize, required int page});

