import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';

part 'user_profile.g.dart';

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get totalDistance => real()();
  RealColumn get totalDuration => real()();
  RealColumn get totalElevationGain => real()();
  RealColumn get totalElevationLoss => real()();
  DateTimeColumn get joinDate => dateTime()();
}

@DriftAccessor(tables: [UserProfiles])
class UserProfileDao extends DatabaseDao<UserProfile> with _$UserProfileDaoMixin {
  UserProfileDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  @override
  TableInfo<Table, dynamic> get table => userProfiles;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(userProfiles)..where((tbl) => (tbl as $UserProfilesTable).id.equals(value)));
  }
}