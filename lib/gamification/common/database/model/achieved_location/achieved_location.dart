import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';
import 'package:priobike/gamification/community_event/model/event.dart';
import 'package:priobike/gamification/community_event/model/location.dart';

part 'achieved_location.g.dart';

class AchievedLocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get locationId => integer()();
  IntColumn get eventId => integer()();
  IntColumn get color => integer()();
  TextColumn get title => text()();
  DateTimeColumn get timestamp => dateTime()();
}

@DriftAccessor(tables: [AchievedLocations])
class AchievedLocationDao extends DatabaseDao<AchievedLocation> with _$AchievedLocationDaoMixin {
  AchievedLocationDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  @override
  TableInfo<Table, dynamic> get table => achievedLocations;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(achievedLocations)..where((tbl) => (tbl as $AchievedLocationsTable).id.equals(value)));
  }

  Future<AchievedLocation?> createAchievedLocation(EventLocation location, WeekendEvent event) async {
    var obj = await (select(achievedLocations)..where((tbl) => tbl.locationId.equals(location.id))).get();
    // If the location was already saved as achieved, return null.
    if (obj.isNotEmpty) return null;
    // If the location has not been saved yet, create a new object and save it.
    return createObject(
      AchievedLocationsCompanion.insert(
        locationId: location.id,
        eventId: event.id,
        color: event.colorValue,
        title: location.title,
        timestamp: DateTime.now(),
      ),
    );
  }

  Stream<List<AchievedLocation>> streamLocationsForEvent(int eventId) {
    return (select(achievedLocations)..where((tbl) => tbl.eventId.equals(eventId))).watch();
  }
}
