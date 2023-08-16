import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';
import 'package:priobike/gamification/hub/services/game_service.dart';
import 'package:priobike/main.dart';
import 'package:priobike/statistics/models/summary.dart';

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
  DateTimeColumn get startTime => dateTime()();
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

  /// Store ride summary in database.
  void createObjectFromSummary(Summary summary, DateTime startTime) {
    createObject(
      RideSummariesCompanion.insert(
        distanceMetres: summary.distanceMeters,
        durationSeconds: summary.durationSeconds,
        elevationGainMetres: summary.elevationGain,
        elevationLossMetres: summary.elevationLoss,
        averageSpeedKmh: summary.averageSpeedKmH,
        startTime: startTime,
      ),
    );
  }

  void _createMocks() async {
    await _createMock(1208, 400, 12, 14, DateTime(2023, 8, 12));
    await _createMock(3124, 621, 64, 120, DateTime(2023, 8, 10));
    await _createMock(14029, 2354, 312, 122, DateTime(2023, 8, 9));
    getIt<UserProfileService>().updateUserData();
  }

  Future _createMock(double distance, double duration, double gain, double loss, DateTime start) async {
    return createObject(
      RideSummariesCompanion.insert(
          distanceMetres: distance,
          durationSeconds: duration,
          elevationGainMetres: gain,
          elevationLossMetres: loss,
          startTime: start,
          averageSpeedKmh: (distance / duration) * 3.6),
    );
  }
}
