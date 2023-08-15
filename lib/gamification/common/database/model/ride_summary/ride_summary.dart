import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';
import 'package:priobike/gamification/hub/services/game_service.dart';
import 'package:priobike/main.dart';

part 'ride_summary.g.dart';

/// Table which holds ride summary objects, which contain relevant information of rides which the user has done.
@DataClassName('RideSummary')
class RideSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get distanceMetres => real()();
  RealColumn get durationSeconds => real()();
  RealColumn get elevationGainMetres => real()();
  RealColumn get elevationLossMetres => real()();
  RealColumn get averageSpeedKmh => real()();
}

@DriftAccessor(tables: [RideSummaries])
class RideSummaryDao extends DatabaseDao<RideSummary> with _$RideSummaryDaoMixin {
  RideSummaryDao(AppDatabase attachedDatabase) : super(attachedDatabase) {
    _createMocks(); // This is just for testing /TODO remove
  }

  @override
  TableInfo<Table, dynamic> get table => rideSummaries;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(rideSummaries)..where((tbl) => (tbl as $RideSummariesTable).id.equals(value)));
  }

  void _createMocks() async {
    await _createMock(1208, 400, 12, 14);
    await _createMock(3124, 621, 64, 120);
    await _createMock(14029, 2354, 312, 122);
    getIt<GameService>().updateUserData();
  }

  Future _createMock(double distance, double duration, double gain, double loss) async {
    return createObject(
      RideSummariesCompanion.insert(
          distanceMetres: distance,
          durationSeconds: duration,
          elevationGainMetres: gain,
          elevationLossMetres: loss,
          averageSpeedKmh: (distance / duration) * 3.6),
    );
  }
}
