import 'package:flutter/material.dart';
// Pastikan kedua file ini ada di folder yang sama
import 'transaksi_akad_jual_beli_page.dart';
import 'transaksi_cicilan_jual_beli_page.dart';

class JualBeliPage extends StatelessWidget {
  const JualBeliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jual Beli (Murabahah)'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Pilih Transaksi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            // Grid Menu dengan navigasi aktif
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                // TOMBOL 1: TRANSAKSI CICILAN
                _buildMenuButton(
                  context,
                  icon: Icons.payments_outlined,
                  title: 'Transaksi Cicilan',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TransaksiCicilanJualBeliPage(),
                      ),
                    );
                  },
                ),
                // TOMBOL 2: TAMBAH AKAD
                _buildMenuButton(
                  context,
                  icon: Icons.add_shopping_cart_rounded,
                  title: 'Tambah Akad',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransaksiAkadJualBeliPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget Button bergaya Dashboard
  Widget _buildMenuButton(BuildContext context,
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
