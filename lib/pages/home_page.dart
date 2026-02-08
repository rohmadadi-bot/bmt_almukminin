import 'package:flutter/material.dart';

// --- IMPORT HALAMAN LAIN ---
// Pastikan file-file ini ada di folder project Anda
import 'keanggotaan/daftar_anggota_page.dart';
import 'fasilitas/tabungan/tabungan_page.dart';
import 'fasilitas/jual_beli/jual_beli_page.dart';
import 'fasilitas/usaha_bersama/usaha_bersama_page.dart';
import 'fasilitas/bagi_hasil/bagi_hasil_page.dart';
import 'fasilitas/pinjaman_lunak/pinjaman_lunak_page.dart';
import 'laporan/backup_restore_page.dart';
import 'manajemen/permodalan_bmt_page.dart';
import 'manajemen/pengeluaran_bmt_page.dart';
import 'manajemen/cash_flow_bmt_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Tema
    const Color primaryColor = Color(0xFF2E7D32); // Hijau Tua
    const Color accentColor =
        Color(0xFF66BB6A); // Hijau Muda (Sekarang Terpakai)

    return Scaffold(
      // Container pembungkus untuk membuat background gradasi
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, accentColor], // Efek gradasi halus
          ),
        ),
        child: SafeArea(
          bottom:
              false, // Membiarkan panel putih menyentuh bagian paling bawah layar
          child: Column(
            children: [
              // --- 1. HEADER SECTION (SAPAAN & LOGOUT) ---
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Assalamualaikum,",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Admin BMT",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // Tombol Logout
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white),
                        tooltip: "Keluar",
                        onPressed: () {
                          // Navigasi Logout (Kembali ke halaman Login)
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/', (route) => false);
                        },
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 10), // Jarak header ke panel menu

              // --- 2. BODY SECTION (PANEL PUTIH MELENGKUNG) ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA), // Warna putih keabuan (Soft)
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION 1: KEANGGOTAAN
                          _buildSectionHeader(
                              "Keanggotaan", Icons.people_outline),
                          _buildMenuGrid(context, [
                            _MenuData(Icons.groups_rounded, 'Daftar Anggota',
                                Colors.blue),
                          ]),

                          const SizedBox(height: 25),

                          // SECTION 2: FASILITAS
                          _buildSectionHeader("Fasilitas & Transaksi",
                              Icons.account_balance_wallet_outlined),
                          _buildMenuGrid(context, [
                            _MenuData(Icons.savings_rounded,
                                'Tabungan\n(Wadiah)', Colors.teal),
                            _MenuData(Icons.shopping_bag_rounded,
                                'Jual Beli\n(Murabahah)', Colors.orange),
                            _MenuData(Icons.pie_chart_rounded,
                                'Bagi Hasil\n(Mudharabah)', Colors.purple),
                            _MenuData(Icons.handshake_rounded,
                                'Usaha Bersama\n(Musyarakah)', Colors.indigo),
                            _MenuData(Icons.volunteer_activism_rounded,
                                'Pinjaman Lunak\n(Qardhul Hasan)', Colors.pink),
                          ]),

                          const SizedBox(height: 25),

                          // SECTION 3: MANAJEMEN BMT
                          _buildSectionHeader(
                              "Manajemen BMT", Icons.business_center_outlined),
                          _buildMenuGrid(context, [
                            _MenuData(Icons.account_balance_rounded,
                                'Permodalan', Colors.brown),
                            _MenuData(Icons.money_off_csred_rounded,
                                'Pengeluaran', Colors.redAccent),
                            _MenuData(Icons.timeline_rounded, 'Cash Flow',
                                Colors.blueGrey),
                          ]),

                          const SizedBox(height: 25),

                          // SECTION 4: LAPORAN
                          _buildSectionHeader(
                              "Laporan & Data", Icons.folder_open_rounded),
                          _buildMenuGrid(context, [
                            _MenuData(Icons.assignment_rounded,
                                'Laporan Bulanan', Colors.amber[800]!),
                            _MenuData(Icons.cloud_sync_rounded, 'Backup Data',
                                Colors.cyan),
                          ]),

                          const SizedBox(
                              height:
                                  40), // Ruang ekstra di bawah agar tidak mentok
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  // Header Judul Per Kategori
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, left: 5.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Grid Menu
  Widget _buildMenuGrid(BuildContext context, List<_MenuData> menus) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.5, // Rasio kartu (Lebar : Tinggi)
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08), // Bayangan halus
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _handleNavigation(context, menu.title),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Lingkaran
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: menu.color
                          .withOpacity(0.1), // Warna background icon soft
                      shape: BoxShape.circle,
                    ),
                    child: Icon(menu.icon, size: 30, color: menu.color),
                  ),
                  const SizedBox(height: 10),
                  // Teks Menu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      menu.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Logika Navigasi
  void _handleNavigation(BuildContext context, String menuTitle) {
    // Normalisasi string (hapus enter/newline agar cocok)
    String cleanTitle = menuTitle.replaceAll('\n', ' ');
    Widget? targetPage;

    if (cleanTitle.contains('Daftar Anggota'))
      targetPage = const DaftarAnggotaPage();
    else if (cleanTitle.contains('Tabungan'))
      targetPage = const TabunganPage();
    else if (cleanTitle.contains('Jual Beli'))
      targetPage = const JualBeliPage();
    else if (cleanTitle.contains('Usaha Bersama'))
      targetPage = const UsahaBersamaPage();
    else if (cleanTitle.contains('Bagi Hasil'))
      targetPage = const BagiHasilPage();
    else if (cleanTitle.contains('Pinjaman Lunak'))
      targetPage = const PinjamanLunakPage();
    else if (cleanTitle.contains('Permodalan'))
      targetPage = const PermodalanBmtPage();
    else if (cleanTitle.contains('Pengeluaran'))
      targetPage = const PengeluaranBmtPage();
    else if (cleanTitle.contains('Cash Flow'))
      targetPage = const CashFlowBmtPage();
    else if (cleanTitle.contains('Backup Data'))
      targetPage = const BackupRestorePage();

    if (targetPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage!),
      );
    } else {
      // Feedback jika halaman belum ada
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menu "$cleanTitle" sedang disiapkan'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

// Model Data Menu Sederhana
class _MenuData {
  final IconData icon;
  final String title;
  final Color color;

  _MenuData(this.icon, this.title, this.color);
}
