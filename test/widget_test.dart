import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_game/main.dart';

void main() {
  testWidgets('offline profile screen validates and opens main menu', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FinanceQuestApp());
    await tester.pumpAndSettle();

    expect(find.text('Введите ваше имя'), findsOneWidget);
    expect(find.textContaining('Это офлайн-игра'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Artem Hikaru');
    await tester.pump();
    await tester.tap(find.widgetWithText(InkWell, 'Далее'));
    await tester.pumpAndSettle();

    expect(find.text('Artem Hikaru'), findsOneWidget);
    expect(find.text('FinQuest'), findsOneWidget);
    expect(find.text('Начать игру'), findsOneWidget);
    expect(find.text('Как играть?'), findsOneWidget);
    expect(find.text('Поддержка'), findsOneWidget);
    expect(find.text('Дуэль'), findsNothing);
    expect(find.textContaining('Рейтинг'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Размер интерфейса'), findsOneWidget);

    await tester.tap(find.text('Размер интерфейса'));
    await tester.pumpAndSettle();
    expect(find.text('Мельче'), findsOneWidget);
    expect(find.text('Крупнее'), findsOneWidget);

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'main menu starts an offline game with departments and random news',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'player_name': 'Игрок'});
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const FinanceQuestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Как играть?'));
      await tester.pumpAndSettle();

      expect(find.text('Как играть?'), findsOneWidget);
      expect(find.text('Цель'), findsOneWidget);
      expect(find.text('Радость'), findsOneWidget);
      expect(find.text('Рейтинг'), findsNothing);
      expect(find.text('Дуэль'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Начать игру'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сложный'));
      await tester.pumpAndSettle();

      expect(find.text('Ход 1 из 10'), findsOneWidget);
      expect(find.text('Бюджет'), findsOneWidget);
      expect(find.text('Инвестиции'), findsOneWidget);
      expect(find.text('Новости'), findsOneWidget);
      expect(find.text('Образование'), findsOneWidget);

      await tester.tap(find.text('Инвестиции').last);
      await tester.pumpAndSettle();
      expect(find.text('All-Market'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Вложить').first);
      await tester.pumpAndSettle();
      expect(find.text('Пополнить'), findsOneWidget);
      expect(find.text('Вывести'), findsOneWidget);
      expect(find.text('Пополнить все'), findsOneWidget);
      expect(find.text('Вывести все'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Новости').last);
      await tester.pumpAndSettle();

      expect(find.text('Финансовые\nНовости'), findsOneWidget);
    },
  );

  testWidgets('year requires mandatory expenses and yearly life choices', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'player_name': 'Игрок'});
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FinanceQuestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Начать игру'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сложный'));
    await tester.pumpAndSettle();

    expect(find.text('Минимальные расходы на жизнь за год'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Оплатить').first);
    await tester.pumpAndSettle();

    expect(find.text('Решение года'), findsOneWidget);
    expect(find.text('Отклонить'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      final decline = find.widgetWithText(FilledButton, 'Отклонить');
      if (decline.evaluate().isEmpty) {
        break;
      }
      await tester.tap(decline.first);
      await tester.pumpAndSettle();
    }

    expect(find.text('Основные решения приняты'), findsOneWidget);
    expect(find.text('Закончить ход'), findsOneWidget);
  });

  testWidgets('credit card and bank credit are separate mechanics', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'player_name': 'Игрок'});
    tester.view.physicalSize = const Size(430, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FinanceQuestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Начать игру'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сложный'));
    await tester.pumpAndSettle();

    expect(find.text('Кредитная карта'), findsOneWidget);
    final issueButton = find.widgetWithText(FilledButton, 'Выпустить').first;
    await tester.tap(issueButton);
    await tester.pumpAndSettle();
    expect(find.text('Кредитная карта без процентов'), findsOneWidget);

    expect(find.text('Зеленый банк'), findsWidgets);
    expect(find.text('Городской банк'), findsOneWidget);
    expect(find.text('Быстрые деньги'), findsOneWidget);

    await tester.tap(find.text('Быстрые деньги'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Взять кредит'));
    await tester.pumpAndSettle();

    expect(find.text('Кредит активен'), findsOneWidget);
    expect(find.text('Остаток долга'), findsOneWidget);
  });
}
