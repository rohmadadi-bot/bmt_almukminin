import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/db_helper.dart';

class DetailLaporanUsahaPage extends StatefulWidget {
  final Map<String, dynamic> usaha; // Data Usaha
  final Map<String, dynamic> laporan; // Data Laporan (Total uang yg dibagi)

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
    // 1. Ambil data modal
    final dataModal = await _dbHelper.getModalByUsahaId(widget.usaha['id']);

    // 2. Ambil data anggota (untuk cari nomor telepon)
    final dataAnggota = await _dbHelper.getAllAnggota();

    // 3. Gabungkan Data (Cari Telepon berdasarkan Nama)
    List<Map<String, dynamic>> tempList = [];
    double total = 0;

    for (var modal in dataModal) {
      total += (modal['jumlah_modal'] as num).toDouble();

      // Cari data anggota yg namanya sama
      String? noTelp;
      try {
        final anggotaFound = dataAnggota.firstWhere(
          (a) =>
              a['nama'].toString().toLowerCase() ==
              modal['nama_pemodal'].toString().toLowerCase(),
          orElse: () => {},
        );
        if (anggotaFound.isNotEmpty) {
          noTelp = anggotaFound['telepon'];
        }
      } catch (e) {
        // Abaikan jika tidak ketemu
      }

      // Buat map baru yg bisa diedit (tambah no telp)
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

  // --- FUNGSI KIRIM WA ---
  void _kirimWA(String nama, String? telepon, double persentase,
      double nominalDiterima) async {
    if (telepon == null || telepon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Nomor telepon nasabah tidak ditemukan"),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Format Nomor HP (08 -> 628)
    String cleanPhone = telepon.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    // Format Pesan
    String namaUsaha = widget.usaha['nama_usaha'];
    String tglLaporan = widget.laporan['tgl_lapor'];
    String nominalHasil = _formatter.format(nominalDiterima);
    String persenStr = "${(persentase * 100).toStringAsFixed(2)}%";

    String pesan = "🏛 *BMT AL MUKMININ - BAGI HASIL*\n"
        "----------------------------------------\n"
        "Kepada Yth. *$nama*,\n\n"
        "Berikut adalah laporan bagi hasil usaha *$namaUsaha* pada tanggal $tglLaporan:\n\n"
        "📊 Saham Anda: $persenStr\n"
        "💵 *Bagi Hasil: $nominalHasil*\n"
        "----------------------------------------\n"
        "✅ _Nominal tersebut telah masuk ke Tabungan Wadiah Anda._\n\n"
        "Terima kasih atas kepercayaannya.";

    final Uri url = Uri.parse(
        "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(pesan)}");

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Gagal kirim WA: $e");
    }
  }

  // Helper Row
  Widget _buildRow(String label, double nominal,
      {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize)),
          Text(
            _formatter.format(nominal),
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- PERHITUNGAN BALIK (REVERSE CALCULATION) ---
    // Di database tersimpan Dana Siap Dibagi (95%)
    double danaSiapDibagi = (widget.laporan['total_lapor'] as num).toDouble();

    // Hitung Total Pemasukan (100%) -> Dana Siap Dibagi / 0.95
    double totalPemasukan = danaSiapDibagi / 0.95;

    // Hitung Kontribusi BMT (5%) -> Total Pemasukan * 0.05
    double kontribusiBmt = totalPemasukan * 0.05;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Detail Bagi Hasil"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- HEADER INFO LAPORAN ---
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      widget.laporan['tgl_lapor'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Sukses",
                        style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const Divider(height: 20),
                const Text("Rincian Laporan",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),

                // --- RINCIAN PERHITUNGAN ---
                _buildRow("Total Pemasukan", totalPemasukan),
                _buildRow("Kontribusi BMT (5%)", kontribusiBmt,
                    color: Colors.red),
                const Divider(),
                _buildRow("Dana Siap Dibagi", danaSiapDibagi,
                    isBold: true, fontSize: 18, color: Colors.green[800]),

                const SizedBox(height: 8),
                Text(
                  "Ket: ${widget.laporan['keterangan']}",
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Distribusi Ke Pemodal (${_listInvestor.length})",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // --- LIST INVESTOR ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listInvestor.isEmpty
                    ? const Center(child: Text("Tidak ada data pemodal"))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _listInvestor.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final investor = _listInvestor[index];
                          double modalDia =
                              (investor['jumlah_modal'] as num).toDouble();

                          // HITUNG BAGI HASIL (DARI DANA SIAP DIBAGI)
                          double persentase = 0;
                          double dapatUang = 0;

                          if (_totalModalTerkumpul > 0) {
                            persentase = (modalDia / _totalModalTerkumpul);
                            dapatUang = persentase * danaSiapDibagi;
                          }

                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Tombol WA
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF25D366),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          minimumSize: const Size(0, 32),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          _kirimWA(
                                              investor['nama_pemodal'],
                                              investor['telepon'],
                                              persentase,
                                              dapatUang);
                                        },
                                        icon: const Icon(Icons.share, size: 14),
                                        label: const Text("Kirim WA",
                                            style: TextStyle(fontSize: 12)),
                                      ),

                                      // Nominal Diterima
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
