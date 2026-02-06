import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/db_helper.dart';
import 'tambah_usaha_bersama_page.dart';
// IMPORT HALAMAN MENU (DASHBOARD USAHA)
import 'menu_usaha_bersama_page.dart';

class UsahaBersamaPage extends StatefulWidget {
  const UsahaBersamaPage({super.key});

  @override
  State<UsahaBersamaPage> createState() => _UsahaBersamaPageState();
}

class _UsahaBersamaPageState extends State<UsahaBersamaPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // Fungsi untuk refresh data setelah tambah usaha
  Future<List<Map<String, dynamic>>> _getDaftarUsaha() async {
    return await _dbHelper.getAllUsahaBersama();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Fasilitas Usaha Bersama'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getDaftarUsaha(),
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Data Kosong
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text('Belum ada profil usaha bersama',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // List Data Usaha
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final usaha = snapshot.data![index];
              return _buildUsahaCard(usaha);
            },
          );
        },
      ),
      // Floating Action Button di Pojok Kanan Bawah
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigasi ke halaman tambah dan tunggu hasil (refresh jika ada data baru)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TambahUsahaBersamaPage()),
          );
          if (result == true) {
            setState(() {}); // Refresh halaman
          }
        },
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Tambah Usaha', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildUsahaCard(Map<String, dynamic> usaha) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // <--- TAMBAHAN: Agar kartu bisa diklik
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // NAVIGASI KE HALAMAN MENU USAHA BERSAMA
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuUsahaBersamaPage(usaha: usaha),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usaha['nama_usaha'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            usaha['jenis_usaha'] ?? 'Umum',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: usaha['status'] == 'Aktif'
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      usaha['status'],
                      style: TextStyle(
                        color: usaha['status'] == 'Aktif'
                            ? Colors.green[800]
                            : Colors.red[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              // --- MENAMPILKAN DESKRIPSI (JIKA ADA) ---
              if (usaha['deskripsi'] != null &&
                  usaha['deskripsi'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  usaha['deskripsi'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],

              const Divider(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Modal Awal',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        _formatter.format(usaha['modal_awal']),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Mulai Tanggal',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Row(
                        children: [
                          Text(
                            usaha['tgl_mulai'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              size: 16, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
