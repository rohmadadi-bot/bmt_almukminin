import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'edit_anggota_page.dart';

// Import Halaman Detail Fasilitas
import 'detail_jual_beli_anggota_page.dart';
import 'detail_bagi_hasil_anggota_page.dart';
import 'detail_pinjaman_lunak_anggota_page.dart';
import 'detail_usaha_bersama_anggota_page.dart';

class DetailAnggotaPage extends StatefulWidget {
  final Map<String, dynamic> nasabah;

  const DetailAnggotaPage({super.key, required this.nasabah});

  @override
  State<DetailAnggotaPage> createState() => _DetailAnggotaPageState();
}

class _DetailAnggotaPageState extends State<DetailAnggotaPage> {
  final ApiService _apiService = ApiService();

  late Map<String, dynamic> _currentNasabah;
  double _saldoWadiah = 0;
  List<dynamic> _riwayatMutasi = [];

  // VARIABEL SUMMARY MURABAHAH (JUAL BELI)
  double _murabahahSisaKewajiban = 0;
  double _murabahahBebanBulanan = 0;
  int _murabahahBelumLunas = 0;
  int _murabahahSudahLunas = 0;

  // VARIABEL SUMMARY MUDHARABAH (BAGI HASIL)
  double _mudharabahTotalModal = 0;
  double _mudharabahTotalKeuntungan = 0;
  double _mudharabahKeuntunganBMT = 0;
  double _mudharabahKeuntunganNasabah = 0;

  // VARIABEL SUMMARY PINJAMAN LUNAK
  double _pinjamanTotalPlafond = 0;
  double _pinjamanSudahBayar = 0;
  double _pinjamanSisaTagihan = 0;

