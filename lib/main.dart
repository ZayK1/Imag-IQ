import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'screens/shell.dart';
import 'store/quiz_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const ImagIqApp());
}

class ImagIqApp extends StatelessWidget {
  const ImagIqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizStore(),
      child: MaterialApp(
        title: 'Imag-IQ',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const AppShell(),
      ),
    );
  }
}
