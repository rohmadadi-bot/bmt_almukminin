import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// UBAH: Gunakan ApiService
import '../../../services/api_service.dart';

class PemasukanUsahaPage extends StatefulWidget {
  final Map<String, dynamic> usaha;

  const PemasukanUsahaPage({super.key, required this.usaha});

  @override
  State<PemasukanUsahaPage> createState() => _PemasukanUsahaPageState();
}

class _PemasukanUsahaPageState extends State<PemasukanUsahaPage> {
  // UBAH: Inisialisasi ApiService
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<dynamic> _listPemasukan = [];
  double _totalBelumDibagi = 0; // Saldo Aktif
  double _totalPemasukanAll = 0; // Akumulasi Semua Waktu
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    int usahaId = int.tryParse(widget.usaha['id'].toString()) ?? 0;

    // Panggil API
    final data = await _apiService.getPemasukanUsaha(usahaId);

    double totalBelum = 0;
    double totalAll = 0;

    for (var item in data) {
      double jumlah = double.tryParse(item['jumlah'].toString()) ?? 0;

      // Hitung Total Semua Pemasukan
      totalAll += jumlah;

      // Hitung Hanya yang Belum Dibagi
      if (item['status'] == 'Belum Dibagi') {
        totalBelum += jumlah;
      }
    }

