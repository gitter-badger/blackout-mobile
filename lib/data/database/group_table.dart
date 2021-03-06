import 'package:moor/moor.dart';

@DataClassName("GroupEntry")
class GroupTable extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().customConstraint('unique')();

  TextColumn get pluralName => text().nullable().customConstraint('unique')();

  TextColumn get warnInterval => text().nullable()();

  TextColumn get homeId => text().customConstraint('references Home(id)')();

  RealColumn get refillLimit => real().nullable()();

  IntColumn get unit => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
