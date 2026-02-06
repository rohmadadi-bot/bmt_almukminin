import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Pastikan sudah di add di pubspec.yaml
import '../../../data/db_helper.dart';
import 'detail_bagi_hasil_page.dart';

class TransaksiBagiHasilPage extends StatefulWidget {
  final Map<String, dynamic> akadData;

  const TransaksiBagiHasilPage({super.key, required this.akadData});

  @override
  State<TransaksiBagiHasilPage> createState() => _TransaksiBagiHasilPageState();
}

class _TransaksiBagiHasilPageState extends State<TransaksiBagiHasilPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _riwayatTransaksi = [];

  // Variabel Header Summary
  double _totalOmsetAll = 0;
  double _totalNasabahAll = 0;
  double _totalBmtAll = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _dbHelper.getTransaksiByAkadId(widget.akadData['id']);

    // Hitung Total untuk Header
    double tOmset = 0;
    double tNasabah = 0;
    double tBmt = 0;

    for (var item in data) {
      tOmset += (item['total_keuntungan'] as num).toDouble();
      tNasabah += (item['bagian_nasabah'] as num).toDouble();
      tBmt += (item['bagian_bmt'] as num).toDouble();
    }

    if (mounted) {
      setState(() {
        _riwayatTransaksi = data;
        _totalOmsetAll = tOmset;
        _totalNasabahAll = tNasabah;
        _totalBmtAll = tBmt;
      });
    }
  }

  // --- LOGIKA KIRIM WA ---
  void _kirimWA(Map<String, dynamic> transaksi) async {
    // Ambil No HP Nasabah dari Database berdasarkan ID Nasabah di Akad
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery(
        'SELECT telepon FROM anggota WHERE id = ?',
        [widget.akadData['nasabah_id']]);

    String rawPhone = "";
    if (res.isNotEmpty) {
      rawPhone = res.first['telepon']?.toString() ?? "";
    }

    if (rawPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nomor HP Nasabah tidak ditemukan")));
      }
      return;
    }

    // Format Nomor HP
    String phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (phone.startsWith('8')) {
      phone = '62$phone';
    }

    // Template Pesan
    String pesan = "📊 *LAPORAN BAGI HASIL BULANAN*\n"
        "🏛 *BMT AL MUKMININ*\n"
        "--------------------------------\n"
        "Usaha : *${widget.akadData['nama_usaha']}*\n"
        "Tanggal : ${transaksi['tgl_transaksi']}\n"
        "--------------------------------\n"
        "💰 Total Keuntungan : ${_currencyFormatter.format(transaksi['total_keuntungan'])}\n\n"
        "Pembagian:\n"
        "👤 Pengelola : ${_currencyFormatter.format(transaksi['bagian_nasabah'])}\n"
        "🏦 BMT : ${_currencyFormatter.format(transaksi['bagian_bmt'])}\n"
        "--------------------------------\n"
        "_Terima kasih atas kerjasamanya._";

    final String url =
        "https://wa.me/$phone?text=${Uri.encodeComponent(pesan)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal membuka WhatsApp")));
      }
    }
  }

  // --- INPUT KEUNTUNGAN (BOTTOM SHEET) ---
  void _showInputKeuntunganSheet() {
    final totalController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Ambil Nisbah dari Akad
    double nisbahN = (widget.akadData['nisbah_nasabah'] as num).toDouble();
    double nisbahB = (widget.akadData['nisbah_bmt'] as num).toDouble();

    double previewNasabah = 0;
    double previewBmt = 0;

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
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
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
                            const Icon(Icons.monetization_on,
                                color: Colors.white),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Text("Input Bagi Hasil",
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
                                const Text("Total Keuntungan Bulan Ini",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: totalController,
                                  keyboardType: TextInputType.number,
                                  autofocus: true,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                      prefixText: "Rp ",
                                      hintText: "0",
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 15)),
                                  validator: (val) =>
                                      val!.isEmpty ? "Wajib diisi" : null,
                                  onChanged: (val) {
                                    double v = double.tryParse(
                                            val.replaceAll('.', '')) ??
                                        0;
                                    setStateSheet(() {
                                      previewNasabah = v * (nisbahN / 100);
                                      previewBmt = v * (nisbahB / 100);
                                    });
                                  },
                                ),
                                const SizedBox(height: 25),

                                // Preview Pembagian (Card)
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: Colors.grey[300]!)),
                                  child: Column(
                                    children: [
                                      const Text("Estimasi Pembagian",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const Divider(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Nasabah ($nisbahN%)"),
                                          Text(
                                              _currencyFormatter
                                                  .format(previewNasabah),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("BMT ($nisbahB%)"),
                                          Text(
                                              _currencyFormatter
                                                  .format(previewBmt),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green)),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Tombol Simpan
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
                                double total = double.parse(
                                    totalController.text.replaceAll('.', ''));

                                Map<String, dynamic> row = {
                                  'akad_id': widget.akadData['id'],
                                  'tgl_transaksi':
                                      DateFormat('dd/MM/yyyy HH:mm')
                                          .format(DateTime.now()),
                                  'total_keuntungan': total,
                                  'bagian_nasabah': total * (nisbahN / 100),
                                  'bagian_bmt': total * (nisbahB / 100),
                                  'keterangan': 'Bagi Hasil Bulanan'
                                };

                                await _dbHelper.insertMudharabahTransaksi(row);

                                if (mounted) {
                                  Navigator.pop(context); // Tutup Sheet Input
                                  _loadData(); // Refresh Data Dashboard

                                  // --- BUKA SHEET SUKSES ---
                                  _showSuccessSheet(row);
                                }
                              }
                            },
                            child: const Text("SIMPAN TRANSAKSI",
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

  // --- SHEET SUKSES (BARU) ---
  void _showSuccessSheet(Map<String, dynamic> transaksi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Color(0xFF2E7D32),
                      child: Icon(Icons.check, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    const Text("Pembagian Berhasil Disimpan",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(transaksi['tgl_transaksi'],
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),

              // Detail
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(
                        "Total Keuntungan",
                        _currencyFormatter
                            .format(transaksi['total_keuntungan']),
                        isBold: true),
                    const Divider(height: 25),
                    _buildDetailRow("Bagian Pengelola",
                        _currencyFormatter.format(transaksi['bagian_nasabah'])),
                    const SizedBox(height: 8),
                    _buildDetailRow("Bagian BMT",
                        _currencyFormatter.format(transaksi['bagian_bmt'])),
                  ],
                ),
              ),

              // Tombol
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text("TUTUP",
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _kirimWA(transaksi),
                        icon: const Icon(Icons.share,
                            color: Colors.white, size: 18),
                        label: const Text("KIRIM WA",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
                fontSize: 15)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Transaksi Bagi Hasil"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. HEADER SUMMARY
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Text("Total Akumulasi Keuntungan",
                    style: TextStyle(color: Colors.white70)),
                Text(_currencyFormatter.format(_totalOmsetAll),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            const Text("Pengelola",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(_currencyFormatter.format(_totalNasabahAll),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            const Text("BMT",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(_currencyFormatter.format(_totalBmtAll),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 15),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Riwayat Transaksi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),

          // 2. LIST RIWAYAT
          Expanded(
            child: _riwayatTransaksi.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 50, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("Belum ada transaksi",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _riwayatTransaksi.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _riwayatTransaksi[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[50],
                            child: const Icon(Icons.receipt_long,
                                color: Colors.green),
                          ),
                          title: Text(
                              _currencyFormatter
                                  .format(item['total_keuntungan']),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item['tgl_transaksi']),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailBagiHasilPage(transaksiData: item),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 3. FLOATING BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInputKeuntunganSheet,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Input Keuntungan",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
