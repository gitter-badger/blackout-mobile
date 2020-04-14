import 'package:Blackout/data/database/database.dart';
import 'package:Blackout/models/category.dart';
import 'package:Blackout/models/displayable.dart';
import 'package:Blackout/models/home.dart';
import 'package:Blackout/models/item.dart';
import 'package:Blackout/models/unit.dart';
import 'package:moor/moor.dart';
import 'package:time_machine/time_machine.dart';

class Product extends Displayable {
  String id;
  String ean;
  Category category;
  String description;
  List<Item> items = [];
  Home home;
  double refillLimit;

  double get amount => items.map((i) => i.amount).reduce((a, b) => a + b);

  String get scaledAmount {
    if (category != null) {
      return category.unit.toScientific(amount).toString();
    }

    return unit.toScientific(amount).toString();
  }

  @override
  String get title => description;

  @override
  bool get expiredOrNotification {
    bool isExpired = false;
    if (category?.warnInterval != null) {
      isExpired = items.where((item) => item.expirationDate != null).any(
          (item) =>
              item.expirationDate.subtract(category.warnInterval) <
              LocalDateTime.now());
    }

    return isExpired ||
        items
            .where((item) => item.notificationDate != null)
            .any((item) => item.notificationDate <= LocalDateTime.now());
  }

  @override
  bool get tooFewAvailable {
    if (category == null && refillLimit != null) {
      return amount <= refillLimit;
    }

    return false;
  }

  Product(
      {this.id,
      this.ean,
      @required this.description,
      this.category,
      this.items,
      this.refillLimit,
      BaseUnit unit,
      @required this.home})
      : super(unit);

  factory Product.fromEntry(ProductEntry entry, Home home,
      {Category category, List<Item> items}) {
    return Product(
      id: entry.id,
      ean: entry.ean,
      description: entry.description,
      refillLimit: entry.refillLimit,
      unit:
          entry.unit == null ? null : baseUnitFromUnit(Unit.values[entry.unit]),
      category: category,
      items: items,
      home: home,
    );
  }

  ProductTableCompanion toCompanion() {
    return ProductTableCompanion(
      id: Value(id),
      ean: Value(ean),
      description: Value(description),
      refillLimit: Value(refillLimit),
      unit:
          unit != null ? Value(Unit.values.indexOf(unit.unit)) : Value.absent(),
      categoryId: category != null ? Value(category.id) : Value(null),
      homeId: Value(home.id),
    );
  }

  @override
  bool isValid() {
    return description != null && description != "";
  }
}
