import 'achievement.dart';

enum AchievementStatusFilter { all, inProgress, completed }

enum AchievementTypeFilter { all, streak, region, distance, area }

class AchievementFilter {
  const AchievementFilter({
    this.status = AchievementStatusFilter.all,
    this.type = AchievementTypeFilter.all,
    this.query = '',
  });

  final AchievementStatusFilter status;
  final AchievementTypeFilter type;
  final String query;

  List<Achievement> apply(List<Achievement> source, UserStats stats) {
    final normalizedQuery = query.trim().toLowerCase();
    return source
        .where((achievement) {
          if (!_matchesStatus(achievement, stats)) return false;
          if (!_matchesType(achievement)) return false;
          if (normalizedQuery.isEmpty) return true;
          final searchable = [
            achievement.id,
            achievement.titleKo,
            achievement.descKo,
            achievement.metric.name,
            achievement.category.name,
          ].join(' ').toLowerCase();
          return searchable.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  bool _matchesStatus(Achievement achievement, UserStats stats) {
    final done = achievement.isCompleted(stats);
    switch (status) {
      case AchievementStatusFilter.all:
        return true;
      case AchievementStatusFilter.inProgress:
        return !done;
      case AchievementStatusFilter.completed:
        return done;
    }
  }

  bool _matchesType(Achievement achievement) {
    switch (type) {
      case AchievementTypeFilter.all:
        return true;
      case AchievementTypeFilter.streak:
        return achievement.category == AchievementCategory.streak;
      case AchievementTypeFilter.region:
        return achievement.category == AchievementCategory.region;
      case AchievementTypeFilter.distance:
        return achievement.category == AchievementCategory.distance;
      case AchievementTypeFilter.area:
        return achievement.category == AchievementCategory.area;
    }
  }
}
