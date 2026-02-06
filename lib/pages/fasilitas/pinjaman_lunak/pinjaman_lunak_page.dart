import 'package:flutter/material.dart';
import 'akad_pinjaman_lunak_page.dart';
import 'transaksi_cicilan_pinjaman_lunak_page.dart';

class PinjamanLunakPage extends StatelessWidget {
  const PinjamanLunakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Pinjaman Lunak (Qardhul Hasan)"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. HEADER PENJELASAN ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.volunteer_activism,
                          color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        "Tentang Qardhul Hasan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Pinjaman Lunak adalah pinjaman kebajikan tanpa bunga (riba). Peminjam hanya wajib mengembalikan pokok pinjaman sesuai kesepakatan waktu. BMT tidak mengambil keuntungan materi, melainkan keuntungan pahala dan bantuan sosial.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "\"Siapakah yang mau memberi pinjaman kepada Allah, pinjaman yang baik...\" (QS. Al-Baqarah: 245)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. MENU NAVIGASI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // TOMBOL 1: TRANSAKSI (CICILAN)
                  _buildMenuCard(
                    context,
                    title: "Transaksi Cicilan",
                    subtitle: "Input pembayaran angsuran nasabah",
                    icon: Icons.payments,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // PERBAIKAN: Hapus 'const' di sini
                          builder: (context) =>
                              TransaksiCicilanPinjamanLunakPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // TOMBOL 2: AKAD PINJAMAN
                  _buildMenuCard(
                    context,
                    title: "Akad Pinjaman Lunak",
                    subtitle: "Buat pinjaman baru atau lihat daftar peminjam",
                    icon: Icons.handshake,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // PERBAIKAN: Hapus 'const' di sini
                          builder: (context) => AkadPinjamanLunakPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[300], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
