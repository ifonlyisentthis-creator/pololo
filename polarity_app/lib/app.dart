import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polarity/core/theme.dart';
import 'package:polarity/features/menu/screens/menu_screen.dart';
import 'package:polarity/providers/providers.dart';

class PolarityApp extends ConsumerWidget {
  const PolarityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkThemeProvider);

    return MaterialApp(
      title: 'Polarity',
      debugShowCheckedModeBanner: false,
      theme: isDark ? PolarityTheme.dark() : PolarityTheme.light(),
      home: const MenuScreen(),
    );
  }
}
