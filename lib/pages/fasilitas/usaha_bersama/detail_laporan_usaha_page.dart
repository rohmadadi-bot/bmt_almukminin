import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/db_helper.dart';

class DetailLaporanUsahaPage extends StatefulWidget {
  final Map<String, dynamic> usaha;
  final Map<String, dynamic> laporan;

  const DetailLaporanUsahaPage(
      {super.key, required this.usaha, required this.laporan});

  @override
  State<DetailLaporanUsahaPage> createState() => _DetailLaporanUsahaPageState();
}

class _DetailLaporanUsahaPageState extends State<DetailLaporanUsahaPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _listInvestor = [];
  double _totalModalTerkumpul = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _hitungDistribusi();
  }

  Future<void> _hitungDistribusi() async {
    final dataModal = await _dbHelper.getModalByUsahaId(widget.usaha['id']);
    final dataAnggota = await _dbHelper.getAllAnggota();

    List<Map<String, dynamic>> tempList = [];
    double total = 0;

    for (var modal in dataModal) {
      total += (modal['jumlah_modal'] as num).toDouble();
      String? noTelp;
      try {
        final anggotaFound = dataAnggota.firstWhere(
          (a) =>
              a['nama'].toString().toLowerCase() ==
              modal['nama_pemodal'].toString().toLowerCase(),
          orElse: () => {},
        );
        if (anggotaFound.isNotEmpty) noTelp = anggotaFound['telepon'];
      } catch (e) {}

      Map<String, dynamic> newItem = Map.from(modal);
      newItem['telepon'] = noTelp;
      tempList.add(newItem);
    }

    if (mounted) {
      setState(() {
        _listInvestor = tempList;
        _totalModalTerkumpul = total;
        _isLoading = false;
      });
    }
  }

  // --- FUNGSI HAPUS LAPORAN ---
  Future<void> _hapusLaporan() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Laporan?"),
        content: const Text(
            "Data laporan ini akan dihapus permanen. Saldo yang sudah masuk ke wadiah tidak otomatis ditarik kembali."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteLaporanUsaha(widget.laporan['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Laporan berhasil dihapus"),
              backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  void _kirimWA(String nama, String? telepon, double persentase,
      double nominalDiterima) async {
    if (telepon == null || telepon.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No HP tidak ditemukan")));
      return;
    }
    String cleanPhone = telepon.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) cleanPhone = '62${cleanPhone.substring(1)}';

    String pesan = "🏛 *BMT AL MUKMININ - BAGI HASIL*\n"
        "Kepada Yth. *$nama*,\n"
        "Laporan bagi hasil usaha *${widget.usaha['nama_usaha']}* pada ${widget.laporan['tgl_lapor']}:\n"
        "💰 Total Dibagikan: ${_formatter.format(widget.laporan['total_lapor'])}\n"
        "📊 Saham Anda: ${(persentase * 100).toStringAsFixed(2)}%\n"
        "💵 *Diterima: ${_formatter.format(nominalDiterima)}*\n"
        "✅ _Masuk ke Tabungan Wadiah._";

    final Uri url = Uri.parse(
        "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(pesan)}");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Gagal WA: $e");
    }
  }

  // Widget Helper Baru (Konsisten dengan LaporanUsahaPage)
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

  @override
  Widget build(BuildContext context) {
    double danaSiapDibagi = (widget.laporan['total_lapor'] as num).toDouble();
    double totalPemasukan = danaSiapDibagi / 0.95;
    double kontribusiBmt = totalPemasukan * 0.05;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Detail Bagi Hasil"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0, // Hilangkan shadow agar menyatu dengan header
        actions: [
          IconButton(
            onPressed: _hapusLaporan,
            icon: const Icon(Icons.delete),
            tooltip: "Hapus Laporan",
          ),
        ],
      ),
      body: Column(
        children: [
          // --- HEADER KONSISTEN (Hijau Rounded) ---
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow("Total Pemasukan", totalPemasukan),
                const SizedBox(height: 8),
                _buildHeaderRow("Kontribusi BMT 5%", kontribusiBmt,
                    isMinus: true),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white30, height: 1),
                ),
                _buildHeaderRow("Dana Siap Dibagi", danaSiapDibagi,
                    isBig: true),
                const SizedBox(height: 15),

                // Keterangan & Tanggal
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text(
                      widget.laporan['tgl_lapor'],
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    if (widget.laporan['keterangan'] != null)
                      Text(
                        "Ket: ${widget.laporan['keterangan']}",
                        style: const TextStyle(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontSize: 12),
                      ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Judul List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Rincian Distribusi Pemodal",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- LIST DATA ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listInvestor.isEmpty
                    ? const Center(child: Text("Data pemodal tidak ditemukan"))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _listInvestor.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final investor = _listInvestor[index];
                          double modalDia =
                              (investor['jumlah_modal'] as num).toDouble();
                          double persentase = (_totalModalTerkumpul > 0)
                              ? (modalDia / _totalModalTerkumpul)
                              : 0;
                          double dapatUang = persentase * danaSiapDibagi;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              investor['nama_pemodal'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Modal: ${_formatter.format(modalDia)}",
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "${(persentase * 100).toStringAsFixed(2)}%",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange[800],
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF25D366),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 0),
                                          minimumSize: const Size(0, 32),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () => _kirimWA(
                                            investor['nama_pemodal'],
                                            investor['telepon'],
                                            persentase,
                                            dapatUang),
                                        icon: const Icon(Icons.share, size: 14),
                                        label: const Text("Kirim WA",
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                      Text(
                                        _formatter.format(dapatUang),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF2E7D32)),
                                      ),
                                    ],
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