  // VARIABEL SUMMARY USAHA BERSAMA (INVESTASI)
  double _usahaTotalInvestasi = 0;
  double _usahaTotalKeuntungan = 0;

  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _currentNasabah = widget.nasabah;
    _refreshAllData();
  }

  Future<void> _refreshAllData() async {
    await _loadSaldoWadiah();
    await _loadMurabahahSummary();
    await _loadMudharabahSummary(); // <--- INI SUDAH DIPERBAIKI DI BAWAH
    await _loadPinjamanSummary();
    await _loadUsahaSummary();
  }

  // --- 1. LOAD SALDO WADIAH ---
  Future<void> _loadSaldoWadiah() async {
    try {
      int id = int.parse(_currentNasabah['id'].toString());
      final response = await _apiService.getWadiah(id);

      if (mounted && response['status'] == true) {
        setState(() {
          _saldoWadiah = double.parse(response['saldo'].toString());
          _riwayatMutasi = response['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error load saldo API: $e");
    }
  }

  // --- 2. LOAD SUMMARY MURABAHAH ---
  Future<void> _loadMurabahahSummary() async {
    try {
      final List<dynamic> allAkad = await _apiService.getAkadJualBeli();

      final myAkad = allAkad
          .where((item) =>
              item['nasabah_id'].toString() == _currentNasabah['id'].toString())
          .toList();

      double tempSisa = 0;
      double tempBeban = 0;
      int tempBelum = 0;
      int tempLunas = 0;

      for (var akad in myAkad) {
        double totalPiutang = double.parse(akad['total_piutang'].toString());
        double angsuranPerBulan =
            double.parse(akad['angsuran_bulanan'].toString());

        String status = akad['status'] ?? 'Pengajuan';

        if (status == 'Lunas') {
          tempLunas++;
        } else if (status == 'Disetujui' || status == 'Aktif') {
          tempBelum++;
          double sisaServer = akad['sisa_piutang'] != null
              ? double.parse(akad['sisa_piutang'].toString())
              : totalPiutang;

          tempSisa += sisaServer;
          tempBeban += angsuranPerBulan;
        }
      }

      if (mounted) {
        setState(() {
          _murabahahSisaKewajiban = tempSisa;
          _murabahahBebanBulanan = tempBeban;
          _murabahahBelumLunas = tempBelum;
          _murabahahSudahLunas = tempLunas;
        });
      }
    } catch (e) {
      debugPrint("Error load murabahah API: $e");
    }
  }

  // --- 3. LOAD SUMMARY MUDHARABAH (LOGIC LENGKAP) ---
  Future<void> _loadMudharabahSummary() async {
    try {
      // A. Ambil Daftar Akad
      final response = await _apiService.getMudharabah();

      if (response['status'] == true && response['data'] is List) {
        List<dynamic> allData = response['data'];

        var myAkad = allData
            .where((item) =>
                item['nasabah_id'].toString() ==
                _currentNasabah['id'].toString())
            .toList();

        double tempModal = 0;
        double tempKeuntungan = 0;
        double tempBMT = 0;
        double tempNasabah = 0;

        // B. Loop setiap Akad
        for (var akad in myAkad) {
          // 1. Hitung Modal
          String status = akad['status'] ?? '';
          if (status == 'Disetujui' ||
              status == 'Aktif' ||
              status == 'Berjalan') {
            tempModal += double.tryParse(akad['modal'].toString()) ??
                double.tryParse(akad['nominal_modal'].toString()) ??
                0;
          }

          // 2. Hitung Keuntungan (Panggil API Riwayat per Akad)
          try {
            int akadId = int.parse(akad['id'].toString());
            List<dynamic> riwayat =
                await _apiService.getRiwayatBagiHasil(akadId);

            for (var tr in riwayat) {
              tempKeuntungan +=
                  double.tryParse(tr['total_keuntungan'].toString()) ?? 0;
              tempBMT += double.tryParse(tr['bagian_bmt'].toString()) ?? 0;
              tempNasabah +=
                  double.tryParse(tr['bagian_nasabah'].toString()) ?? 0;
            }
          } catch (e) {
            debugPrint("Skip detail akad $e");
          }
        }

        if (mounted) {
          setState(() {
            _mudharabahTotalModal = tempModal;
            _mudharabahTotalKeuntungan = tempKeuntungan;
            _mudharabahKeuntunganBMT = tempBMT;
            _mudharabahKeuntunganNasabah = tempNasabah;
          });
        }
      }
    } catch (e) {
      debugPrint("Error load mudharabah API: $e");
    }
  }

// --- LOGIKA HITUNG SUMMARY PINJAMAN LUNAK (DIPERBAIKI) ---
  Future<void> _loadPinjamanSummary() async {
    try {
      // 1. Ambil Data Pinjaman dari API
      final response = await _apiService.getPinjamanLunak();

      if (response['status'] == true && response['data'] is List) {
        List<dynamic> allPinjaman = response['data'];

        // 2. Filter milik nasabah ini
        List<dynamic> myPinjaman = allPinjaman
            .where((item) =>
                item['nasabah_id'].toString() ==
                _currentNasabah['id'].toString())
            .toList();

        double tempPlafond = 0;
        double tempSisa = 0;
        double tempBayar = 0;

        for (var p in myPinjaman) {
          int pinjamanId = int.tryParse(p['id'].toString()) ?? 0;
          double nominal = double.tryParse(p['nominal'].toString()) ?? 0.0;
          String status = (p['status'] ?? '').toString().toLowerCase();

          // Hanya hitung yang aktif (Disetujui/Lunas)
          if (status == 'disetujui' || status == 'lunas' || status == 'aktif') {
            // --- LOGIKA UTAMA (Sesuai Halaman Detail Transaksi) ---
            // Ambil SISA REAL langsung dari Server (API)
            double sisaReal = 0;
            try {
              sisaReal = await _apiService.getSisaPinjaman(pinjamanId);
            } catch (e) {
              sisaReal = nominal; // Fallback jika error, dianggap belum bayar
            }

            // Hitung Sudah Bayar = Nominal - Sisa
            double bayarReal = nominal - sisaReal;

            // Pencegahan nilai minus jika data server tidak sinkron
            if (bayarReal < 0) bayarReal = 0;

            // Akumulasi ke Total Statistik
            tempPlafond += nominal;
            tempSisa += sisaReal;
            tempBayar += bayarReal;
          }
        }

        if (mounted) {
          setState(() {
            _pinjamanTotalPlafond = tempPlafond;
            _pinjamanSisaTagihan = tempSisa;
            _pinjamanSudahBayar = tempBayar; // Data ini sekarang akurat
          });
        }
      }
    } catch (e) {
      debugPrint("Error load pinjaman summary: $e");
    }
  }

  // --- 5. LOAD SUMMARY USAHA BERSAMA ---
  Future<void> _loadUsahaSummary() async {
    try {
      double tempInvestasi = 0;
      double tempKeuntungan = 0;

      // Ambil Modal (Harus filter dari semua usaha karena belum ada endpoint spesifik)
      final List<dynamic> allUsaha = await _apiService.getUsahaBersama();
      for (var usaha in allUsaha) {
        int usahaId = int.parse(usaha['id'].toString());
        final List<dynamic> pemodalList =
            await _apiService.getModalUsaha(usahaId);

        // Cari nama nasabah ini
        var myModal = pemodalList.where((p) =>
            p['nama_pemodal'].toString().toLowerCase() ==
            _currentNasabah['nama'].toString().toLowerCase());
        for (var m in myModal) {
          tempInvestasi += double.tryParse(m['jumlah_modal'].toString()) ?? 0;
        }
      }

      // Hitung Keuntungan dari Riwayat Wadiah
      for (var m in _riwayatMutasi) {
        if (m['keterangan'].toString().contains('Bagi Hasil')) {
          tempKeuntungan += double.parse(m['jumlah'].toString());
        }
      }

      if (mounted) {
        setState(() {
          _usahaTotalInvestasi = tempInvestasi;
          _usahaTotalKeuntungan = tempKeuntungan;
        });
      }
    } catch (e) {
      debugPrint("Error usaha summary: $e");
    }
  }

  Future<void> _refreshData() async {
    try {
      final allAnggota = await _apiService.getAllAnggota();
      final updatedData = allAnggota.firstWhere(
        (element) =>
            element['id'].toString() == _currentNasabah['id'].toString(),
        orElse: () => _currentNasabah,
      );

      setState(() => _currentNasabah = updatedData);
      await _refreshAllData();
    } catch (e) {
      debugPrint("Gagal refresh user: $e");
    }
  }

  void _showRiwayatMutasi() {
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Riwayat Mutasi Tabungan",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("${_riwayatMutasi.length} Transaksi",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _riwayatMutasi.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_edu,
                                    size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                const Text("Belum ada riwayat transaksi.",
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: _riwayatMutasi.length,
                            separatorBuilder: (ctx, i) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _riwayatMutasi[index];

                              String jenis = item['jenis'] ?? 'Transaksi';
                              double nominal =
                                  double.parse(item['jumlah'].toString());
                              String tanggal = item['tgl_transaksi'] ?? '-';

                              bool isMasuk = [
                                'Setoran',
                                'Setor Tunai',
                                'Bagi Hasil',
                                'Setoran Awal'
                              ].any((e) => jenis.contains(e));

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                leading: CircleAvatar(
                                  backgroundColor: isMasuk
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  child: Icon(
                                    isMasuk
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isMasuk ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                title: Text(jenis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(tanggal,
                                    style: const TextStyle(fontSize: 12)),
                                trailing: Text(
                                  "${isMasuk ? '+' : '-'} ${_formatter.format(nominal)}",
                                  style: TextStyle(
                                    color: isMasuk
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Detail Nasabah'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditAnggotaPage(nasabah: _currentNasabah)));
              if (result == true) _refreshData();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),

              const Text("KEUANGAN UTAMA",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),

              _buildWadiahCard(),
              const SizedBox(height: 15),

              _buildMurabahahCard(),
              const SizedBox(height: 15),

              // --- KARTU MUDHARABAH (YANG DATA-NYA SUDAH DIPERBAIKI) ---
              _buildMudharabahCard(),
              const SizedBox(height: 15),

              _buildPinjamanCard(),
              const SizedBox(height: 15),

              _buildUsahaCard(),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _konfirmasiHapus,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("Hapus Anggota Ini",
                      style: TextStyle(color: Colors.red)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF2E7D32),
            child: Text(_currentNasabah['nama'][0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_currentNasabah['nama'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text("NIK: ${_currentNasabah['nik'] ?? '-'}",
                  style: const TextStyle(color: Colors.grey)),
              Text("Telp: ${_currentNasabah['telepon'] ?? '-'}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildWadiahCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Saldo Simpanan", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 5),
          Text(_formatter.format(_saldoWadiah),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRiwayatMutasi,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.history),
              label: const Text("Lihat Riwayat Mutasi",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMurabahahCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3))
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF29B6F6), Color(0xFF039BE5)]),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailJualBeliAnggotaPage(
                    nasabahId: int.parse(_currentNasabah['id'].toString()),
                  ),
                ),
              ).then((_) => _refreshAllData());
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sisa Kewajiban Jual Beli",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text(_formatter.format(_murabahahSisaKewajiban),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Beban Bulanan",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(_formatter.format(_murabahahBebanBulanan),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: [
                                const Text("Belum",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 10)),
                                Text("$_murabahahBelumLunas",
                                    style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: [
                                const Text("Lunas",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 10)),
                                Text("$_murabahahSudahLunas",
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMudharabahCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3))
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)]),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DetailBagiHasilAnggotaPage(
                            nasabahId:
                                int.parse(_currentNasabah['id'].toString()))))
                .then((_) => _refreshAllData()),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Modal Bagi Hasil Disalurkan",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text(_formatter.format(_mudharabahTotalModal),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        const Text("Total Keuntungan (Omzet)",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(_formatter.format(_mudharabahTotalKeuntungan),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Keuntungan Nasabah",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                            Text(
                                _formatter.format(_mudharabahKeuntunganNasabah),
                                style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Masuk BMT",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                            Text(_formatter.format(_mudharabahKeuntunganBMT),
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinjamanCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3))
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFF57C00)]),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DetailPinjamanLunakAnggotaPage(
                            nasabahId:
                                int.parse(_currentNasabah['id'].toString()))))
                .then((_) => _refreshAllData()),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Pinjaman Lunak (Plafond)",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text(_formatter.format(_pinjamanTotalPlafond),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Sudah Dibayar",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(_formatter.format(_pinjamanSudahBayar),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Sisa Tagihan",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(_formatter.format(_pinjamanSisaTagihan),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsahaCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3))
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(
            color: Colors.teal,
          ),
          child: InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DetailUsahaBersamaAnggotaPage(
                        nasabahId: int.parse(_currentNasabah['id'].toString()),
                        namaNasabah: _currentNasabah['nama']))).then(
                (_) => _refreshAllData()),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Nilai Investasi Usaha Bersama",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text(_formatter.format(_usahaTotalInvestasi),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
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
                            Text(_formatter.format(_usahaTotalKeuntungan),
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
          ),
        ),
      ),
    );
  }

  void _konfirmasiHapus() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Anggota"),
            content: const Text(
                "Apakah Anda yakin? Data yang dihapus tidak dapat dikembalikan."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Hapus",
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        bool success = await _apiService
            .deleteAnggota(int.parse(_currentNasabah['id'].toString()));

        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Anggota berhasil dihapus")));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Gagal menghapus anggota. Cek API.")));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }
}
