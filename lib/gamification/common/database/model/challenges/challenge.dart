import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';

part 'challenge.g.dart';

enum ChallengeType {
  distance,
  duration,
  track,
}

class ChallengeTypeExtension {
  static String getLabel(ChallengeType type) {
    if (type == ChallengeType.distance) return 'm';
    if (type == ChallengeType.duration) return 'min';
    return '';
  }
}

class Challenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get xp => integer()();
  DateTimeColumn get intervalStart => dateTime()();
  DateTimeColumn get intervalEnd => dateTime()();
  IntColumn get target => integer()();
  IntColumn get progress => integer()();
  IntColumn get type => integer()();
}

@DriftAccessor(tables: [Challenges])
class ChallengeDao extends DatabaseDao<Challenge> with _$ChallengeDaoMixin {
  ChallengeDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  @override
  TableInfo<Table, dynamic> get table => challenges;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(challenges)..where((tbl) => (tbl as $ChallengesTable).id.equals(value)));
  }
}
