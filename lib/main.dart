import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasiku/core/app_state.dart';
import 'package:aplikasiku/core/router.dart';
import 'package:aplikasiku/core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const GymkuApp(),
    ),
  );
}

class GymkuApp extends StatefulWidget {
  const GymkuApp({super.key});
  @override
  State<GymkuApp> createState() => _GymkuAppState();
}

class _GymkuAppState extends State<GymkuApp> {
  late final GoRouter _router = buildRouter(context.read<AppState>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GYMKU',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
