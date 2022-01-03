import 'package:driveme/dependency_injector.dart';
import 'package:driveme/models/car.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driveme/list/cars_list_bloc.dart';
import 'package:driveme/list/cars_list_page.dart';
import 'package:driveme/constants.dart';

import '../database/mock_car_data_provider.dart';
import '../database/mock_car_data_provider_error.dart';

void main() {
  setupLocator();
  var carsListBloc = locator<CarsListBloc>();

  testWidgets(
      "Cars are displayed with summary details, and selected car is highlighted in blue.",
      (WidgetTester tester) async {
    /// This will inject the test data.
    carsListBloc.injectDataProviderForTest(MockCarDataProvider());

    CarsList cars = await MockCarDataProvider().loadCars();
    cars.items.sort(carsListBloc.alphabetiseItemsByTitleIgnoreCases);

    await tester.pumpWidget(ListPageWrapper());
    await tester.pump(Duration.zero);

    /// ensure that the Carslist is in the view
    final carListKey = find.byKey(Key(CARS_LIST_KEY));
    expect(carListKey, findsOneWidget);

    _verifyAllCarDetails(cars.items, tester);

    carsListBloc.selectItem(1);

    WidgetPredicate widgetSelectedPredicate = (Widget widget) =>
        widget is Card && widget.color == Colors.blue.shade200;
    WidgetPredicate widgetUnselectedPredicate =
        (Widget widget) => widget is Card && widget.color == Colors.white;

    expect(find.byWidgetPredicate(widgetSelectedPredicate), findsOneWidget);
    expect(find.byWidgetPredicate(widgetUnselectedPredicate), findsNWidgets(5));
  });

  testWidgets('Proper error message is shown when an error occurred',
      (WidgetTester tester) async {
    carsListBloc.injectDataProviderForTest(MockCarDataProviderError());

    await tester.pumpWidget(ListPageWrapper());
    await tester.pump(Duration.zero);

    final errorFinder =
        find.text(ERROR_MESSAGE.replaceFirst(WILD_STRING, MOCK_ERROR_MESSAGE));
    expect(errorFinder, findsOneWidget);
  });

  testWidgets(
      'After encountering an error, and stream is updated, Widget is also updated.',
      (WidgetTester tester) async {
    carsListBloc.injectDataProviderForTest(MockCarDataProviderError());

    await tester.pumpWidget(ListPageWrapper());
    await tester.pump(Duration.zero);

    final errorFinder =
        find.text(ERROR_MESSAGE.replaceFirst(WILD_STRING, MOCK_ERROR_MESSAGE));
    final retryButtonFinder = find.text(RETRY_BUTTON);

    expect(errorFinder, findsOneWidget);
    expect(retryButtonFinder, findsOneWidget);

    carsListBloc.injectDataProviderForTest(MockCarDataProvider());
    await tester.tap(retryButtonFinder);

    await tester.pump(Duration.zero);

    CarsList cars = await MockCarDataProvider().loadCars();
    _verifyAllCarDetails(cars.items, tester);
  });
}

void _verifyAllCarDetails(List<Car> carsList, WidgetTester tester) async {
  for (var car in carsList) {
    final carTitleFinder = find.text(car.title);
    final carPricePerDayFinder = find.text(PRICE_PER_DAY_TEXT.replaceFirst(
        WILD_STRING, car.pricePerDay.toStringAsFixed(2)));
    await tester.ensureVisible(carTitleFinder);
    expect(carTitleFinder, findsOneWidget);
    await tester.ensureVisible(carPricePerDayFinder);
    expect(carPricePerDayFinder, findsOneWidget);
  }
}

class ListPageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ListPage(),
    );
  }
}
