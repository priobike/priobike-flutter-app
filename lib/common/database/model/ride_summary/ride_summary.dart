import 'package:drift/drift.dart';
import 'package:priobike/common/database/database.dart';
import 'package:priobike/common/database/database_dao.dart';

part 'ride_summary.g.dart';

@DataClassName('RideSummary')
class RideSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get distance => real()();
}

@DriftAccessor(tables: [RideSummaries])
class RideSummaryDao extends DatabaseDao<RideSummary> with _$RideSummaryDaoMixin {
  RideSummaryDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  @override
  TableInfo<Table, dynamic> get table => rideSummaries;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(rideSummaries)..where((tbl) => (tbl as $RideSummariesTable).id.equals(value)));
  }
}
