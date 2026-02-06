import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format Rupiah
import 'package:url_launcher/url_launcher.dart'; // Untuk WA
import '../../data/db_helper.dart';

class PermodalanBmtPage extends StatefulWidget {
  const PermodalanBmtPage({super.key});

  @override
  State<PermodalanBmtPage> createState() => _PermodalanBmtPageState();
}

class _PermodalanBmtPageState extends State<PermodalanBmtPage> {
  final DbHelper _dbHelper = DbHelper();
  List<Map<String, dynamic>> _history = [];
  int _totalDana = 0;

  // Controller untuk Input
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // --- FUNGSI LOAD DATA ---
  void _refreshData() async {
    final data = await _dbHelper.getModalHistory();
    final total = await _dbHelper.getTotalModal();
    setState(() {
      _history = data;
      _totalDana = total;
    });
  }

  // --- [MODIFIKASI] FUNGSI TAMBAH DATA ---
  Future<void> _addModal() async {
    // 1. Validasi Input
    if (_namaController.text.isEmpty || _nominalController.text.isEmpty) return;

    // 2. Siapkan Data
    String nama = _namaController.text;
    int nominal = int.parse(_nominalController.text);
    String tanggal = DateTime.now().toIso8601String();

    // 3. Simpan ke DB dan AMBIL ID BARU
    int newId = await _dbHelper.insertModal({
      'nama_pemodal': nama,
      'nominal': nominal,
      'tanggal': tanggal,
    });

    // 4. Bersihkan Controller
    _namaController.clear();
    _nominalController.clear();

    // 5. Tutup Bottom Sheet Input
    if (mounted) Navigator.pop(context);

    // 6. Refresh Tampilan Background
    _refreshData();

    // 7. [FITUR BARU] Langsung Munculkan Detail Transaksi Baru
    if (mounted) {
      // Buat Map sementara agar bisa dibaca oleh _showDetailModal
      Map<String, dynamic> newItem = {
        'id': newId,
        'nama_pemodal': nama,
        'nominal': nominal,
        'tanggal': tanggal,
      };

      // Panggil Bottom Sheet Detail
      _showDetailModal(context, newItem);
    }
  }

  // --- FUNGSI HAPUS DATA ---
  Future<void> _deleteModal(int id) async {
    await _dbHelper.deleteModal(id);
    if (mounted) Navigator.pop(context); // Tutup Bottom Sheet Detail
    _refreshData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Data Berhasil Dihapus'), backgroundColor: Colors.red),
    );
  }

  // --- FUNGSI KIRIM WA (NOMOR BLANK) ---
  // Fungsi ini sudah benar menggunakan skema tanpa nomor HP
  Future<void> _shareToWhatsApp(
      String nama, String nominal, String tanggal) async {
    // Format Pesan
    String message = "Assalamualaikum, berikut detail transaksi Modal BMT:\n\n"
        "Nama: $nama\n"
        "Nominal: $nominal\n"
        "Tanggal: $tanggal\n\n"
        "Terima kasih.";

    // URL Scheme WA tanpa nomor HP (akan membuka kontak picker)
    final Uri url =
        Uri.parse("whatsapp://send?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Fallback jika tidak bisa membuka WA langsung (misal di simulator)
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuka WhatsApp: $e")),
      );
    }
  }

  // Helper Format Rupiah
  String _formatRupiah(int nominal) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(nominal);
  }

  // Helper Format Tanggal
  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Permodalan BMT"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      // --- FAB DI KANAN BAWAH ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text("Tambah Modal", style: TextStyle(color: Colors.white)),
        onPressed: () => _showInputModal(context),
      ),
      body: Column(
        children: [
          // --- HEADER TOTAL DANA ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Total Dana Terkumpul",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatRupiah(_totalDana),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- LIST RIWAYAT ---
          Expanded(
            child: _history.isEmpty
                ? const Center(child: Text("Belum ada data modal"))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[50],
                            child: const Icon(Icons.attach_money,
                                color: Colors.green),
                          ),
                          title: Text(
                            item['nama_pemodal'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(_formatDate(item['tanggal'])),
                          trailing: Text(
                            _formatRupiah(item['nominal']),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => _showDetailModal(context, item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM SHEET 1: INPUT MODAL ---
  void _showInputModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Supaya tidak tertutup keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tambah Modal Baru",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: "Nama Pemodal",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Nominal (Rp)",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _addModal,
                  child: const Text("SIMPAN",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BOTTOM SHEET 2: DETAIL & AKSI ---
  void _showDetailModal(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Garis handle kecil
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),

              // Info Detail
              const Text("Detail Transaksi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildDetailRow("Nama Pemodal", item['nama_pemodal']),
              _buildDetailRow("Nominal", _formatRupiah(item['nominal'])),
              _buildDetailRow("Tanggal", _formatDate(item['tanggal'])),

              const SizedBox(height: 30),

              // Tombol Aksi
              Row(
                children: [
                  // Tombol Hapus
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text("Hapus"),
                      onPressed: () {
                        // Konfirmasi hapus
                        showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                  title: const Text("Hapus Data?"),
                                  content: const Text(
                                      "Data yang dihapus tidak dapat dikembalikan."),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("Batal")),
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx); // Tutup dialog
                                          _deleteModal(item['id']);
                                        },
                                        child: const Text("Hapus",
                                            style:
                                                TextStyle(color: Colors.red))),
                                  ],
                                ));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Tombol Kirim WA
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text("Kirim WA",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        _shareToWhatsApp(
                            item['nama_pemodal'],
                            _formatRupiah(item['nominal']),
                            _formatDate(item['tanggal']));
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
