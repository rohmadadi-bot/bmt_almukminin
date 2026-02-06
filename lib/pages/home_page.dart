import 'package:flutter/material.dart';

// Import Keanggotaan
import 'keanggotaan/daftar_anggota_page.dart';

// Import Fasilitas
import 'fasilitas/tabungan/tabungan_page.dart';
import 'fasilitas/jual_beli/jual_beli_page.dart';
import 'fasilitas/usaha_bersama/usaha_bersama_page.dart';
import 'fasilitas/bagi_hasil/bagi_hasil_page.dart';
import 'fasilitas/pinjaman_lunak/pinjaman_lunak_page.dart';

// Import Manajemen / Laporan
import 'laporan/backup_restore_page.dart';

// Import Fitur Manajemen BMT
import 'manajemen/permodalan_bmt_page.dart';
// Pastikan file pengeluaran_bmt_page.dart ada di folder yang sesuai (misal: pages/manajemen/)
import 'manajemen/pengeluaran_bmt_page.dart';
import 'manajemen/cash_flow_bmt_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard BMT Al Mukminin'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KEANGGOTAAN
            _buildSectionTitle('Manajemen Keanggotaan'),
            _buildMenuGrid(context, [
              _MenuData(Icons.groups_rounded, 'Daftar Anggota', Colors.blue),
            ]),

            const SizedBox(height: 24),

            // 2. FASILITAS
            _buildSectionTitle('Fasilitas (Transaksi)'),
            _buildMenuGrid(context, [
              _MenuData(Icons.account_balance_wallet, 'Tabungan (Wadiah)',
                  Colors.green),
              _MenuData(
                  Icons.shopping_bag, 'Jual Beli (Murabahah)', Colors.green),
              _MenuData(
                  Icons.analytics, 'Bagi Hasil (Mudharabah)', Colors.green),
              _MenuData(Icons.handshake_rounded, 'Usaha Bersama (Musyarakah)',
                  Colors.green),
              _MenuData(Icons.volunteer_activism,
                  'Pinjaman Lunak (Qardhul Hasan)', Colors.green),
            ]),

            const SizedBox(height: 24),

            // 3. MANAJEMEN BMT
            _buildSectionTitle('Manajemen BMT'),
            _buildMenuGrid(context, [
              _MenuData(Icons.account_balance, 'Permodalan BMT', Colors.teal),
              _MenuData(Icons.money_off, 'Pengeluaran BMT', Colors.redAccent),
              _MenuData(Icons.timeline, 'Cash Flow BMT', Colors.purple),
            ]),

            const SizedBox(height: 24),

            // 4. LAPORAN & DATA
            _buildSectionTitle('Laporan & Data'),
            _buildMenuGrid(context, [
              _MenuData(Icons.assignment, 'Laporan Bulanan', Colors.orange),
              _MenuData(Icons.settings_backup_restore, 'Backup Data',
                  Colors.blueGrey),
            ]),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, List<_MenuData> menus) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _handleNavigation(context, menu.title),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(menu.icon, size: 36, color: menu.color),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    menu.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleNavigation(BuildContext context, String menuTitle) {
    Widget? targetPage;

    switch (menuTitle) {
      // Keanggotaan
      case 'Daftar Anggota':
        targetPage = const DaftarAnggotaPage();
        break;

      // Fasilitas
      case 'Tabungan (Wadiah)':
        targetPage = const TabunganPage();
        break;
      case 'Jual Beli (Murabahah)':
        targetPage = const JualBeliPage();
        break;
      case 'Usaha Bersama (Musyarakah)':
        targetPage = const UsahaBersamaPage();
        break;
      case 'Bagi Hasil (Mudharabah)':
        targetPage = const BagiHasilPage();
        break;
      case 'Pinjaman Lunak (Qardhul Hasan)':
        targetPage = const PinjamanLunakPage();
        break;

      // Manajemen BMT
      case 'Permodalan BMT':
        targetPage = const PermodalanBmtPage();
        break;
      case 'Pengeluaran BMT':
        targetPage = const PengeluaranBmtPage();
        break;
      case 'Cash Flow BMT':
        targetPage = const CashFlowBmtPage();
        break;

      // Laporan & Data
      case 'Laporan Bulanan':
        // targetPage = const LaporanBulananPage(); // Belum ada
        break;
      case 'Backup Data':
        targetPage = const BackupRestorePage();
        break;
    }

    if (targetPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menu "$menuTitle" sedang disiapkan'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

class _MenuData {
  final IconData icon;
  final String title;
  final Color color;

  _MenuData(this.icon, this.title, this.color);
}
