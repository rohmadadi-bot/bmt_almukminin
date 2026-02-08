import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart'; // Ganti DbHelper dengan ApiService

class DetailJualBeliAnggotaPage extends StatefulWidget {
  final int nasabahId;
  const DetailJualBeliAnggotaPage({super.key, required this.nasabahId});

  @override
  State<DetailJualBeliAnggotaPage> createState() =>
      _DetailJualBeliAnggotaPageState();
}

class _DetailJualBeliAnggotaPageState extends State<DetailJualBeliAnggotaPage> {
  // 1. Inisialisasi API Service
  final ApiService _apiService = ApiService();

  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<dynamic> _listAkad = []; // Ubah ke List<dynamic>
  bool _isLoading = true;

  // Variabel Header Summary
  double _totalSisaKewajiban = 0;
  double _totalAngsuranBulanan = 0;
  int _countBelumLunas = 0;
  int _countSudahLunas = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- 2. LOAD DATA DARI API ---
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _totalSisaKewajiban = 0;
      _totalAngsuranBulanan = 0;
      _countBelumLunas = 0;
      _countSudahLunas = 0;
      _listAkad = [];
    });

    try {
      // Ambil semua data akad jual beli dari server
      final List<dynamic> allAkad = await _apiService.getAkadJualBeli();

      // Filter hanya milik nasabah ini
      final List<dynamic> myAkad = allAkad
          .where((item) =>
              item['nasabah_id'].toString() == widget.nasabahId.toString())
          .toList();

      List<Map<String, dynamic>> processedList = [];
      double tempTotalSisa = 0;
      double tempAngsuranBulanan = 0;
      int tempBelum = 0;
      int tempLunas = 0;

      for (var akad in myAkad) {
        try {
          // Parsing data angka dengan aman
          double totalPiutang = double.parse(akad['total_piutang'].toString());
          double angsuranPerBulan =
              double.parse(akad['angsuran_bulanan'].toString());

          // Cek apakah API mengirimkan 'sisa_piutang' atau 'sudah_bayar'
          // Jika belum ada, kita estimasi dari Status atau hitungan manual jika ada fieldnya
          double sudahBayar = 0;
          double sisa = totalPiutang;

          if (akad['sudah_bayar'] != null) {
            sudahBayar = double.parse(akad['sudah_bayar'].toString());
            sisa = totalPiutang - sudahBayar;
          } else if (akad['sisa_piutang'] != null) {
            sisa = double.parse(akad['sisa_piutang'].toString());
            sudahBayar = totalPiutang - sisa;
          } else {
            // Fallback jika API tidak mengirim sisa/bayar
            // Jika status lunas, sisa 0. Jika tidak, sisa full (krn blm ada data bayar detail di list ini)
            if (akad['status'] == 'Lunas') {
              sisa = 0;
              sudahBayar = totalPiutang;
            }
          }

          // Tentukan Status Lunas (Bisa dari field 'status' atau sisa hutang)
          bool isLunas = (akad['status'] == 'Lunas') || (sisa <= 100);

          if (isLunas) {
            tempLunas++;
            sisa = 0; // Pastikan 0 jika lunas
          } else {
            // Hanya hitung status Aktif/Disetujui ke dalam tanggungan
            if (akad['status'] == 'Disetujui' || akad['status'] == 'Aktif') {
              tempBelum++;
              tempTotalSisa += sisa;
              tempAngsuranBulanan += angsuranPerBulan;
            }
          }

          // Buat Map baru untuk UI
          var newItem = Map<String, dynamic>.from(akad);
          newItem['sisa_real'] = sisa;
          newItem['sudah_bayar'] = sudahBayar;
          newItem['is_lunas'] = isLunas;
          newItem['angsuran_bulanan'] = angsuranPerBulan;
          newItem['total_piutang'] = totalPiutang;

          processedList.add(newItem);
        } catch (e) {
          debugPrint("Error parsing akad: $e");
        }
      }

      if (mounted) {
        setState(() {
          _listAkad = processedList;
          _totalSisaKewajiban = tempTotalSisa;
          _totalAngsuranBulanan = tempAngsuranBulanan;
          _countBelumLunas = tempBelum;
          _countSudahLunas = tempLunas;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Utama Load Data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data: $e")),
        );
      }
    }
  }

  // --- 3. SHOW RINCIAN BAYAR (API VERSION) ---
  void _showRincianBayar(Map<String, dynamic> akad) async {
    try {
      // Panggil fungsi baru di ApiService
      // Pastikan 'id' sudah integer
      int akadId = int.parse(akad['id'].toString());
      final riwayat = await _apiService.getRiwayatAngsuranMurabahah(akadId);

      if (!mounted) return;

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

                    // Header Detail
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Rincian Pembayaran",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(akad['nama_barang'] ?? 'Barang',
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
                                  Icon(Icons.receipt,
                                      size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  const Text("Belum ada pembayaran cicilan",
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
                                // Parse data dari JSON (String/Num)
                                double bayar = double.parse(
                                    item['jumlah_bayar'].toString());
                                String tgl = item['tgl_bayar'] ?? '-';

                                // Cek angsuran ke berapa
                                String labelAngsuran = "";
                                if (item['angsuran_ke'] != null) {
                                  labelAngsuran = "Ke-${item['angsuran_ke']}";
                                }

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.lightBlue[50],
                                    child: const Icon(Icons.check_circle,
                                        color: Colors.lightBlue, size: 20),
                                  ),
                                  title: Text(_formatter.format(bayar),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(tgl),
                                  trailing: labelAngsuran.isNotEmpty
                                      ? Text(labelAngsuran,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey))
                                      : null,
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
                              style: TextStyle(fontWeight: FontWeight.bold)),
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
      debugPrint("Error detail bayar: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Gagal membuka rincian")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Detail Jual Beli"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- 1. HEADER SUMMARY ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.lightBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Total Sisa Kewajiban
                      const Text("Total Sisa Kewajiban",
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 5),
                      Text(
                        _formatter.format(_totalSisaKewajiban),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),

                      const SizedBox(height: 15),

                      // INFORMASI CICILAN BULANAN
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            const Text("Beban Bulanan: ",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(_formatter.format(_totalAngsuranBulanan),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Status Counter
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                children: [
                                  const Text("Belum Lunas",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                  Text("$_countBelumLunas Barang",
                                      style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                children: [
                                  const Text("Sudah Lunas",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                  Text("$_countSudahLunas Barang",
                                      style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
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
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Riwayat Akad Barang",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 14)),
                  ),
                ),

                // --- 2. LIST AKAD ---
                Expanded(
                  child: _listAkad.isEmpty
                      ? const Center(
                          child: Text("Tidak ada riwayat Jual Beli",
                              style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _listAkad.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _listAkad[index];
                            final bool lunas = item['is_lunas'];

                            // Hitung progress bar (0.0 - 1.0)
                            double total =
                                double.parse(item['total_piutang'].toString());
                            double bayar =
                                double.parse(item['sudah_bayar'].toString());
                            double progress =
                                (total == 0) ? 0.0 : (bayar / total);

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: lunas
                                          ? Colors.green.withOpacity(0.5)
                                          : Colors.lightBlue.withOpacity(0.5))),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showRincianBayar(item),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.shopping_bag,
                                                  color: lunas
                                                      ? Colors.green
                                                      : Colors.lightBlue),
                                              const SizedBox(width: 10),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 150),
                                                child: Text(
                                                    item['nama_barang'] ??
                                                        'Barang',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16)),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: lunas
                                                  ? Colors.green
                                                  : Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              lunas ? "LUNAS" : "BELUM LUNAS",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
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
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("Angsuran/bln",
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                              Text(
                                                  _formatter.format(
                                                      item['angsuran_bulanan']),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text("Sisa Tagihan",
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                              Text(
                                                  _formatter.format(
                                                      item['sisa_real']),
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: lunas
                                                          ? Colors.green
                                                          : Colors.red)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      // Progress Bar Kecil
                                      LinearProgressIndicator(
                                        value: progress > 1.0 ? 1.0 : progress,
                                        backgroundColor: Colors.grey[200],
                                        color: lunas
                                            ? Colors.green
                                            : Colors.lightBlue,
                                        minHeight: 4,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      const SizedBox(height: 2),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          "Terbayar: ${_formatter.format(bayar)} / ${_formatter.format(total)}",
                                          style: const TextStyle(
                                              fontSize: 10, color: Colors.grey),
                                        ),
                                      )
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
