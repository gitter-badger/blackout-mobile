import 'package:Blackout/bloc/group/group_bloc.dart';
import 'package:Blackout/bloc/home/home_bloc.dart';
import 'package:Blackout/bloc/charge/charge_bloc.dart';
import 'package:Blackout/bloc/product/product_bloc.dart';
import 'package:Blackout/data/preferences/blackout_preferences.dart';
import 'package:Blackout/data/repository/group_repository.dart';
import 'package:Blackout/data/repository/change_repository.dart';
import 'package:Blackout/data/repository/home_repository.dart';
import 'package:Blackout/data/repository/charge_repository.dart';
import 'package:Blackout/data/repository/model_change_repository.dart';
import 'package:Blackout/data/repository/modification_repository.dart';
import 'package:Blackout/data/repository/product_repository.dart';
import 'package:Blackout/data/repository/user_repository.dart';
import 'package:Blackout/generated/l10n.dart';
import 'package:Blackout/generated/l10n_extension.dart';
import 'package:Blackout/models/group.dart';
import 'package:Blackout/models/change.dart';
import 'package:Blackout/models/home.dart';
import 'package:Blackout/models/charge.dart';
import 'package:Blackout/models/model_change.dart';
import 'package:Blackout/models/modification.dart';
import 'package:Blackout/models/product.dart';
import 'package:Blackout/models/sync.dart';
import 'package:Blackout/models/unit/unit.dart';
import 'package:Blackout/models/user.dart';
import 'package:Blackout/util/time_machine_extension.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:time_machine/time_machine.dart';

final Period DEFAULT_PERIOD_UNTIL_EXPIRATION = Period(weeks: 1);

final Period DEFAULT_PERIOD_UNTIL_NOTIFICATION = Period(days: 6);

final LocalDate NOW = LocalDate.today();

// Home
final String DEFAULT_HOME_ID = "defaultHomeId";
final String DEFAULT_HOME_NAME = "homeName";

Home createDefaultHome() {
  return Home(
    id: DEFAULT_HOME_ID,
    name: DEFAULT_HOME_NAME,
  );
}

// Group
final String DEFAULT_CATEGORY_ID = "groupId";
final String DEFAULT_CATEGORY_NAME = "groupName";
final String DEFAULT_CATEGORY_PLURAL_NAME = "groupPluralName";
final Period DEFAULT_CATEGORY_WARN_INTERVAL = periodFromISO8601String("P8D");

Group createDefaultGroup() {
  return Group(
    name: DEFAULT_CATEGORY_NAME,
    pluralName: DEFAULT_CATEGORY_PLURAL_NAME,
    warnInterval: DEFAULT_CATEGORY_WARN_INTERVAL,
    home: createDefaultHome(),
    unit: UnitEnum.unitless,
  );
}

// Product
final String DEFAULT_PRODUCT_ID = "productId";
final String DEFAULT_PRODUCT_EAN = "productEan";
final String DEFAULT_PRODUCT_DESCRIPTION = "productDescription";
final double DEFAULT_PRODUCT_REFILL_LIMIT = 2.0;

Product createDefaultProduct() {
  return Product(
    ean: DEFAULT_PRODUCT_EAN,
    description: DEFAULT_PRODUCT_DESCRIPTION,
    home: createDefaultHome(),
    unit: UnitEnum.unitless,
  );
}

// Charge
final String DEFAULT_ITEM_ID = "chargeid";
final LocalDate DEFAULT_ITEM_EXPIRATION_DATE = NOW.add(DEFAULT_PERIOD_UNTIL_EXPIRATION);
final LocalDate DEFAULT_ITEM_NOTIFICATION_DATE = NOW.add(DEFAULT_PERIOD_UNTIL_NOTIFICATION);

Charge createDefaultCharge() {
  return Charge(
    expirationDate: DEFAULT_ITEM_EXPIRATION_DATE,
    notificationDate: DEFAULT_ITEM_NOTIFICATION_DATE,
    product: createDefaultProduct(),
    home: createDefaultHome(),
  );
}

// Change
final String DEFAULT_CHANGE_ID = "changeId";
final String DEFAULT_CHANGE_OWNER = "changeOwner";
final double DEFAULT_CHANGE_VALUE = 1.0;
final LocalDate DEFAULT_CHANGE_CHANGE_DATE = NOW;

Change createDefaultChange() {
  return Change(
    user: createDefaultUser(),
    value: DEFAULT_CHANGE_VALUE,
    changeDate: DEFAULT_CHANGE_CHANGE_DATE,
    charge: createDefaultCharge(),
    home: createDefaultHome(),
  );
}

// User
final String DEFAULT_USER_ID = "userId";
final String DEFAULT_USER_NAME = "userName";

