import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/repositories/contact_repository.dart';
import '../models/conversation.dart';

/// 1. Stores and manages the current search keyword entered by the user.
/// autoDispose: Ensures the search state is reset when the user navigates away from the page.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// 2. Core: Watches keyword changes and automatically triggers the search logic.
/// Returns a list of ChatUser entities matching the query.
final contactSearchResultsProvider = FutureProvider.autoDispose<List<ChatUser>>((ref) async {
  // Watch the keyword provider to react to input changes
  final query = ref.watch(searchQueryProvider);

  // Obtain the repository instance for data access
  final repository = ref.watch(contactRepositoryProvider);

  // Return an empty list immediately if the query is blank or only contains whitespace
  if (query.trim().isEmpty) {
    return [];
  }

  // Invokes the underlying Sembast inverted index search.
  // This ensures millisecond-level performance even with a large number of contacts (e.g., 10,000+).
  return await repository.search(query);
});