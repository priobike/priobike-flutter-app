import 'dart:math';

import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';
import 'package:priobike/gamification/hub/services/profile_service.dart';
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
    // Fill the database with mocks, if it is empty - TODO remove
    getAllObjects().then((result) {
      if (result.isEmpty) _createMocks();
    });
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

  Stream<List<RideSummary>> streamSummariesOfWeek(DateTime firstDay) {
    var lastDay = firstDay.add(const Duration(days: 7));
    return (select(rideSummaries)
          ..where((tbl) {
            var startTime = tbl.startTime;
            return startTime.isBetweenValues(firstDay, lastDay);
          }))
        .watch();
  }

  Stream<List<RideSummary>> streamSummariesOfMonth(DateTime firstDay) {
    var isDecember = firstDay.month == 12;
    var lastDay = DateTime(isDecember ? firstDay.year + 1 : firstDay.year, (isDecember ? 0 : firstDay.month + 1), 0);
    return (select(rideSummaries)
          ..where((tbl) {
            var startTime = tbl.startTime;
            return startTime.isBetweenValues(firstDay, lastDay);
          }))
        .watch();
  }

  void _createMocks() async {
    var today = DateTime.now();
    for (int i = 1; i < 30 * 6; i++) {
      var day = today.subtract(Duration(days: i));
      var rides = Random().nextInt(3) + 1;
      for (int e = 0; e < rides; e++) {
        await _createMock(day);
      }
    }
    getIt<UserProfileService>().updateUserData();
  }

  Future _createMock(DateTime start) async {
    var duration = Random().nextDouble() * 3600;
    var distance = duration * 5 * (1 + 0.3 * Random().nextDouble());
    var gain = Random().nextDouble() * 400;
    var loss = Random().nextDouble() * 400;
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
