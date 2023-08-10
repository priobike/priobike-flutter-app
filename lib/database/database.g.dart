// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TestObjectsTable extends TestObjects
    with TableInfo<$TestObjectsTable, TestObject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestObjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, number];
  @override
  String get aliasedName => _alias ?? 'test_objects';
  @override
  String get actualTableName => 'test_objects';
  @override
  VerificationContext validateIntegrity(Insertable<TestObject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TestObject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TestObject(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number'])!,
    );
  }

  @override
  $TestObjectsTable createAlias(String alias) {
    return $TestObjectsTable(attachedDatabase, alias);
  }
}

class TestObject extends DataClass implements Insertable<TestObject> {
  final int id;
  final int number;
  const TestObject({required this.id, required this.number});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['number'] = Variable<int>(number);
    return map;
  }

  TestObjectsCompanion toCompanion(bool nullToAbsent) {
    return TestObjectsCompanion(
      id: Value(id),
      number: Value(number),
    );
  }

  factory TestObject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TestObject(
      id: serializer.fromJson<int>(json['id']),
      number: serializer.fromJson<int>(json['number']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'number': serializer.toJson<int>(number),
    };
  }

  TestObject copyWith({int? id, int? number}) => TestObject(
        id: id ?? this.id,
        number: number ?? this.number,
      );
  @override
  String toString() {
    return (StringBuffer('TestObject(')
          ..write('id: $id, ')
          ..write('number: $number')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, number);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TestObject &&
          other.id == this.id &&
          other.number == this.number);
}

class TestObjectsCompanion extends UpdateCompanion<TestObject> {
  final Value<int> id;
  final Value<int> number;
  const TestObjectsCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
  });
  TestObjectsCompanion.insert({
    this.id = const Value.absent(),
    required int number,
  }) : number = Value(number);
  static Insertable<TestObject> custom({
    Expression<int>? id,
    Expression<int>? number,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
    });
  }

  TestObjectsCompanion copyWith({Value<int>? id, Value<int>? number}) {
    return TestObjectsCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestObjectsCompanion(')
          ..write('id: $id, ')
          ..write('number: $number')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $TestObjectsTable testObjects = $TestObjectsTable(this);
  late final TestDao testDao = TestDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [testObjects];
}
