import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';
import 'package:priobike/gamification/community_event/model/event.dart';

part 'event_badge.g.dart';

class EventBadges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get icon => integer()();
  IntColumn get eventId => integer()();
  TextColumn get title => text()();
  DateTimeColumn get achievedTimestamp => dateTime()();
}

@DriftAccessor(tables: [EventBadges])
class EventBadgeDao extends DatabaseDao<EventBadge> with _$EventBadgeDaoMixin {
  EventBadgeDao(super.attachedDatabase);

  @override
  TableInfo<Table, dynamic> get table => eventBadges;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(eventBadges)..where((tbl) => (tbl as $EventBadgesTable).id.equals(value)));
  }

  Future<EventBadge?> createEventBadge(WeekendEvent event) async {
    var obj = await (select(eventBadges)..where((tbl) => tbl.eventId.equals(event.id))).get();
    // If there already is a badge for the event, return null.
    if (obj.isNotEmpty) return null;
    // If there is no badge for the event, create a new one.
    return createObject(
      EventBadgesCompanion.insert(
        icon: event.iconValue,
        eventId: event.id,
        title: event.title,
        achievedTimestamp: DateTime.now(),
      ),
    );
  }
}
