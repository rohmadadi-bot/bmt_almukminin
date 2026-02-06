import 'package:flutter/material.dart';
// 1. IMPORT PACKAGE UNTUK FORMAT TANGGAL & BAHASA
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/login_page.dart';

// 2. UBAH MAIN MENJADI ASYNC
void main() async {
  // Memastikan plugin Flutter terinisialisasi sebelum aplikasi berjalan
  WidgetsFlutterBinding.ensureInitialized();

  // 3. INISIALISASI DATA FORMAT TANGGAL INDONESIA
  // Ini wajib dilakukan untuk mencegah error "LocaleDataException"
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMT Al Mukminin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),

      // 4. TAMBAHKAN DUKUNGAN LOKALISASI (BAHASA)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Set Bahasa Indonesia sebagai default
      ],

      home: const LoginPage(),
    );
  }
}
