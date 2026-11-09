// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aplikasiku/core/app_state.dart';
import 'package:aplikasiku/core/models.dart';
import 'package:aplikasiku/main.dart';

void main() {
  testWidgets('app starts on the welcome screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(312, 676);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const GymkuApp(),
      ),
    );

    expect(find.text('GYMKU'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Registrasi'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('welcome-panel'))).height,
      closeTo(676 * 0.39, 1),
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('welcome buttons open login and registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const GymkuApp(),
      ),
    );

    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.ensureVisible(find.text('Daftar sekarang'));
    await tester.tap(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar untuk melanjutkan'), findsOneWidget);
  });

  testWidgets('forgot password button explains reset availability', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const GymkuApp(),
      ),
    );

    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lupa Password?'));
    await tester.tap(find.text('Lupa Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Mengerti'), findsOneWidget);
  });

  testWidgets('admin activity log opens and renders its entries', (
    WidgetTester tester,
  ) async {
    final app = AppState();
    expect(app.loginLocalForTest('admin', 'admin123'), isNull);
    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => app, child: const GymkuApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keamanan').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Log aktivitas'));
    await tester.pumpAndSettle();

    expect(find.text('Semua tindakan admin dan sistem'), findsOneWidget);
    expect(find.text('Admin mengubah harga paket'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('freeze and unfreeze only change membership after admin approval', () {
    final app = AppState();
    expect(app.loginLocalForTest('Naufal Badu', 'Gymku123'), isNull);
    final member = app.currentUser!;

    expect(app.requestFreezeMembership(today(), 7, 'Bepergian'), isNull);
    final freezeRequest = app.pendingFreezeRequest!;
    expect(freezeRequest.type, FreezeRequestType.freeze);
    expect(app.membership!.currentFreeze, isNull);
    expect(
      app.decideFreezeRequest(freezeRequest.id, true),
      'Hanya admin yang dapat memproses permintaan',
    );

    app.logout();
    expect(app.loginLocalForTest('admin', 'admin123'), isNull);
    expect(app.decideFreezeRequest(freezeRequest.id, true), isNull);
    expect(app.statusOf(member), MemberStatus.frozen);

    app.logout();
    expect(app.loginLocalForTest('Naufal Badu', 'Gymku123'), isNull);
    expect(app.requestUnfreezeMembership(), isNull);
    final unfreezeRequest = app.pendingFreezeRequest!;
    expect(unfreezeRequest.type, FreezeRequestType.unfreeze);
    expect(app.membership!.isFrozen, isTrue);

    app.logout();
    expect(app.loginLocalForTest('admin', 'admin123'), isNull);
    expect(app.decideFreezeRequest(unfreezeRequest.id, true), isNull);

    app.logout();
    expect(app.loginLocalForTest('Naufal Badu', 'Gymku123'), isNull);
    expect(app.membership!.currentFreeze, isNull);

    expect(app.requestFreezeMembership(today(), 7, 'Urusan pribadi'), isNull);
    final rejectedRequest = app.pendingFreezeRequest!;
    app.logout();
    expect(app.loginLocalForTest('admin', 'admin123'), isNull);
    expect(app.decideFreezeRequest(rejectedRequest.id, false), isNull);

    app.logout();
    expect(app.loginLocalForTest('Naufal Badu', 'Gymku123'), isNull);
    expect(app.membership!.currentFreeze, isNull);
    expect(rejectedRequest.status, 'Ditolak');
  });
}
