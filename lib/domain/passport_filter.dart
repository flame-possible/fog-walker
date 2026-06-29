enum PassportUnlockFilter { all, unlocked, locked }

class PassportFilterItem {
  const PassportFilterItem({
    required this.id,
    required this.searchableText,
    required this.unlocked,
  });

  final String id;
  final String searchableText;
  final bool unlocked;
}

class PassportFilter {
  const PassportFilter({
    this.unlock = PassportUnlockFilter.all,
    this.query = '',
  });

  final PassportUnlockFilter unlock;
  final String query;

  List<T> apply<T>(
    List<T> source, {
    PassportFilterItem Function(T item)? itemOf,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return source
        .where((item) {
          final filterItem = itemOf == null
              ? item as PassportFilterItem
              : itemOf(item);
          if (!_matchesUnlock(filterItem)) return false;
          if (normalizedQuery.isEmpty) return true;
          return filterItem.searchableText.toLowerCase().contains(
            normalizedQuery,
          );
        })
        .toList(growable: false);
  }

  bool _matchesUnlock(PassportFilterItem item) {
    switch (unlock) {
      case PassportUnlockFilter.all:
        return true;
      case PassportUnlockFilter.unlocked:
        return item.unlocked;
      case PassportUnlockFilter.locked:
        return !item.unlocked;
    }
  }
}
