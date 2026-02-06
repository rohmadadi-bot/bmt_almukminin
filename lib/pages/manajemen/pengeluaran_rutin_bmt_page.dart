import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/db_helper.dart';

class PengeluaranRutinBmtPage extends StatefulWidget {
  const PengeluaranRutinBmtPage({super.key});

  @override
  State<PengeluaranRutinBmtPage> createState() =>
      _PengeluaranRutinBmtPageState();
}

class _PengeluaranRutinBmtPageState extends State<PengeluaranRutinBmtPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _listData = [];
  bool _isLoading = true;
  int _totalPengeluaran = 0; // Variabel untuk header total

  // Controller
  final _namaController = TextEditingController();
  final _nominalController = TextEditingController();
  final _ketController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _dbHelper.getPengeluaranByKategori('Rutin');

    // Hitung Total
    int total = 0;
    for (var item in data) {
      total += (item['nominal'] as int);
    }

    if (mounted) {
      setState(() {
        _listData = data;
        _totalPengeluaran = total;
        _isLoading = false;
      });
    }
  }

  Future<void> _tambahPengeluaran() async {
    if (_namaController.text.isEmpty || _nominalController.text.isEmpty) return;

    // 1. Siapkan Data
    String nama = _namaController.text;
    int nominal =
        int.parse(_nominalController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    String ket = _ketController.text;
    String tanggal = DateTime.now().toIso8601String();

    // 2. Simpan ke Database
    int newId = await _dbHelper.insertPengeluaran({
      'kategori': 'Rutin',
      'nama_pengeluaran': nama,
      'nominal': nominal,
      'tanggal': tanggal,
      'keterangan': ket
    });

    // 3. Bersihkan Controller
    _namaController.clear();
    _nominalController.clear();
    _ketController.clear();

    // 4. Tutup Sheet Input & Refresh Data Background
    if (mounted) Navigator.pop(context);
    _loadData();

    // 5. Tampilkan Sheet Detail (Konfirmasi)
    if (mounted) {
      // Buat objek map sementara untuk ditampilkan
      Map<String, dynamic> newItem = {
        'id': newId,
        'nama_pengeluaran': nama,
        'nominal': nominal,
        'tanggal': tanggal,
        'keterangan': ket
      };
      _showDetailSheet(newItem);
    }
  }

  Future<void> _hapusData(int id) async {
    await _dbHelper.deletePengeluaran(id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Data berhasil dihapus"), backgroundColor: Colors.red),
    );
  }

  // --- BOTTOM SHEET 1: INPUT ---
  void _showInputSheet() {
    // Ambil daftar nama unik untuk sugesti
    final List<String> suggestions = _listData
        .map((e) => e['nama_pengeluaran'] as String)
        .toSet() // Hapus duplikat
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tambah Pengeluaran Rutin",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue)),
            const SizedBox(height: 15),

            // INPUT DENGAN SUGESTI (AUTOCOMPLETE)
            const Text("Jenis Pengeluaran",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return suggestions.where((String option) {
                  return option
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _namaController.text = selection;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                // Sinkronisasi controller autocomplete dengan _namaController manual kita
                if (controller.text != _namaController.text) {
                  controller.text = _namaController.text;
                }
                // Listener agar saat mengetik manual tetap masuk ke _namaController
                controller.addListener(() {
                  _namaController.text = controller.text;
                });

                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                      hintText: "Ketik atau pilih sugesti (Gaji, Listrik...)",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                );
              },
            ),

            const SizedBox(height: 15),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: "Nominal (Rp)",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _ketController,
              decoration: InputDecoration(
                  labelText: "Keterangan (Opsional)",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: _tambahPengeluaran,
                child: const Text("SIMPAN",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- BOTTOM SHEET 2: DETAIL SETELAH SIMPAN ---
  void _showDetailSheet(Map<String, dynamic> item) {
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
              const Icon(Icons.check_circle, size: 60, color: Colors.green),
              const SizedBox(height: 10),
              const Text("Berhasil Disimpan!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Tabel Detail Kecil
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildDetailRow("Jenis", item['nama_pengeluaran']),
                    const Divider(),
                    _buildDetailRow(
                        "Nominal", _formatter.format(item['nominal'])),
                    const Divider(),
                    _buildDetailRow("Ket", item['keterangan'] ?? '-'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Tombol Tambah Lagi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    Navigator.pop(context); // Tutup Detail
                    _showInputSheet(); // Buka Input Lagi
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Tambah Pengeluaran Rutin",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("Tutup", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pengeluaran Rutin"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      // Tombol Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInputSheet,
        backgroundColor: Colors.blue[800],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Pengeluaran Rutin",
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // --- HEADER TOTAL ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Total Pengeluaran Rutin",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatter.format(_totalPengeluaran),
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

          // --- LIST DATA ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listData.isEmpty
                    ? const Center(child: Text("Belum ada data"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _listData.length,
                        itemBuilder: (ctx, index) {
                          final item = _listData[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[50],
                                child: const Icon(Icons.repeat,
                                    color: Colors.blue),
                              ),
                              title: Text(item['nama_pengeluaran'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('dd MMM yyyy')
                                      .format(DateTime.parse(item['tanggal']))),
                                  if (item['keterangan'] != null &&
                                      item['keterangan'] != '')
                                    Text(item['keterangan'],
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_formatter.format(item['nominal']),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.red)),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.grey, size: 20),
                                    onPressed: () => _hapusData(item['id']),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
