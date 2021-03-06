import 'package:Blackout/data/database/database.dart';
import 'package:Blackout/data/repository/group_repository.dart';
import 'package:Blackout/data/repository/home_repository.dart';
import 'package:Blackout/data/repository/charge_repository.dart';
import 'package:Blackout/data/repository/product_repository.dart';
import 'package:Blackout/data/repository/user_repository.dart';
import 'package:Blackout/models/group.dart';
import 'package:Blackout/models/charge.dart';
import 'package:Blackout/models/product.dart';
import 'package:Blackout/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:optional/optional.dart';

import '../../blackout_test_base.dart';

void main() {
  Database _database;
  ChargeRepository chargeRepository;
  ProductRepository productRepository;
  GroupRepository groupRepository;
  HomeRepository homeRepository;
  UserRepository userRepository;

  setUp(() {
    _database = Database.forTesting(VmDatabase.memory());
    chargeRepository = _database.chargeRepository;
    productRepository = _database.productRepository;
    groupRepository = _database.groupRepository;
    homeRepository = _database.homeRepository;
    userRepository = _database.userRepository;
  });

  tearDown(() async {
    await _database.close();
  });

  test('(Save) Insert a new Product', () async {
    Product product = createDefaultProduct();

    await homeRepository.save(product.home);
    product = await productRepository.save(product, createDefaultUser());

    expect(product.id, isNotNull);
    expect(product.description, equals(DEFAULT_PRODUCT_DESCRIPTION));
    expect(product.ean, equals(DEFAULT_PRODUCT_EAN));
  });

  test('(Save) Update a Product', () async {
    User user = createDefaultUser();
    Product product = createDefaultProduct();
    await homeRepository.save(product.home);
    product = await productRepository.save(product, user);
    String productId = product.id;

    product.description = "test";
    await productRepository.save(product, user);
    product = await productRepository.findOneByProductId(productId, DEFAULT_HOME_ID);

    expect(product.id, equals(productId));
    expect(product.description, equals("test"));
    expect(product.ean, equals(DEFAULT_PRODUCT_EAN));
    expect(product.home.name, equals(DEFAULT_HOME_NAME));
    expect(product.home.id, equals(DEFAULT_HOME_ID));
  });

  test('(Drop) Throw exception if product to drop is no database object', () async {
    await productRepository.findAllByHomeId(DEFAULT_HOME_ID);
    Product product = createDefaultProduct();
    expect(() => productRepository.drop(product), throwsAssertionError);
  });

  test('(Drop) Delete a product', () async {
    Product product = createDefaultProduct();

    await homeRepository.save(product.home);
    product = await productRepository.save(product, createDefaultUser());

    var result = await productRepository.drop(product);
    expect(result, equals(1));

    List<Product> products = await productRepository.findAllByHomeId(DEFAULT_HOME_ID);
    expect(products.length, equals(0));
    expect(product.home.name, equals(DEFAULT_HOME_NAME));
    expect(product.home.id, equals(DEFAULT_HOME_ID));
  });

  test('(GetOneByProductId) Product contains charges if recurseCharges=true', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;

    await homeRepository.save(product.home);
    product = await productRepository.save(product, createDefaultUser());
    charge = await chargeRepository.save(charge, createDefaultUser());

    product = await productRepository.findOneByProductId(product.id, DEFAULT_HOME_ID);
    expect(product.id, isNotNull);
    expect(product.description, equals(DEFAULT_PRODUCT_DESCRIPTION));
    expect(product.ean, equals(DEFAULT_PRODUCT_EAN));
    expect(product.charges, hasLength(1));
    expect(product.charges[0].product.id, equals(product.id));
    expect(product.home.name, equals(DEFAULT_HOME_NAME));
    expect(product.home.id, equals(DEFAULT_HOME_ID));
  });

  test('(GetOneByProductId) Product does not contain charges if recurseCharges=false', () async {
    Product product = createDefaultProduct();
    Charge charge = createDefaultCharge();
    charge.product = product;

    await homeRepository.save(product.home);
    product = await productRepository.save(product, createDefaultUser());
    charge = await chargeRepository.save(charge, createDefaultUser());

    product = await productRepository.findOneByProductId(product.id, DEFAULT_HOME_ID, recurseCharges: false);
    expect(product.id, isNotNull);
    expect(product.description, equals(DEFAULT_PRODUCT_DESCRIPTION));
    expect(product.ean, equals(DEFAULT_PRODUCT_EAN));
    expect(product.charges, hasLength(0));
    expect(product.home.name, equals(DEFAULT_HOME_NAME));
    expect(product.home.id, equals(DEFAULT_HOME_ID));
  });

  test('(GetOneByProductId) Return null if product not found', () async {
    Product product = await productRepository.findOneByProductId("", DEFAULT_HOME_ID);

    expect(product, isNull);
  });

  test('(FindOneByProductId) Optional is empty if product not found', () async {
    Optional<Product> product = await productRepository.findOneByProductId("", DEFAULT_HOME_ID);

    expect(product.isEmpty, isTrue);
  });

  test('(FindOneByProductId) Optional is present if product found)', () async {
    Product product = createDefaultProduct();
    await homeRepository.save(product.home);
    product = await productRepository.save(createDefaultProduct(), createDefaultUser());

    Optional<Product> optionalProduct = await productRepository.findOneByProductId(product.id, DEFAULT_HOME_ID);

    expect(optionalProduct.isEmpty, isFalse);
  });

  test('(FindAll) find all products', () async {
    Product product = createDefaultProduct();
    await homeRepository.save(product.home);
    product = await productRepository.save(createDefaultProduct(), createDefaultUser());

    List<Product> products = await productRepository.findAllByHomeId(DEFAULT_HOME_ID, recurseCharges: false);
    expect(products.length, equals(1));
  });

  test('(GetAllByGroupId) Get all products by groupId if recurseGroup=true', () async {
    Group group = createDefaultGroup();
    Product product = createDefaultProduct();
    product.group = group;
    await homeRepository.save(product.home);
    group = await groupRepository.save(group, createDefaultUser());
    product = await productRepository.save(product, createDefaultUser());

    List<Product> products = await productRepository.findAllByGroupId(group.id, DEFAULT_HOME_ID);
    expect(products.length, equals(1));
    expect(products[0].group, isNotNull);
  });

  test('(GetAllByGroupId) Get all producty by groupId if recurseGroup=false', () async {
    Group group = createDefaultGroup();
    Product product = createDefaultProduct();
    product.group = group;
    await homeRepository.save(product.home);
    group = await groupRepository.save(group, createDefaultUser());
    product = await productRepository.save(product, createDefaultUser());

    List<Product> products = await productRepository.findAllByGroupId(group.id, DEFAULT_HOME_ID, recurseGroup: false);
    expect(products.length, equals(1));
    expect(products[0].group, isNull);
  });

  test('(findAllByHomeIdAndGroupIsNull) Find all products for group and without a group', () async {
    Group group = createDefaultGroup();
    Product product1 = createDefaultProduct();
    Product product2 = createDefaultProduct()..ean = "otherEan";
    product2.description = "product2";
    await homeRepository.save(product1.home);
    User user = await userRepository.save(createDefaultUser());
    group = await groupRepository.save(group, user);
    product1 = await productRepository.save(product1, user);
    product2 = await productRepository.save(product2, user);

    List<Product> products = await productRepository.findAllByHomeIdAndGroupIsNull(group.home.id);
    expect(products.length, equals(2));
    expect(products[0].description, DEFAULT_PRODUCT_DESCRIPTION);
    expect(products[1].description, "product2");
  });
}
