import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/statistics/models/summary.dart';

part 'ride_summary.g.dart';

/// Table which holds ride summary objects, which contain relevant information of rides which the user has done.
@DataClassName('RideSummary')
class RideSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shortcutId => text().nullable()();
  RealColumn get distanceMetres => real()();
  RealColumn get durationSeconds => real()();
  RealColumn get elevationGainMetres => real()();
  RealColumn get elevationLossMetres => real()();
  RealColumn get averageSpeedKmh => real()();
  DateTimeColumn get startTime => dateTime()();
}

@DriftAccessor(tables: [RideSummaries])
class RideSummaryDao extends DatabaseDao<RideSummary> with _$RideSummaryDaoMixin {
  /// The logger for this service.
  final logger = Logger("RideDAO");

  RideSummaryDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  @override
  TableInfo<Table, dynamic> get table => rideSummaries;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(rideSummaries)..where((tbl) => (tbl as $RideSummariesTable).id.equals(value)));
  }

  /// Store ride summary in database.
  void createObjectFromSummary(Summary summary, DateTime startTime, String? shortcutId) {
    createObject(
      RideSummariesCompanion.insert(
        distanceMetres: summary.distanceMeters,
        durationSeconds: summary.durationSeconds,
        elevationGainMetres: summary.elevationGain,
        elevationLossMetres: summary.elevationLoss,
        averageSpeedKmh: summary.averageSpeedKmH,
        startTime: startTime,
        shortcutId: Value(shortcutId),
      ),
    );
  }

  /// Returns stream of rides which started in a given time intervall, ordered by the start time.
  Stream<List<RideSummary>> streamRidesInInterval(DateTime firstTimeStamp, DateTime lastTimeStamp) {
    return (select(rideSummaries)
          ..where((tbl) {
            var startTime = tbl.startTime;
            return startTime.isBetweenValues(firstTimeStamp, lastTimeStamp);
          })
          ..orderBy(
            [(t) => OrderingTerm(expression: t.startTime)],
          ))
        .watch();
  }

  /// Returns stream of rides on a specific day.
  Stream<List<RideSummary>> streamRidesOnDay(DateTime day) {
    var firstDay = DateTime(day.year, day.month, day.day);
    var lastDay = firstDay.add(const Duration(days: 1));
    return streamRidesInInterval(firstDay, lastDay);
  }

  /// Returns stream of rides started in a week starting from a given day.
  Stream<List<RideSummary>> streamRidesInWeek(DateTime startDay) {
    var firstDay = DateTime(startDay.year, startDay.month, startDay.day);
    var lastDay = firstDay.add(const Duration(days: 7));
    return streamRidesInInterval(firstDay, lastDay);
  }

  /// Returns stream of rides started in a given month.
  Stream<List<RideSummary>> streamRidesInMonth(int year, int month) {
    var isDecember = month == 12;
    var firstDay = DateTime(year, month, 1);
    var lastDay = DateTime(isDecember ? year + 1 : year, (isDecember ? 0 : month + 1), 0);
    return streamRidesInInterval(firstDay, lastDay);
  }

  /// Returns rides which started in a given time intervall, ordered by the start time.
  Future<List<RideSummary>> getRidesInInterval(DateTime firstTimeStamp, DateTime lastTimeStamp) {
    return (select(rideSummaries)
          ..where((tbl) {
            var startTime = tbl.startTime;
            return startTime.isBetweenValues(firstTimeStamp, lastTimeStamp);
          })
          ..orderBy(
            [(t) => OrderingTerm(expression: t.startTime)],
          ))
        .get();
  }

  /// Returns rides on a specific day.
  Future<List<RideSummary>> getRidesOnDay(DateTime day) {
    var firstDay = DateTime(day.year, day.month, day.day);
    var lastDay = firstDay.add(const Duration(days: 1));
    return getRidesInInterval(firstDay, lastDay);
  }

  /// Returns rides started in a week starting from a given day.
  Future<List<RideSummary>> getRidesInWeek(DateTime startDay) {
    var firstDay = DateTime(startDay.year, startDay.month, startDay.day);
    var lastDay = firstDay.add(const Duration(days: 7));
    return getRidesInInterval(firstDay, lastDay);
  }

  /// Returns rides started in a given month.
  Future<List<RideSummary>> getRidesInMonth(int year, int month) {
    var isDecember = month == 12;
    var firstDay = DateTime(year, month, 1);
    var lastDay = DateTime(isDecember ? year + 1 : year, (isDecember ? 0 : month + 1), 0);
    return getRidesInInterval(firstDay, lastDay);
  }
}