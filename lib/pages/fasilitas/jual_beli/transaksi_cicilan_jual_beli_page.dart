import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/db_helper.dart';

class TransaksiCicilanJualBeliPage extends StatefulWidget {
  const TransaksiCicilanJualBeliPage({super.key});

  @override
  State<TransaksiCicilanJualBeliPage> createState() =>
      _TransaksiCicilanJualBeliPageState();
}

class _TransaksiCicilanJualBeliPageState
    extends State<TransaksiCicilanJualBeliPage> {
  final _dbHelper = DbHelper();
  final _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _riwayatList = [];
  double _totalAkadDisetujui = 0;
  double _totalCicilanMasuk = 0;
  double _totalBelumTercicil = 0;
  double _potensiKeuntungan = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = await _dbHelper.database;

    final riwayat = await db.rawQuery('''
      SELECT ang.*, ak.nama_barang, angt.nama as nama_nasabah, angt.telepon, angt.id as nasabah_id
      FROM murabah_angsuran ang
      JOIN murabahah_akad ak ON ang.akad_id = ak.id
      JOIN anggota angt ON ak.nasabah_id = angt.id
      ORDER BY ang.id DESC
    ''');

    final akadStats = await db.rawQuery('''
      SELECT SUM(total_piutang) as total_piutang, SUM(margin) as total_margin 
      FROM murabahah_akad 
      WHERE status = 'Aktif' OR status = 'Disetujui' OR status = 'Lunas'
    ''');

    final angsuranStats = await db.rawQuery('''
      SELECT SUM(jumlah_bayar) as total_masuk FROM murabah_angsuran
    ''');

    double totalPiutang =
        (akadStats.first['total_piutang'] as num?)?.toDouble() ?? 0.0;
    double totalMargin =
        (akadStats.first['total_margin'] as num?)?.toDouble() ?? 0.0;
    double totalMasuk =
        (angsuranStats.first['total_masuk'] as num?)?.toDouble() ?? 0.0;

    if (mounted) {
      setState(() {
        _riwayatList = riwayat;
        _totalAkadDisetujui = totalPiutang;
        _potensiKeuntungan = totalMargin;
        _totalCicilanMasuk = totalMasuk;
        _totalBelumTercicil = totalPiutang - totalMasuk;
        _isLoading = false;
      });
    }
  }

  String _formatPhone(String rawPhone) {
    String digitsOnly = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.startsWith('0')) return '62${digitsOnly.substring(1)}';
    if (digitsOnly.startsWith('8')) return '62$digitsOnly';
    return digitsOnly;
  }

  void _kirimWASingle(Map<String, dynamic> item) async {
    String phone = _formatPhone(item['telepon'] ?? '');
    if (phone.length < 10) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Nomor WA tidak valid")));
      return;
    }

    String pesan = "✅ *BUKTI PEMBAYARAN CICILAN*\n"
        "🏛 *BMT AL MUKMININ*\n"
        "--------------------------------\n"
        "Nasabah : *${item['nama_nasabah']}*\n"
        "Barang  : ${item['nama_barang']}\n"
        "Tanggal : ${item['tgl_bayar']}\n"
        "--------------------------------\n"
        "💰 *BAYAR : ${_formatter.format(item['jumlah_bayar'])}*\n"
        "--------------------------------\n"
        "_Terima kasih. Jazakumullah khairan._";

    final String url =
        "https://wa.me/$phone?text=${Uri.encodeComponent(pesan)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _hapusTransaksi(int id) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Transaksi"),
            content: const Text(
                "Yakin ingin menghapus pembayaran ini? Sisa hutang nasabah akan bertambah kembali."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Hapus",
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final db = await _dbHelper.database;
      await db.delete('murabah_angsuran', where: 'id = ?', whereArgs: [id]);
      if (mounted) {
        Navigator.pop(context); // Tutup Bottom Sheet Detail
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transaksi berhasil dihapus")));
      }
    }
  }

  // --- SHOW DETAIL RIWAYAT (BOTTOM SHEET) ---
  void _showDetailBottomSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            const Text("Detail Pembayaran",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            _buildDetailRow("Nasabah", item['nama_nasabah']),
            _buildDetailRow("Barang", item['nama_barang']),
            _buildDetailRow("Tanggal", item['tgl_bayar']),
            const Divider(height: 30),
            Text(_formatter.format(item['jumlah_bayar']),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32))),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _hapusTransaksi(item['id']),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Hapus",
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _kirimWASingle(item),
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text("Kirim WA",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- STEP 1: CARI NASABAH (BOTTOM SHEET) ---
  void _showCariNasabahSheet() async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> allAkad = await db.rawQuery('''
      SELECT m.*, a.nama as nama_nasabah, a.telepon 
      FROM murabahah_akad m
      JOIN anggota a ON m.nasabah_id = a.id
      WHERE m.status = 'Disetujui' OR m.status = 'Aktif'
      ORDER BY a.nama ASC
    ''');

    Map<int, List<Map<String, dynamic>>> groupedData = {};
    for (var item in allAkad) {
      int nId = item['nasabah_id'];
      if (!groupedData.containsKey(nId)) groupedData[nId] = [];
      groupedData[nId]!.add(item);
    }
    List<List<Map<String, dynamic>>> listNasabah = groupedData.values.toList();
    List<List<Map<String, dynamic>>> filtered = List.from(listNasabah);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: InputDecoration(
                            hintText: 'Cari nama nasabah...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: EdgeInsets.zero),
                        onChanged: (val) {
                          setStateSheet(() {
                            filtered = listNasabah
                                .where((list) => list.first['nama_nasabah']
                                    .toString()
                                    .toLowerCase()
                                    .contains(val.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text("Tidak ditemukan"))
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                var nasabahData = filtered[i];
                                var firstItem = nasabahData.first;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[50],
                                    child: Text(
                                        firstItem['nama_nasabah'][0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(firstItem['nama_nasabah'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      "${nasabahData.length} Barang Cicilan"),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showFormPembayaranSheet(nasabahData);
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
      ),
    );
  }

  // --- STEP 2: INPUT BAYAR (BOTTOM SHEET) ---
  void _showFormPembayaranSheet(List<Map<String, dynamic>> nasabahAkads) {
    List<Map<String, dynamic>> selectedItems = List.from(nasabahAkads);

    double hitungTotal() {
      return selectedItems.fold(
          0, (sum, item) => sum + (item['angsuran_bulanan'] as num).toDouble());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          double currentTotal = hitungTotal();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header Hijau
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Pilih Tagihan",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text(nasabahAkads.first['nama_nasabah'],
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white))
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: nasabahAkads.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = nasabahAkads[i];
                      final isChecked = selectedItems.contains(item);
                      return InkWell(
                        onTap: () {
                          setStateSheet(() {
                            if (isChecked)
                              selectedItems.remove(item);
                            else
                              selectedItems.add(item);
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: isChecked
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey[300]!,
                                width: isChecked ? 2 : 1),
                            borderRadius: BorderRadius.circular(12),
                            color: isChecked
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  isChecked
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isChecked
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['nama_barang'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Text(
                                        "Cicilan: ${_formatter.format(item['angsuran_bulanan'])}",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -4),
                          blurRadius: 10)
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Bayar",
                                style: TextStyle(color: Colors.grey)),
                            Text(_formatter.format(currentTotal),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: selectedItems.isEmpty
                                ? null
                                : () async {
                                    for (var akad in selectedItems) {
                                      await _dbHelper.insertAngsuran({
                                        'akad_id': akad['id'],
                                        'jumlah_bayar':
                                            (akad['angsuran_bulanan'] as num)
                                                .toDouble(),
                                        'tgl_bayar':
                                            DateFormat('dd/MM/yyyy HH:mm')
                                                .format(DateTime.now()),
                                        'keterangan': 'Cicilan Murabahah',
                                      });
                                    }
                                    if (mounted) {
                                      Navigator.pop(context); // Tutup Input
                                      _loadData(); // Refresh Data
                                      _showSuccessBottomSheet(
                                          selectedItems, currentTotal);
                                    }
                                  },
                            child: const Text("BAYAR SEKARANG",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // --- STEP 3: SUKSES (BOTTOM SHEET) ---
  void _showSuccessBottomSheet(
      List<Map<String, dynamic>> akads, double totalBayar) {
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
              // Header dengan Icon Besar
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
                    const Text("Pembayaran Berhasil",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),

              // Rincian Pembayaran
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReceiptRow("Nasabah", akads.first['nama_nasabah'],
                          isBold: true),
                      const Divider(height: 25),
                      const Text("Rincian:",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      ...akads.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: Text(e['nama_barang'],
                                        style: const TextStyle(fontSize: 14))),
                                Text(_formatter.format(e['angsuran_bulanan']),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )),
                      const Divider(height: 25),
                      _buildReceiptRow(
                          "TOTAL DITERIMA", _formatter.format(totalBayar),
                          isBold: true, size: 18, color: Color(0xFF2E7D32)),
                    ],
                  ),
                ),
              ),

              // Tombol Aksi
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10)
                ]),
                child: SafeArea(
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
                          onPressed: () {
                            Navigator.pop(context);
                            // Logic WA
                            String rawPhone =
                                akads.first['telepon']?.toString() ?? "";
                            String phone = _formatPhone(rawPhone);
                            if (phone.length < 10) return;

                            String listBarang = "";
                            for (var item in akads) {
                              listBarang +=
                                  "- ${item['nama_barang']} (${_formatter.format(item['angsuran_bulanan'])})\n";
                            }

                            String pesan = "✅ *BUKTI PEMBAYARAN CICILAN*\n"
                                "🏛 *BMT AL MUKMININ*\n"
                                "--------------------------------\n"
                                "Nasabah : *${akads.first['nama_nasabah']}*\n"
                                "Tanggal : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}\n"
                                "--------------------------------\n"
                                "Rincian:\n$listBarang"
                                "--------------------------------\n"
                                "💰 *TOTAL : ${_formatter.format(totalBayar)}*\n"
                                "--------------------------------\n"
                                "_Terima kasih_";

                            launchUrl(
                                Uri.parse(
                                    "https://wa.me/$phone?text=${Uri.encodeComponent(pesan)}"),
                                mode: LaunchMode.externalApplication);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.send,
                              size: 18, color: Colors.white),
                          label: const Text("KIRIM WA",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool isBold = false, double size = 14, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: size, color: Colors.black54)),
        Text(value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: size,
                color: color ?? Colors.black87)),
      ],
    );
  }

  Widget _buildHeaderItem(String label, double value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(
          _formatter.format(value),
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          title: const Text('Transaksi Jual Beli'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0),
      body: Column(
        children: [
          // HEADER
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
                Row(
                  children: [
                    Expanded(
                        child: _buildHeaderItem(
                            "Total Akad Disetujui", _totalAkadDisetujui)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildHeaderItem(
                            "Potensi Keuntungan", _potensiKeuntungan,
                            color: Colors.yellowAccent)),
                  ],
                ),
                const SizedBox(height: 15),
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
                            const Text("Total Cicilan Masuk",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(_formatter.format(_totalCicilanMasuk),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
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
                            const Text("Total Belum Tercicil",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(_formatter.format(_totalBelumTercicil),
                                style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _riwayatList.isEmpty
                    ? const Center(
                        child: Text('Belum ada transaksi cicilan.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _riwayatList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final trx = _riwayatList[index];
                          return InkWell(
                            onTap: () => _showDetailBottomSheet(trx),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                    backgroundColor: Colors.orange[50],
                                    child: const Icon(Icons.receipt_long,
                                        color: Colors.orange)),
                                title: Text(trx['nama_nasabah'] ?? 'Nasabah',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(trx['nama_barang'],
                                        style: const TextStyle(
                                            color: Colors.black87)),
                                    Text(trx['tgl_bayar'],
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                trailing: Text(
                                    _formatter.format(trx['jumlah_bayar']),
                                    style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCariNasabahSheet,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Transaksi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
