import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/db_helper.dart';

class TabunganPage extends StatefulWidget {
  const TabunganPage({super.key});

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Variabel Statistik
  double _totalMasuk = 0;
  double _totalKeluar = 0;
  double _selisih = 0;
  List<Map<String, dynamic>> _riwayatList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load Data & Hitung Statistik
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = await _dbHelper.database;

    // Ambil Data Riwayat
    final List<Map<String, dynamic>> data = await db.rawQuery('''
      SELECT t.*, a.nama as nama_nasabah, a.telepon, a.id as real_nasabah_id
      FROM transaksi_wadiah t
      JOIN anggota a ON t.nasabah_id = a.id
      ORDER BY t.id DESC
    ''');

    // Hitung Total
    double masuk = 0;
    double keluar = 0;

    for (var item in data) {
      String jenis = item['jenis'] ?? '';
      double jumlah = (item['jumlah'] as num).toDouble();

      // Logika: Setoran/Masuk menambah, Penarikan mengurangi
      if (jenis == 'Setoran' ||
          jenis == 'Setor Tunai' ||
          jenis.contains('Masuk') ||
          jenis.contains('Bagi Hasil')) {
        masuk += jumlah;
      } else {
        keluar += jumlah;
      }
    }

    if (mounted) {
      setState(() {
        _riwayatList = data;
        _totalMasuk = masuk;
        _totalKeluar = keluar;
        _selisih = masuk - keluar;
        _isLoading = false;
      });
    }
  }

  // --- FUNGSI KIRIM WA ---
  void _kirimWhatsApp(
      String? telepon, String nama, Map<String, dynamic> data) async {
    if (telepon == null || telepon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor WA nasabah tidak tersedia!')));
      return;
    }

    String nomor = telepon.replaceAll(RegExp(r'[^0-9]'), '');
    if (nomor.startsWith('0')) {
      nomor = '62${nomor.substring(1)}';
    }

    // Ambil saldo terbaru untuk struk
    // Jika data['real_nasabah_id'] ada gunakan itu, jika tidak coba ambil dari nasabah_id
    int nasabahId = data['real_nasabah_id'] ?? data['nasabah_id'];
    double saldoTerbaru = await _dbHelper.getSaldoWadiah(nasabahId);

    String pesan = "✅ *BUKTI TRANSAKSI WADIAH BMT AL MUKMININ*\n"
        "--------------------------------\n"
        "Nasabah : $nama\n"
        "Jenis   : ${data['jenis']} - Wadiah\n"
        "Waktu   : ${data['tgl_transaksi']}\n"
        "Ket     : ${data['keterangan'] ?? '-'}\n"
        "--------------------------------\n"
        "💸 Jumlah  : ${_formatter.format(data['jumlah'])}\n"
        "💰 *SALDO AKHIR : ${_formatter.format(saldoTerbaru)}*\n"
        "--------------------------------\n"
        "_Terima kasih. Jazakumullah khairan._";

    var url =
        Uri.parse("https://wa.me/$nomor?text=${Uri.encodeComponent(pesan)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka WhatsApp')));
      }
    }
  }

  // --- FUNGSI HAPUS TRANSAKSI ---
  void _hapusTransaksi(int id) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Transaksi"),
            content: const Text(
                "Yakin ingin menghapus data ini? Saldo nasabah akan berubah."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text("Hapus", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final db = await _dbHelper.database;
      await db.delete('transaksi_wadiah', where: 'id = ?', whereArgs: [id]);
      _loadData(); // Refresh data
      if (mounted) {
        Navigator.pop(context); // Tutup Bottom Sheet
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transaksi berhasil dihapus")));
      }
    }
  }

  // --- SHOW DETAIL BOTTOM SHEET (Fixed Button) ---
  void _showDetailSheet(Map<String, dynamic> item) {
    bool isSetor = item['jenis'] == 'Setoran' ||
        item['jenis'] == 'Setor Tunai' ||
        (item['jenis'] ?? '').toString().contains('Bagi Hasil');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                isSetor ? Colors.green[100] : Colors.red[100],
                            child: Icon(
                              isSetor
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isSetor ? Colors.green : Colors.red,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(item['jenis'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 5),
                          Text(_formatter.format(item['jumlah']),
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isSetor
                                      ? Colors.green[700]
                                      : Colors.red[700])),
                          const SizedBox(height: 20),
                          const Divider(),
                          _detailRow("Nasabah", item['nama_nasabah']),
                          _detailRow("Waktu", item['tgl_transaksi']),
                          _detailRow("Keterangan", item['keterangan'] ?? '-'),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ]),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _hapusTransaksi(item['id']),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text("Hapus",
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _kirimWhatsApp(
                                  item['telepon'], item['nama_nasabah'], item),
                              icon:
                                  const Icon(Icons.share, color: Colors.white),
                              label: const Text("Kirim WA",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 1: PILIH NASABAH (BOTTOM SHEET) ---
  void _showPilihNasabahSheet() async {
    List<Map<String, dynamic>> allNasabah = await _dbHelper.getAllAnggota();
    List<Map<String, dynamic>> filteredNasabah = List.from(allNasabah);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text("Pilih Nasabah",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          autofocus: false,
                          decoration: InputDecoration(
                              hintText: 'Cari nama nasabah...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 10)),
                          onChanged: (value) {
                            setStateSheet(() {
                              filteredNasabah = allNasabah
                                  .where((n) => n['nama']
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // List Nasabah
                      Expanded(
                        child: filteredNasabah.isEmpty
                            ? const Center(child: Text('Tidak ditemukan'))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filteredNasabah.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final n = filteredNasabah[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      child: Text(n['nama'][0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ),
                                    title: Text(n['nama'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text('ID: ${n['nik'] ?? '-'}'),
                                    onTap: () {
                                      Navigator.pop(context); // Tutup Sheet 1
                                      _showInputNominalSheet(n); // Buka Sheet 2
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- STEP 2: INPUT NOMINAL (BOTTOM SHEET) ---
  void _showInputNominalSheet(Map<String, dynamic> nasabah) async {
    final TextEditingController nominalController = TextEditingController();
    final TextEditingController ketController = TextEditingController();
    String jenisTrx = 'Setoran';
    double saldoDulu = await _dbHelper.getSaldoWadiah(nasabah['id']);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            bool isSetoran = jenisTrx == 'Setoran';

            return Padding(
              // Handle Keyboard agar tombol tidak tertutup
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // Header Info
                    Text(nasabah['nama'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Saldo Saat Ini: ${_formatter.format(saldoDulu)}',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.green)),
                    const SizedBox(height: 20),

                    // Toggle Jenis
                    Row(
                      children: [
                        _buildTabButton(
                            setStateSheet, 'Setoran', isSetoran, Colors.green,
                            () {
                          setStateSheet(() => jenisTrx = 'Setoran');
                        }),
                        const SizedBox(width: 10),
                        _buildTabButton(
                            setStateSheet, 'Penarikan', !isSetoran, Colors.red,
                            () {
                          setStateSheet(() => jenisTrx = 'Penarikan');
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Input Form
                    TextField(
                      controller: nominalController,
                      keyboardType: TextInputType.number,
                      autofocus: true, // Langsung fokus agar siap ketik
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                          labelText: 'Nominal',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15)),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: ketController,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan (Opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Tombol Simpan
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSetoran ? Colors.green : Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          double nominal = double.tryParse(
                                  nominalController.text.replaceAll('.', '')) ??
                              0;
                          if (nominal <= 0) return;

                          if (!isSetoran && nominal > saldoDulu) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Saldo tidak mencukupi!')));
                            return;
                          }

                          Map<String, dynamic> data = {
                            'nasabah_id': nasabah['id'],
                            'jenis': jenisTrx,
                            'jumlah': nominal,
                            'keterangan': ketController.text,
                            'tgl_transaksi': DateFormat('dd/MM/yyyy HH:mm')
                                .format(DateTime.now()),
                          };

                          await _dbHelper.insertTransaksiWadiah(data);
                          if (mounted) {
                            Navigator.pop(context); // Tutup Sheet Input
                            _loadData(); // Refresh Halaman

                            // PANGGIL BOTTOM SHEET SUKSES DI SINI
                            _showSuccessSheet(nasabah, data);
                          }
                        },
                        child: const Text('SIMPAN TRANSAKSI',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- STEP 3: SUKSES TRANSAKSI (BOTTOM SHEET) ---
  void _showSuccessSheet(
      Map<String, dynamic> nasabah, Map<String, dynamic> data) async {
    // Ambil saldo terbaru setelah transaksi berhasil
    double saldoTerbaru = await _dbHelper.getSaldoWadiah(nasabah['id']);

    if (!mounted) return;

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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Sukses
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 15),
              const Text("Transaksi Berhasil!",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32))),
              const Divider(height: 30),

              // Detail Transaksi
              _detailRow("Nasabah", nasabah['nama']),
              _detailRow("Jenis", data['jenis']),
              _detailRow("Tanggal", data['tgl_transaksi']),
              const SizedBox(height: 10),
              _detailRow("Nominal", _formatter.format(data['jumlah'])),
              const SizedBox(height: 10),
              // Highlight Saldo Akhir
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Saldo Akhir:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_formatter.format(saldoTerbaru),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("TUTUP",
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _kirimWhatsApp(
                          nasabah['telepon'], nasabah['nama'], data),
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text("Kirim WA",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(StateSetter setStateSheet, String label, bool isActive,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? color : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tabungan Wadiah'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. HEADER STATISTICS
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text("Saldo Fisik (Selisih)",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 5),
                Text(
                  _formatter.format(_selisih),
                  style: const TextStyle(
                      fontSize: 32,
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
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            const Text("Total Masuk",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(_formatter.format(_totalMasuk),
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            const Text("Total Keluar",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(_formatter.format(_totalKeluar),
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // 2. TRANSACTION LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _riwayatList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                size: 70, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            const Text('Belum ada transaksi',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _riwayatList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final trx = _riwayatList[index];
                          final bool isSetor = trx['jenis'] == 'Setoran' ||
                              trx['jenis'] == 'Setor Tunai' ||
                              (trx['jenis'] ?? '')
                                  .toString()
                                  .contains('Bagi Hasil');

                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    isSetor ? Colors.green[50] : Colors.red[50],
                                child: Icon(
                                  isSetor
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isSetor ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(trx['nama_nasabah'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(trx['tgl_transaksi'],
                                      style: const TextStyle(fontSize: 12)),
                                  if (trx['keterangan'] != null &&
                                      trx['keterangan'].toString().isNotEmpty)
                                    Text(trx['keterangan'],
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                ],
                              ),
                              trailing: Text(
                                _formatter.format(trx['jumlah']),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSetor
                                        ? Colors.green[700]
                                        : Colors.red[700]),
                              ),
                              onTap: () => _showDetailSheet(trx),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      // --- UPDATE: TOMBOL TRANSAKSI MEMBUKA SHEET ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: _showPilihNasabahSheet, // Menggunakan Sheet Baru
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Transaksi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
