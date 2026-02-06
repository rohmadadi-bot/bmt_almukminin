import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/db_helper.dart';
import 'detail_laporan_usaha_page.dart';

class LaporanUsahaPage extends StatefulWidget {
  final Map<String, dynamic> usaha;

  const LaporanUsahaPage({super.key, required this.usaha});

  @override
  State<LaporanUsahaPage> createState() => _LaporanUsahaPageState();
}

class _LaporanUsahaPageState extends State<LaporanUsahaPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _listLaporan = [];
  double _totalPemasukan = 0; // Ini Total Kotor (Pemasukan)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final laporan = await _dbHelper.getLaporanByUsahaId(widget.usaha['id']);
    // Ambil total pemasukan kotor dari tabel pemasukan
    final totalPending =
        await _dbHelper.getPemasukanBelumDibagi(widget.usaha['id']);

    if (mounted) {
      setState(() {
        _listLaporan = laporan;
        _totalPemasukan = totalPending;
        _isLoading = false;
      });
    }
  }

  // --- BUAT LAPORAN (BOTTOM SHEET) ---
  void _showBuatLaporanSheet() {
    if (_totalPemasukan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Tidak ada pemasukan baru untuk dilaporkan/dibagi.")),
      );
      return;
    }

    // --- RUMUS PERHITUNGAN ---
    double totalMasuk = _totalPemasukan;
    double kontribusiBmt = totalMasuk * 0.05; // 5%
    double danaSiapDibagi = totalMasuk - kontribusiBmt; // 95%

    final tglController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
    final ketController = TextEditingController();
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
            child: DraggableScrollableSheet(
              initialChildSize:
                  0.75, // Sedikit lebih tinggi untuk info tambahan
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Header Sheet
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
                              child: const Icon(Icons.assignment,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Text("Buat Laporan Baru",
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

                      // Form Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- INFORMASI KEUANGAN (HEADER STYLE) ---
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.green[100]!),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildSummaryRow("Pemasukan", totalMasuk,
                                          isBold: false),
                                      const Divider(),
                                      _buildSummaryRow(
                                          "Kontribusi BMT (5%)", kontribusiBmt,
                                          isBold: false,
                                          color: Colors.red[700]),
                                      const Divider(thickness: 2),
                                      _buildSummaryRow(
                                          "Dana Siap Dibagi", danaSiapDibagi,
                                          isBold: true,
                                          color: Colors.green[800],
                                          fontSize: 18),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.blue[100]!)),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.blue[800], size: 20),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          "Dana Siap Dibagi akan didistribusikan otomatis ke Tabungan Wadiah pemodal sesuai porsi modal.",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),
                                const Text("Tanggal Laporan",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tglController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    prefixIcon:
                                        const Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onTap: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      tglController.text =
                                          DateFormat('dd/MM/yyyy')
                                              .format(picked);
                                    }
                                  },
                                ),
                                const SizedBox(height: 15),
                                const Text("Keterangan (Opsional)",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: ketController,
                                  decoration: InputDecoration(
                                    hintText: "Cth: Laporan Bulan Januari",
                                    prefixIcon: const Icon(Icons.description),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Tombol Proses
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
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                // PENTING: Kita kirim 'danaSiapDibagi' sebagai totalLapor
                                // agar DbHelper membagikan nominal bersih ke nasabah.
                                await _dbHelper.buatLaporanUsaha(
                                    usahaId: widget.usaha['id'],
                                    namaUsaha: widget.usaha['nama_usaha'],
                                    totalLapor:
                                        danaSiapDibagi, // Kirim Nominal Bersih
                                    tgl: tglController.text,
                                    ket: ketController.text.isEmpty
                                        ? "Laporan Berkala"
                                        : ketController.text);

                                if (mounted) {
                                  Navigator.pop(context); // Tutup Sheet
                                  await _loadData(); // Refresh Data

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Sukses! Dana Bersih dibagikan ke pemodal."),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text("PROSES BAGI HASIL",
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

  // Widget Helper untuk Baris Ringkasan
  Widget _buildSummaryRow(String label, double nominal,
      {bool isBold = false, Color? color, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87)),
          Text(_formatter.format(nominal),
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hitung Breakdown untuk Header Utama
    double totalPemasukan = _totalPemasukan;
    double kontribusiBmt = totalPemasukan * 0.05;
    double danaSiapDibagi = totalPemasukan - kontribusiBmt;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Laporan & Bagi Hasil"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- HEADER BARU ---
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
                _buildHeaderRow("Pemasukan", totalPemasukan),
                const SizedBox(height: 8),
                _buildHeaderRow("Kontribusi BMT 5%", kontribusiBmt,
                    isMinus: true),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white30, height: 1),
                ),
                _buildHeaderRow("Dana Siap Dibagi", danaSiapDibagi,
                    isBig: true),
              ],
            ),
          ),

          // --- LIST RIWAYAT ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listLaporan.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            const Text("Belum ada riwayat laporan",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _listLaporan.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _listLaporan[index];
                          // Item di database menyimpan 'Dana Siap Dibagi'
                          // Kita tampilkan itu saja di list
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailLaporanUsahaPage(
                                      usaha: widget.usaha,
                                      laporan: item,
                                    ),
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple[100],
                                child: Icon(Icons.check_circle,
                                    color: Colors.purple[800]),
                              ),
                              title: Text(
                                _formatter.format(item['total_lapor']),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(item['keterangan'] ?? '-'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 12, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(item['tgl_lapor'],
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBuatLaporanSheet,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
        label: const Text("Proses Bagi Hasil",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeaderRow(String label, double nominal,
      {bool isMinus = false, bool isBig = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withOpacity(isBig ? 1.0 : 0.8),
              fontSize: isBig ? 16 : 14,
              fontWeight: isBig ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          "${isMinus ? '- ' : ''}${_formatter.format(nominal)}",
          style: TextStyle(
            color: isMinus ? Colors.red[100] : Colors.white,
            fontSize: isBig ? 20 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
