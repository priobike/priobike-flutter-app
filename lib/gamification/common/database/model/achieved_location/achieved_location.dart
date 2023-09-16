import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';
import 'package:priobike/gamification/community/model/location.dart';

part 'achieved_location.g.dart';

class AchievedLocations extends Table {
  IntColumn get id => integer()();
  IntColumn get eventId => integer()();
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

  Future<AchievedLocation?> addLocation(EventLocation location, int eventId) async {
    var obj = await getObjectByPrimaryKey(location.id);
    if (obj == null) {
      return createObject(
        AchievedLocation(
          id: location.id,
          eventId: eventId,
          title: location.title,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      return null;
    }
  }

  Stream<List<AchievedLocation>> streamLocationsForEvent(int eventId) {
    return (select(achievedLocations)..where((tbl) => tbl.eventId.equals(eventId))).watch();
  }
}
