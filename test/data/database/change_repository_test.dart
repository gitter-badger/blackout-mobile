import 'package:Blackout/data/database/database.dart';
import 'package:Blackout/data/repository/change_repository.dart';
import 'package:Blackout/data/repository/home_repository.dart';
import 'package:Blackout/data/repository/charge_repository.dart';
import 'package:Blackout/data/repository/product_repository.dart';
import 'package:Blackout/data/repository/user_repository.dart';
import 'package:Blackout/models/change.dart';
import 'package:Blackout/models/charge.dart';
import 'package:Blackout/models/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:optional/optional.dart';
import 'package:time_machine/time_machine.dart';

import '../../blackout_test_base.dart';

void main() {
  Database _database;
  ProductRepository productRepository;
  ChargeRepository chargeRepository;
  ChangeRepository changeRepository;
  UserRepository userRepository;
  HomeRepository homeRepository;

  setUp(() {
    _database = Database.forTesting(VmDatabase.memory());
    productRepository = _database.productRepository;
    chargeRepository = _database.chargeRepository;
    changeRepository = _database.changeRepository;
    userRepository = _database.userRepository;
    homeRepository = _database.homeRepository;
  });

  tearDown(() async {
    await _database.close();
  });

  test('(Save) Insert a new change', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;

    await homeRepository.save(change.home);
    await userRepository.save(change.user);
    await productRepository.save(product, createDefaultUser());
    await chargeRepository.save(charge, createDefaultUser());
    change = await changeRepository.save(change);

    expect(change.id, isNotNull);
    expect(change.user.name, equals(DEFAULT_USER_NAME));
    expect(change.value, equals(DEFAULT_CHANGE_VALUE));
    expect(change.home.name, equals(DEFAULT_HOME_NAME));
    expect(change.home.id, equals(DEFAULT_HOME_ID));
  });

  test('(Save) Update a change', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;
    change.user.name = "test";

    await homeRepository.save(change.home);
    await productRepository.save(product, createDefaultUser());
    await chargeRepository.save(charge, createDefaultUser());
    await userRepository.save(change.user);
    change = await changeRepository.save(change);
    String changeId = change.id;

    await changeRepository.save(change);
    change = await changeRepository.findOneByChangeId(changeId, DEFAULT_HOME_ID);

    expect(change.id, equals(changeId));
    expect(change.user.name, equals("test"));
    expect(change.value, equals(DEFAULT_CHANGE_VALUE));
    expect(change.home.name, equals(DEFAULT_HOME_NAME));
    expect(change.home.id, equals(DEFAULT_HOME_ID));
  });

  test('(Drop) Throw exception if change to drop is no database object', () async {
    await changeRepository.findAllByChargeId(DEFAULT_ITEM_ID, DEFAULT_HOME_ID, recurseCharge: false);
    Change change = createDefaultChange();
    expect(() => changeRepository.drop(change), throwsAssertionError);
  });

  test('(Drop) Delete a change', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;

    await homeRepository.save(change.home);
    await productRepository.save(product, createDefaultUser());
    await chargeRepository.save(charge, createDefaultUser());
    change = await changeRepository.save(change);

    var result = await changeRepository.drop(change);
    expect(result, equals(1));

    List<Change> changes = await changeRepository.findAllByChargeId(DEFAULT_ITEM_ID, DEFAULT_HOME_ID, recurseCharge: false);
    expect(changes.length, equals(0));
  });

  test('(GetOneByChangeId) Get one change by changeId', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;

    await homeRepository.save(change.home);
    await productRepository.save(product, createDefaultUser());
    await chargeRepository.save(charge, createDefaultUser());
    await userRepository.save(change.user);
    change = await changeRepository.save(change);

    change = await changeRepository.findOneByChangeId(change.id, DEFAULT_HOME_ID);
    expect(change.id, isNotNull);
    expect(change.user.name, equals(DEFAULT_USER_NAME));
    expect(change.value, equals(DEFAULT_CHANGE_VALUE));
    expect(change.home.name, equals(DEFAULT_HOME_NAME));
    expect(change.home.id, equals(DEFAULT_HOME_ID));
  });

  test('(GetOneByChangeId) Return null if change not found', () async {
    Change change = await changeRepository.findOneByChangeId("", DEFAULT_HOME_ID);

    expect(change, isNull);
  });

  test('(FindOneByChangeId) Optional is empty if change not found', () async {
    Optional<Change> change = await changeRepository.findOneByChangeId("", DEFAULT_HOME_ID);

    expect(change.isEmpty, isTrue);
  });

  test('(FindOneByChangeId) Optional is present if change found)', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;

    await homeRepository.save(change.home);
    await productRepository.save(product, createDefaultUser());
    await chargeRepository.save(charge, createDefaultUser());
    change = await changeRepository.save(change);

    Optional<Change> optionalChange = await changeRepository.findOneByChangeId(change.id, DEFAULT_HOME_ID);

    expect(optionalChange.isEmpty, isFalse);
  });

  test('(FindAll) find all changes', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;

    await homeRepository.save(change.home);
    await productRepository.save(product, createDefaultUser());
    await chargeRepository.save(charge, createDefaultUser());
    change = await changeRepository.save(change);

    List<Change> changes = await changeRepository.findAllByHomeId(DEFAULT_HOME_ID);
    expect(changes.length, equals(1));
  });

  test('(GetAllByChargeId) Get all changes by chargeId if recurseCharge=true', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;

    await homeRepository.save(change.home);
    await productRepository.save(product, createDefaultUser());
    charge = await chargeRepository.save(charge, createDefaultUser());
    change = await changeRepository.save(change);

    List<Change> changes = await changeRepository.findAllByChargeId(charge.id, DEFAULT_HOME_ID);
    expect(changes.length, equals(1));
    expect(changes[0].charge, isNotNull);
  });

  test('(GetAllByChargeId) Get all changes by chargeId if recurseCharge=false', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;

    await homeRepository.save(change.home);
    await productRepository.save(product, createDefaultUser());
    charge = await chargeRepository.save(charge, createDefaultUser());
    change = await changeRepository.save(change);

    List<Change> changes = await changeRepository.findAllByChargeId(charge.id, DEFAULT_HOME_ID, recurseCharge: false);
    expect(changes.length, equals(1));
    expect(changes[0].charge, isNull);
  });

  test('(FindAllByChangeDateAfter) Find all changes and expect zero', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;

    await homeRepository.save(change.home);
    await productRepository.save(product, createDefaultUser());
    await chargeRepository.save(charge, createDefaultUser());
    await changeRepository.save(change);

    List<Change> changes = await changeRepository.findAllByChangeDateAfterAndHomeId(LocalDate.today(), DEFAULT_HOME_ID);
    expect(changes.length, equals(0));
  });

  test('(FindAllByChangeDateAfter) Find all changes and expect one', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;
    Change change = createDefaultChange();
    change.charge = charge;

    await homeRepository.save(change.home);
    await productRepository.save(product, createDefaultUser());
    await chargeRepository.save(charge, createDefaultUser());
    await changeRepository.save(change);

    List<Change> changes = await changeRepository.findAllByChangeDateAfterAndHomeId(LocalDate.today().subtractYears(2020), DEFAULT_HOME_ID);
    expect(changes.length, equals(1));
  });
}
