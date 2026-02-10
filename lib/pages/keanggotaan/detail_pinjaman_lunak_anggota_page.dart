import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class DetailPinjamanLunakAnggotaPage extends StatefulWidget {
  final int nasabahId;
  const DetailPinjamanLunakAnggotaPage({super.key, required this.nasabahId});

  @override
  State<DetailPinjamanLunakAnggotaPage> createState() =>
      _DetailPinjamanLunakAnggotaPageState();
}

class _DetailPinjamanLunakAnggotaPageState
    extends State<DetailPinjamanLunakAnggotaPage> {
  final ApiService _apiService = ApiService();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _dataPinjaman = [];
  bool _isLoading = true;

  // Variabel Header Statistik
  double _totalPinjamanDisalurkan = 0; // Total Plafond
  double _totalCicilanMasuk = 0; // Sudah Bayar (Dihitung dari Plafond - Sisa)
  double _totalSisaTagihan = 0; // Sisa Hutang (Dari Server)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() => _isLoading = true);
    }

    try {
      // Reset variabel hitungan
      double tempTotalPinjaman = 0;
      double tempTotalCicilan = 0;
      double tempTotalSisa = 0;
      List<Map<String, dynamic>> processedList = [];

      // 1. Ambil Semua Data Pinjaman
      final response = await _apiService.getPinjamanLunak();

      if (response['status'] == true && response['data'] is List) {
        List<dynamic> allPinjaman = response['data'];

        // 2. Filter milik nasabah ini saja
        List<dynamic> myPinjaman = allPinjaman
            .where((item) =>
                item['nasabah_id'].toString() == widget.nasabahId.toString())
            .toList();

        // 3. Loop setiap pinjaman
        for (var p in myPinjaman) {
          int pinjamanId = int.tryParse(p['id'].toString()) ?? 0;
          double nominal = double.tryParse(p['nominal'].toString()) ?? 0.0;
          String status = p['status'] ?? 'Pengajuan';

          // --- LOGIKA UTAMA (Sesuai Referensi Sheet Sukses) ---
          // Kita ambil SISA TAGIHAN langsung dari server agar akurat.
          // Rumus: Sudah Bayar = Nominal - Sisa Server.

          double sisaReal = 0;
          double sudahBayarHitungan = 0;

          // Cek status agar tidak menghitung yang Ditolak/Pengajuan
          String statusCheck = status.toLowerCase();
          bool isAktif = (statusCheck == 'disetujui' ||
              statusCheck == 'lunas' ||
              statusCheck == 'aktif');

          if (isAktif) {
            try {
              // Panggil API getSisaPinjaman (Data paling update dari server)
              sisaReal = await _apiService.getSisaPinjaman(pinjamanId);

              // Hitung yang sudah dibayar
              sudahBayarHitungan = nominal - sisaReal;
              if (sudahBayarHitungan < 0) sudahBayarHitungan = 0; // Cegah minus

              // Tambahkan ke Total Header
              tempTotalPinjaman += nominal;
              tempTotalSisa += sisaReal;
              tempTotalCicilan += sudahBayarHitungan;
            } catch (e) {
              debugPrint("Gagal ambil sisa ID $pinjamanId: $e");
              // Fallback: anggap sisa = nominal jika error
              sisaReal = nominal;
            }
          } else {
            // Jika status Pengajuan/Ditolak, anggap sisa = nominal (belum jalan)
            sisaReal = nominal;
          }

          // Simpan data untuk list card
          var newItem = Map<String, dynamic>.from(p);
          newItem['sisa'] = sisaReal;
          newItem['sudah_bayar'] = sudahBayarHitungan;
          newItem['nominal_angka'] = nominal;

          processedList.add(newItem);
        }

        if (mounted) {
          setState(() {
            _dataPinjaman = processedList;

            // Update Header dengan hasil akumulasi
            _totalPinjamanDisalurkan = tempTotalPinjaman;
            _totalSisaTagihan = tempTotalSisa;
            _totalCicilanMasuk = tempTotalCicilan;

            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error load data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SHOW RIWAYAT CICILAN ---
  void _showRiwayatCicilan(Map<String, dynamic> pinjaman) async {
    try {
      int pinjamanId = int.parse(pinjaman['id'].toString());
      final List riwayat =
          await _apiService.getRiwayatCicilanPinjaman(pinjamanId);

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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Riwayat Cicilan",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(pinjaman['deskripsi'] ?? 'Pinjaman',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                              "Total Pinjaman: ${_formatter.format(pinjaman['nominal_angka'] ?? 0)}",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.orange)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: riwayat.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long,
                                      size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  const Text("Belum ada data cicilan",
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
                                double bayar = double.tryParse(
                                        item['jumlah_bayar'].toString()) ??
                                    0.0;
                                String tgl = item['tgl_bayar'] ?? '-';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange[50],
                                    child: const Icon(Icons.download_done,
                                        color: Colors.orange, size: 20),
                                  ),
                                  title: Text(_formatter.format(bayar),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(tgl),
                                );
                              },
                            ),
                    ),
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
                                  color: Colors.orange)),
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
        const SnackBar(content: Text("Gagal memuat riwayat cicilan")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Pinjaman Lunak"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData(isRefresh: true);
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // --- HEADER SUMMARY ---
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text("Total Pinjaman (Plafond)",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 5),
                          Text(
                            _formatter.format(_totalPinjamanDisalurkan),
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Sudah Dibayar",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatter.format(_totalCicilanMasuk),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Sisa Tagihan",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatter.format(_totalSisaTagihan),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
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
                        child: Text("Riwayat Akad",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // --- LIST PINJAMAN ---
                    _dataPinjaman.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: const Center(
                                child: Text("Tidak ada riwayat pinjaman",
                                    style: TextStyle(color: Colors.grey))),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _dataPinjaman.length,
                            separatorBuilder: (ctx, i) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _dataPinjaman[index];
                              double nominal = item['nominal_angka'] ?? 0.0;
                              double sisa = item['sisa'] ?? 0.0;
                              // Hitung paid di level item juga agar tampil di list
                              double paid = nominal - sisa;
                              if (paid < 0) paid = 0;

                              String status = item['status'] ?? 'Pengajuan';

                              Color statusColor = Colors.grey;
                              if (status == 'Disetujui')
                                statusColor = Colors.orange;
                              if (status == 'Lunas') statusColor = Colors.green;
                              if (status == 'Ditolak') statusColor = Colors.red;

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: statusColor.withOpacity(0.5))),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showRiwayatCicilan(item),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                  item['deskripsi'] ??
                                                      'Pinjaman',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: statusColor,
                                                  borderRadius:
                                                      BorderRadius.circular(5)),
                                              child: Text(status,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(item['tgl_pengajuan'] ?? '-',
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                        const Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text("Total Pinjaman",
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey)),
                                                Text(_formatter.format(nominal),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500)),
                                              ],
                                            ),
                                            // Menampilkan Sisa Tagihan di Kanan
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text("Sisa Tagihan",
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey)),
                                                Text(_formatter.format(sisa),
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: sisa <= 0
                                                            ? Colors.green
                                                            : Colors.red)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        // Opsional: Menampilkan progress bar pembayaran
                                        if (nominal > 0) ...[
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: (nominal - sisa) / nominal,
                                            backgroundColor: Colors.grey[200],
                                            color: Colors.orange,
                                            minHeight: 4,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Terbayar: ${_formatter.format(paid)}",
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          )
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}
