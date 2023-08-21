import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';

part 'challenge.g.dart';

enum ChallengeType {
  distance,
  duration,
  rides,
}

class Challenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get xp => integer()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();
  TextColumn get description => text()();
  IntColumn get target => integer()();
  IntColumn get progress => integer()();
  BoolColumn get isWeekly => boolean()();
  IntColumn get type => integer()();
  TextColumn get valueLabel => text()();
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
