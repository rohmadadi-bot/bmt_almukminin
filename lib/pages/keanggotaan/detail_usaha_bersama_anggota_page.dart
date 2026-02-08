import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart'; // Ganti DbHelper dengan ApiService

class DetailUsahaBersamaAnggotaPage extends StatefulWidget {
  final int nasabahId;
  final String namaNasabah;

  const DetailUsahaBersamaAnggotaPage(
      {super.key, required this.nasabahId, required this.namaNasabah});

  @override
  State<DetailUsahaBersamaAnggotaPage> createState() =>
      _DetailUsahaBersamaAnggotaPageState();
}

class _DetailUsahaBersamaAnggotaPageState
    extends State<DetailUsahaBersamaAnggotaPage> {
  // 1. Inisialisasi API Service
  final ApiService _apiService = ApiService();

  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _dataPortofolio = [];
  bool _isLoading = true;

  // Variabel Header Statistik
  double _totalInvestasi = 0;
  double _totalKeuntunganDiterima = 0;

  // Cache riwayat wadiah untuk efisiensi
  List<dynamic> _riwayatWadiahCache = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- 2. LOAD DATA DARI API ---
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Reset
    double tempInvestasi = 0;
    double tempKeuntungan = 0;
    List<Map<String, dynamic>> tempPortofolio = [];

    try {
      // A. AMBIL DATA MODAL (PORTOFOLIO)
      // Strategi: Ambil Semua Usaha -> Cek Modal di tiap usaha
      final List<dynamic> allUsaha = await _apiService.getUsahaBersama();

      for (var usaha in allUsaha) {
        int usahaId = int.parse(usaha['id'].toString());

        // Ambil daftar pemodal di usaha ini
        final List<dynamic> pemodalList =
            await _apiService.getModalUsaha(usahaId);

        // Cek apakah nasabah ini ada di daftar pemodal (Match by Nama)
        // Note: Idealnya match by ID, tapi struktur lama pakai Nama
        var myModal = pemodalList.where((p) =>
            p['nama_pemodal'].toString().toLowerCase() ==
            widget.namaNasabah.toLowerCase());

        for (var m in myModal) {
          double jumlahModal =
              double.tryParse(m['jumlah_modal'].toString()) ?? 0;
          tempInvestasi += jumlahModal;

          tempPortofolio.add({
            'nama_usaha': usaha['nama_usaha'],
            'jenis_usaha': usaha['jenis_usaha'],
            'jumlah_modal': jumlahModal,
            'usaha_id': usahaId
          });
        }
      }

      // B. AMBIL DATA KEUNTUNGAN (DARI RIWAYAT WADIAH)
      // Ambil riwayat wadiah nasabah ini
      final wadiahResponse = await _apiService.getWadiah(widget.nasabahId);
      if (wadiahResponse['status'] == true && wadiahResponse['data'] != null) {
        _riwayatWadiahCache =
            wadiahResponse['data']; // Simpan untuk popup nanti

        for (var t in _riwayatWadiahCache) {
          String ket = t['keterangan'] ?? '';
          // Filter transaksi yang merupakan Bagi Hasil Otomatis
          // Sesuaikan dengan format keterangan di PHP Anda
          if (ket.toLowerCase().contains('bagi hasil')) {
            double nominal = double.tryParse(t['jumlah'].toString()) ?? 0;
            // Cek jenis transaksi (harus Setoran/Masuk)
            String jenis = t['jenis'] ?? '';
            if (jenis == 'Setoran' || jenis == 'Bagi Hasil') {
              tempKeuntungan += nominal;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _dataPortofolio = tempPortofolio;
          _totalInvestasi = tempInvestasi;
          _totalKeuntunganDiterima = tempKeuntungan;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load usaha: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. SHOW RIWAYAT BAGI HASIL (FILTER DARI CACHE) ---
  void _showRiwayatBagiHasil(String namaUsaha) {
    try {
      // Filter dari cache _riwayatWadiahCache yang sudah diambil di awal
      // Cari yang keterangannya mengandung nama usaha tersebut
      final riwayat = _riwayatWadiahCache.where((item) {
        String ket = (item['keterangan'] ?? '').toString().toLowerCase();
        return ket.contains(namaUsaha.toLowerCase()) &&
            ket.contains('bagi hasil');
      }).toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 5),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // Header Bottom Sheet
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Riwayat Bagi Hasil",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(namaUsaha,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // List Riwayat
                    Expanded(
                      child: riwayat.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history,
                                      size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  const Text("Belum ada pembagian hasil",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: riwayat.length,
                              separatorBuilder: (ctx, i) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final item = riwayat[i];
                                double nominal = double.tryParse(
                                        item['jumlah'].toString()) ??
                                    0;
                                String tgl = item['tgl_transaksi'] ?? '-';
                                String ket = item['keterangan'] ?? '-';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.teal[50],
                                    child: const Icon(Icons.arrow_downward,
                                        color: Colors.teal, size: 20),
                                  ),
                                  title: Text(_formatter.format(nominal),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(tgl,
                                          style: const TextStyle(fontSize: 12)),
                                      Text(ket,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Tombol Tutup
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: const Text("TUTUP",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal)),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat riwayat")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Portofolio Investasi"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- HEADER SUMMARY ---
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text("Total Nilai Investasi",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(
                        _formatter.format(_totalInvestasi),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Row Statistik: Total Keuntungan
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.trending_up,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Total Bagi Hasil Diterima",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                                Text(
                                    _formatter.format(_totalKeuntunganDiterima),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Daftar Usaha",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 5),

                // --- LIST PORTOFOLIO ---
                Expanded(
                  child: _dataPortofolio.isEmpty
                      ? const Center(
                          child: Text("Belum ada investasi",
                              style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _dataPortofolio.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _dataPortofolio[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    _showRiwayatBagiHasil(item['nama_usaha']),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            color: Colors.teal[50],
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.storefront,
                                            color: Colors.teal, size: 24),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item['nama_usaha'],
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                            Text(item['jenis_usaha'] ?? '-',
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text("Modal",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey)),
                                          Text(
                                              _formatter
                                                  .format(item['jumlah_modal']),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal)),
                                        ],
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.chevron_right,
                                          color: Colors.grey, size: 20)
                                    ],
                                  ),
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