User createDefaultUser() {
  return User(
    id: DEFAULT_USER_ID,
    name: DEFAULT_USER_NAME,
  );
}

// DatabaseChangelog
final String DEFAULT_MODEL_CHANGE_ID = "databaseChangelogId";
final LocalDate DEFAULT_MODEL_CHANGE_MODIFICATION_DATE = DEFAULT_CHANGE_CHANGE_DATE;

ModelChange createDefaultModelChange(ModelChangeType modification, {Group group, Product product, Charge charge}) {
  return ModelChange(
    id: DEFAULT_MODEL_CHANGE_ID,
    user: createDefaultUser(),
    modificationDate: DEFAULT_MODEL_CHANGE_MODIFICATION_DATE,
    modification: modification,
    home: createDefaultHome(),
    groupId: group != null ? group.id : null,
    productId: product != null ? product.id : null,
    chargeId: charge != null ? charge.id : null,
  );
}

// Sync
final LocalDate SYNC_SYNCHRONIZATION_DATE = NOW;

Sync createDefaultSync() {
  return Sync(
    synchronizationDate: SYNC_SYNCHRONIZATION_DATE,
    user: createDefaultUser(),
    home: createDefaultHome(),
  );
}

// Modification
final String DEFAULT_MODIFICATION_ID = "modificationId";
final String DEFAULT_MODIFICATION_FIELD_NAME = "fieldName";
final String DEFAULT_MODIFICATION_FROM = "from";
final String DEFAULT_MODIFICATION_TO = "to";

Modification createDefaultModification() {
  return Modification(
    id: DEFAULT_MODIFICATION_ID,
    fieldName: DEFAULT_MODIFICATION_FIELD_NAME,
    from: DEFAULT_MODIFICATION_FROM,
    to: DEFAULT_MODIFICATION_TO,
    home: createDefaultHome(),
    modelChange: createDefaultModelChange(ModelChangeType.create, group: createDefaultGroup()..id = DEFAULT_CATEGORY_ID),
  );
}

typedef Widget WidgetBuilder(BuildContext context);

class WidgetBuilderWidget extends StatelessWidget {
  final WidgetBuilder builder;
  final ContextFactory contextFactory;

  WidgetBuilderWidget({Key key, this.builder, this.contextFactory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (contextFactory != null) {
      contextFactory(context);
    }
    return builder(context);
  }
}

MaterialApp wrapMaterial({Widget widget, WidgetBuilder builder, ContextFactory contextCallback}) {
  assert((widget != null && builder == null) || (widget == null && builder != null));
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Blackout",
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    localeResolutionCallback: S.delegate.resolution(fallback: Locale("en", "")),
    home: Scaffold(
      body: widget ??
          WidgetBuilderWidget(
            builder: builder,
            contextFactory: contextCallback,
          ),
    ),
  );
}

typedef void ContextFactory(BuildContext buildContext);

Future<BuildContext> DEFAULT_BUILD_CONTEXT(WidgetTester tester) async {
  BuildContext context;
  await tester.pumpWidget(
    _TestApp(
      factory: (_context) {
        context = _context;
      },
    ),
  );
  await tester.pumpAndSettle();

  return context;
}

class _TestApp extends StatelessWidget {
  final ContextFactory factory;

  _TestApp({Key key, this.factory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Blackout",
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: S.delegate.resolution(fallback: Locale("en", "")),
      home: _Home(
        factory: factory,
      ),
    );
  }
}

class _Home extends StatefulWidget {
  final ContextFactory factory;

  _Home({Key key, this.factory}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  @override
  Widget build(BuildContext context) {
    widget.factory(context);
    return Container();
  }
}

class BlackoutPreferencesMock extends Mock implements BlackoutPreferences {}

class GroupBlocMock extends MockBloc<GroupEvent, GroupState> implements GroupBloc {}

class GroupRepositoryMock extends Mock implements GroupRepository {}

class ChangeRepositoryMock extends Mock implements ChangeRepository {}

class HomeBlocMock extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class HomeRepositoryMock extends Mock implements HomeRepository {}

class ChargeBlocMock extends MockBloc<ChargeEvent, ChargeState> implements ChargeBloc {}

class ChargeRepositoryMock extends Mock implements ChargeRepository {}

class ModelChangeRepositoryMock extends Mock implements ModelChangeRepository {}

class ModificationRepositoryMock extends Mock implements ModificationRepository {}

class ProductBlocMock extends MockBloc<ProductEvent, ProductState> implements ProductBloc {}

class ProductRepositoryMock extends Mock implements ProductRepository {}

class UserRepositoryMock extends Mock implements UserRepository {}