    if (mounted) {
      setState(() {
        _listPemasukan = data;
        _totalBelumDibagi = totalBelum;
        _totalPemasukanAll = totalAll;
        _isLoading = false;
      });
    }
  }

  // --- HAPUS DATA (ONLINE) ---
  void _hapusData(int id) async {
    bool success = await _apiService.deletePemasukanUsaha(id);

    if (mounted) {
      if (success) {
        Navigator.pop(context); // Tutup Detail Sheet
        _loadData(); // Refresh Data
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data berhasil dihapus")));
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Gagal menghapus data"),
            backgroundColor: Colors.red));
      }
    }
  }

  // --- DETAIL SHEET (Updated: Ada Tombol Hapus) ---
  void _showDetailSheet(Map<String, dynamic> item) {
    bool isLocked = item['status'] == 'Sudah Dibagi';
    int id = int.tryParse(item['id'].toString()) ?? 0;
    double jumlah = double.tryParse(item['jumlah'].toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),

                // Icon Header
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      isLocked ? Colors.grey[200] : Colors.teal[50],
                  child: Icon(
                    isLocked ? Icons.lock : Icons.check_circle,
                    color: isLocked ? Colors.grey : Colors.teal,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 15),
                const Text("Rincian Pemasukan",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(height: 30),

                // Detail Info
                _detailRow("Tanggal", item['tgl_transaksi']),
                _detailRow("Keterangan", item['keterangan'] ?? '-'),
                _detailRow("Status", item['status'],
                    color: isLocked ? Colors.grey : Colors.orange),

                const SizedBox(height: 20),

                // Highlight Jumlah
                Container(
                  padding: const EdgeInsets.all(15),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Text("Nominal Masuk",
                          style:
                              TextStyle(color: Colors.teal[800], fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(_currencyFormatter.format(jumlah),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              color: Colors.teal)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- TOMBOL AKSI ---
                Row(
                  children: [
                    // TOMBOL HAPUS (Kiri) - Hanya jika belum dibagi
                    if (!isLocked)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                      title: const Text("Hapus Data"),
                                      content: const Text(
                                          "Yakin ingin menghapus data ini secara permanen?"),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text("Batal")),
                                        TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _hapusData(id);
                                            },
                                            child: const Text("Hapus",
                                                style: TextStyle(
                                                    color: Colors.red))),
                                      ],
                                    ));
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text("HAPUS",
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                        ),
                      ),

                    if (!isLocked) const SizedBox(width: 10),

                    // TOMBOL TUTUP (Kanan)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text("TUTUP",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),

                // Pesan jika terkunci
                if (isLocked)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "Data ini sudah dibagikan (profit sharing) dan tidak dapat dihapus.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.black87)),
          ),
        ],
      ),
    );
  }

  // --- TAMBAH PEMASUKAN (SHEET) ---
  void _showTambahSheet() {
    final jumlahController = TextEditingController();
    final ketController = TextEditingController();
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now())); // Format SQL
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          child: const Icon(Icons.attach_money,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text("Catat Pemasukan",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Jumlah Pendapatan",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: jumlahController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                prefixText: "Rp ",
                                hintText: "0",
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? "Wajib diisi" : null,
                            ),
                            const SizedBox(height: 20),
                            const Text("Tanggal Transaksi",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: "Pilih Tanggal",
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onTap: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  dateController.text =
                                      DateFormat('yyyy-MM-dd').format(picked);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text("Keterangan / Sumber",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: ketController,
                              decoration: InputDecoration(
                                hintText: "Cth: Penjualan Harian",
                                prefixIcon: const Icon(Icons.notes),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? "Wajib diisi" : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [
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
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            String cleanJumlah = jumlahController.text
                                .replaceAll('.', '')
                                .replaceAll(',', '');
                            double nominal = double.parse(cleanJumlah);
                            int usahaId =
                                int.tryParse(widget.usaha['id'].toString()) ??
                                    0;

                            // 1. Simpan ke Database API & Ambil ID
                            int newId = await _apiService.insertPemasukanUsaha({
                              'usaha_id': usahaId,
                              'jumlah': nominal,
                              'tgl_transaksi': dateController.text,
                              'keterangan': ketController.text,
                              'status': 'Belum Dibagi'
                            });

                            if (mounted) {
                              if (newId > 0) {
                                // 2. Tutup Form Sheet
                                Navigator.pop(context);

                                // 3. Refresh Data di Halaman
                                _loadData();

                                // 4. Siapkan Data Baru
                                Map<String, dynamic> newItem = {
                                  'id': newId,
                                  'jumlah': nominal,
                                  'tgl_transaksi': dateController.text,
                                  'keterangan': ketController.text,
                                  'status': 'Belum Dibagi'
                                };

                                // 5. Buka Detail Sheet Secara Otomatis
                                _showDetailSheet(newItem);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Gagal menyimpan data"),
                                        backgroundColor: Colors.red));
                              }
                            }
                          }
                        },
                        child: const Text("SIMPAN PEMASUKAN",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pemasukan Usaha"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- HEADER TOTAL ---
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
                  "Total Belum Dibagi (Saldo Aktif)",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  _currencyFormatter.format(_totalBelumDibagi),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // --- INFO TOTAL PEMASUKAN (SEMUA) ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history, color: Colors.white70, size: 16),
                          SizedBox(width: 8),
                          Text("Total Pemasukan (Akumulasi)",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      Text(
                        _currencyFormatter.format(_totalPemasukanAll),
                        style: const TextStyle(
                            color: Colors.yellowAccent,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          // --- LIST PEMASUKAN ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listPemasukan.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("Belum ada data pemasukan",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _listPemasukan.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _listPemasukan[index];
                          bool isLocked = item['status'] == 'Sudah Dibagi';
                          double jumlah =
                              double.tryParse(item['jumlah'].toString()) ?? 0;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              onTap: () => _showDetailSheet(item),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    isLocked ? Colors.grey : Colors.teal[100],
                                child: Icon(
                                    isLocked
                                        ? Icons.lock
                                        : Icons.arrow_downward,
                                    color: isLocked
                                        ? Colors.white
                                        : Colors.teal[800]),
                              ),
                              title: Text(
                                _currencyFormatter.format(jumlah),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(item['keterangan'] ?? '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 12, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(item['tgl_transaksi'],
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                      const Spacer(),
                                      if (isLocked)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: Colors.grey,
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: const Text("Sudah Dibagi",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white)),
                                        )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTambahSheet,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Pemasukan",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
