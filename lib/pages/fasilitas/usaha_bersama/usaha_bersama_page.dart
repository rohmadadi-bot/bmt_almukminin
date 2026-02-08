import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// UBAH: Gunakan ApiService
import '../../../services/api_service.dart';
// HAPUS IMPORT PAGE LAMA
// import 'tambah_usaha_bersama_page.dart';
import 'menu_usaha_bersama_page.dart';

class UsahaBersamaPage extends StatefulWidget {
  const UsahaBersamaPage({super.key});

  @override
  State<UsahaBersamaPage> createState() => _UsahaBersamaPageState();
}

class _UsahaBersamaPageState extends State<UsahaBersamaPage> {
  final ApiService _apiService = ApiService();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // --- 1. GET DATA LIST USAHA (ONLINE) ---
  Future<List<dynamic>> _getDaftarUsaha() async {
    return await _apiService.getUsahaBersama();
  }

  // --- 2. BOTTOM SHEET TAMBAH USAHA (PENGGANTI PAGE LAMA) ---
  void _showTambahUsahaSheet() {
    final formKey = GlobalKey<FormState>();
    final namaUsahaController = TextEditingController();
    final jenisUsahaController = TextEditingController();
    final modalController = TextEditingController();
    final deskripsiController = TextEditingController();
    final pjNamaController = TextEditingController();
    final tglController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now())); // Format SQL

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar bisa full screen saat keyboard muncul
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          bool isLoading = false; // State lokal sheet

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false, // Penting agar bisa di-drag
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // --- HEADER HIJAU ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.storefront,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Text("Buat Profil Usaha",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            )
                          ],
                        ),
                      ),

                      // --- FORM CONTENT ---
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInput(namaUsahaController, "Nama Usaha",
                                    Icons.store, "Contoh: Ternak Lele"),
                                const SizedBox(height: 15),
                                _buildInput(jenisUsahaController, "Kategori",
                                    Icons.category, "Contoh: Perikanan"),
                                const SizedBox(height: 15),
                                _buildInput(modalController, "Modal Awal (Rp)",
                                    Icons.monetization_on, "0",
                                    isNumber: true),
                                const SizedBox(height: 15),
                                _buildInput(
                                    pjNamaController,
                                    "Penanggung Jawab",
                                    Icons.person,
                                    "Nama Lengkap PJ"),
                                const SizedBox(height: 15),

                                // Tanggal Mulai (Read Only + DatePicker)
                                TextFormField(
                                  controller: tglController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: "Tanggal Mulai",
                                    hintText: "Pilih Tanggal",
                                    prefixIcon: const Icon(Icons.calendar_today,
                                        color: Color(0xFF2E7D32)),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  onTap: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      tglController.text =
                                          DateFormat('yyyy-MM-dd')
                                              .format(picked);
                                    }
                                  },
                                ),
                                const SizedBox(height: 15),
                                _buildInput(
                                    deskripsiController,
                                    "Deskripsi Usaha",
                                    Icons.description,
                                    "Jelaskan detail rencana...",
                                    maxLines: 3),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // --- TOMBOL SIMPAN ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration:
                            BoxDecoration(color: Colors.white, boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5))
                        ]),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setStateSheet(() => isLoading = true);

                                      // Parsing Modal
                                      double modal = double.tryParse(
                                              modalController.text
                                                  .replaceAll('.', '')
                                                  .replaceAll(',', '')) ??
                                          0;

                                      Map<String, dynamic> data = {
                                        'nama_usaha': namaUsahaController.text,
                                        'jenis_usaha':
                                            jenisUsahaController.text,
                                        'modal_awal': modal,
                                        'deskripsi': deskripsiController.text,
                                        'pj_nama': pjNamaController.text,
                                        'data_pelaksana': '-',
                                        'tgl_mulai': tglController.text,
                                      };

                                      // KIRIM KE API (usaha_bersama.php)
                                      bool success = await _apiService
                                          .addUsahaBersama(data);

                                      if (mounted) {
                                        setStateSheet(() => isLoading = false);

                                        if (success) {
                                          Navigator.pop(context); // Tutup Sheet
                                          setState(
                                              () {}); // Refresh Halaman Utama
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      "Profil Usaha Berhasil Dibuat!")));
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      "Gagal menyimpan data"),
                                                  backgroundColor: Colors.red));
                                        }
                                      }
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text("SIMPAN PROFIL USAHA",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER INPUT ---
  Widget _buildInput(TextEditingController controller, String label,
      IconData icon, String hint,
      {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: isNumber ? "Rp " : null,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (val) => val == null || val.isEmpty ? "Wajib diisi" : null,
    );
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
      body: FutureBuilder<List<dynamic>>(
        future: _getDaftarUsaha(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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
      // TOMBOL TAMBAH (MEMANGGIL BOTTOM SHEET)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTambahUsahaSheet, // <--- PANGGIL FUNGSI SHEET
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Tambah Usaha', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildUsahaCard(dynamic usaha) {
    double modal = double.tryParse(usaha['modal_awal'].toString()) ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // NAVIGASI KE MENU DETAIL (DATA DIPASSING LANGSUNG)
          Map<String, dynamic> usahaMap = Map<String, dynamic>.from(usaha);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuUsahaBersamaPage(usaha: usahaMap),
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
                          usaha['nama_usaha'] ?? '-',
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
                      color: (usaha['status'] == 'Aktif')
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      usaha['status'] ?? 'Aktif',
                      style: TextStyle(
                        color: (usaha['status'] == 'Aktif')
                            ? Colors.green[800]
                            : Colors.red[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
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
                        _formatter.format(modal),
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
                            usaha['tgl_mulai'] ?? '-',
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
