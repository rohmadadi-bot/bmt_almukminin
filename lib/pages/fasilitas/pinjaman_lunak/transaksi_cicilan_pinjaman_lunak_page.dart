import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// UBAH: Pastikan import ini mengarah ke file api_service.dart Anda
import '../../../services/api_service.dart';

class TransaksiCicilanPinjamanLunakPage extends StatefulWidget {
  const TransaksiCicilanPinjamanLunakPage({super.key});

  @override
  State<TransaksiCicilanPinjamanLunakPage> createState() =>
      _TransaksiCicilanPinjamanLunakPageState();
}

class _TransaksiCicilanPinjamanLunakPageState
    extends State<TransaksiCicilanPinjamanLunakPage> {
  // UBAH: Inisialisasi ApiService
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // Data List & Statistik
  List<dynamic> _riwayatCicilan = [];
  List<dynamic> _listPeminjamAktif = [];

  double _totalPinjamanDisetujui = 0;
  double _totalCicilanMasuk = 0;
  double _sisaUangTerpinjam = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- 1. LOAD DATA ---
  Future<void> _loadData({bool isRefresh = true}) async {
    if (!isRefresh) {
      setState(() => _isLoading = true);
    }

    try {
      // 1. Ambil Riwayat & Statistik
      final result = await _apiService.getTransaksiCicilanPinjaman();

      // 2. Ambil List Peminjam Aktif (Untuk Dropdown)
      final peminjam = await _apiService.getPeminjamAktif();

      if (mounted) {
        if (result['status'] == true) {
          final stats = result['stats'];
          _riwayatCicilan = result['riwayat'] ?? [];
          _listPeminjamAktif = peminjam;

          if (stats != null) {
            _totalPinjamanDisetujui =
                double.tryParse(stats['total_pinjaman'].toString()) ?? 0;
            _totalCicilanMasuk =
                double.tryParse(stats['total_cicilan'].toString()) ?? 0;
            _sisaUangTerpinjam = _totalPinjamanDisetujui - _totalCicilanMasuk;
          }
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. FITUR WA ---
  Future<void> _launchWhatsApp(String phone, String message) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nomor HP tidak tersedia")));
      return;
    }
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.startsWith('0'))
      formattedPhone = "62${formattedPhone.substring(1)}";
    if (formattedPhone.startsWith('8')) formattedPhone = "62$formattedPhone";

    final Uri url = Uri.parse(
        "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal membuka WhatsApp")));
      }
    }
  }

  // --- 3. HAPUS CICILAN (ONLINE) ---
  Future<void> _hapusCicilan(int id) async {
    bool success = await _apiService.deleteCicilanPinjaman(id);

    if (mounted) {
      if (success) {
        Navigator.pop(context); // Tutup Sheet Detail
        _loadData(isRefresh: true); // Refresh List
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data cicilan berhasil dihapus")));
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Gagal menghapus data"),
            backgroundColor: Colors.red));
      }
    }
  }

  // --- 4. DETAIL SHEET ---
  void _showDetailCicilanSheet(Map<String, dynamic> item) {
    int id = int.tryParse(item['id'].toString()) ?? 0;
    double jumlah = double.tryParse(item['jumlah_bayar'].toString()) ?? 0;
    int pinjamanId = int.tryParse(item['pinjaman_id'].toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
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
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.receipt_long,
                      color: Color(0xFF2E7D32), size: 30),
                ),
                const SizedBox(height: 15),
                const Text("Detail Pembayaran",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(height: 30),
                _buildDetailRow("Nama Nasabah", item['nama_nasabah'] ?? '-'),
                _buildDetailRow("Tanggal", item['tgl_bayar'] ?? '-'),
                _buildDetailRow("Keterangan", item['keterangan'] ?? '-'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      const Text("Jumlah Masuk",
                          style: TextStyle(fontSize: 12, color: Colors.green)),
                      const SizedBox(height: 5),
                      Text(_currencyFormatter.format(jumlah),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.green)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                    title: const Text("Hapus Transaksi?"),
                                    content: const Text(
                                        "Data ini akan dihapus permanen dan saldo outstanding akan bertambah kembali."),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Batal")),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _hapusCicilan(id);
                                          },
                                          child: const Text("Hapus",
                                              style: TextStyle(
                                                  color: Colors.red))),
                                    ],
                                  ));
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("Hapus",
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Ambil Sisa Terbaru (Online)
                          double sisaSaatIni =
                              await _apiService.getSisaPinjaman(pinjamanId);

                          String msg = "✅ *BUKTI PEMBAYARAN CICILAN*\n"
                              "🏛 *BMT AL MUKMININ*\n"
                              "----------------------------------\n"
                              "Nasabah : ${item['nama_nasabah']}\n"
                              "Ket     : ${item['keterangan'] ?? '-'}\n"
                              "Tanggal : ${item['tgl_bayar']}\n"
                              "----------------------------------\n"
                              "💰 *BAYAR : ${_currencyFormatter.format(jumlah)}*\n"
                              "📉 *SISA  : ${_currencyFormatter.format(sisaSaatIni)}*\n"
                              "----------------------------------\n"
                              "Terima kasih.";

                          _launchWhatsApp(item['telepon'] ?? '', msg);
                        },
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text("Kirim WA",
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 5. SEARCH NASABAH ---
  Future<dynamic> _showSearchPeminjamSheet() {
    List<dynamic> filtered = List.from(_listPeminjamAktif);

    return showModalBottomSheet(
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
                        child: Text("Pilih Peminjam",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          autofocus: false,
                          decoration: InputDecoration(
                              hintText: "Cari nama...",
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 15)),
                          onChanged: (val) {
                            setStateSheet(() {
                              filtered = _listPeminjamAktif
                                  .where((a) => a['nama_nasabah']
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
                            ? const Center(
                                child: Text("Tidak ada peminjam aktif",
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (ctx, i) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final item = filtered[i];
                                  double nominal = double.tryParse(
                                          item['nominal'].toString()) ??
                                      0;
                                  return ListTile(
                                    title: Text(item['nama_nasabah'] ?? '-',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        "Keperluan: ${item['deskripsi']}\nPinjaman: ${_currencyFormatter.format(nominal)}"),
                                    isThreeLine: true,
                                    onTap: () => Navigator.pop(context, item),
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

  // --- 6. INPUT CICILAN ---
  void _showInputCicilanSheet() {
    final formKey = GlobalKey<FormState>();
    final nominalController = TextEditingController();
    final ketController =
        TextEditingController(text: "Angsuran Pinjaman Lunak");

    Map<String, dynamic>? selectedPeminjam;
    String? namaTampil;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                            child: const Icon(Icons.input, color: Colors.white),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Text("Input Cicilan Masuk",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () async {
                                final result = await _showSearchPeminjamSheet();
                                if (result != null) {
                                  setStateSheet(() {
                                    selectedPeminjam =
                                        Map<String, dynamic>.from(result);
                                    namaTampil = result['nama_nasabah'];
                                  });
                                }
                              },
                              child: IgnorePointer(
                                child: TextFormField(
                                  key: Key(namaTampil ?? 'peminjam'),
                                  initialValue: namaTampil,
                                  decoration: InputDecoration(
                                      labelText: "Nama Peminjam",
                                      hintText: "Klik cari...",
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      prefixIcon:
                                          const Icon(Icons.person_search),
                                      suffixIcon:
                                          const Icon(Icons.arrow_drop_down),
                                      filled: true,
                                      fillColor: Colors.grey[50]),
                                  validator: (val) => selectedPeminjam == null
                                      ? "Wajib pilih"
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: nominalController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                  labelText: "Nominal Masuk",
                                  prefixText: "Rp ",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  prefixIcon: const Icon(Icons.monetization_on),
                                  filled: true,
                                  fillColor: Colors.grey[50]),
                              validator: (val) =>
                                  val!.isEmpty ? "Wajib diisi" : null,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: ketController,
                              decoration: InputDecoration(
                                labelText: "Keterangan",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.note),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          onPressed: () async {
                            if (formKey.currentState!.validate() &&
                                selectedPeminjam != null) {
                              double nominal = double.parse(nominalController
                                  .text
                                  .replaceAll('.', '')
                                  .replaceAll(',', ''));
                              String tglDB = DateFormat('yyyy-MM-dd')
                                  .format(DateTime.now());
                              int pinjamanId = int.tryParse(
                                      selectedPeminjam!['id'].toString()) ??
                                  0;

                              final response =
                                  await _apiService.insertCicilanPinjaman({
                                'pinjaman_id': pinjamanId,
                                'tgl_bayar': tglDB,
                                'jumlah_bayar': nominal,
                                'keterangan': ketController.text,
                              });

                              if (mounted) {
                                if (response['status'] == true) {
                                  double sisaTerbaru = double.tryParse(
                                          response['sisa_terbaru']
                                              .toString()) ??
                                      0;

                                  Navigator.pop(context); // Tutup Sheet Input
                                  _loadData(
                                      isRefresh:
                                          true); // Refresh Data Dashboard

                                  _showSuccessSheet(
                                    nama: selectedPeminjam!['nama_nasabah'],
                                    barang: selectedPeminjam!['deskripsi'],
                                    nominal: nominal,
                                    sisa: sisaTerbaru,
                                    telepon: selectedPeminjam!['telepon'],
                                    tgl: DateFormat('dd MMM yyyy')
                                        .format(DateTime.now()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Gagal Simpan Data"),
                                          backgroundColor: Colors.red));
                                }
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
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 7. SUKSES SHEET ---
  void _showSuccessSheet({
    required String nama,
    required String barang,
    required double nominal,
    required double sisa,
    required String? telepon,
    required String tgl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20))),
                  child: Column(
                    children: [
                      const CircleAvatar(
                          radius: 35,
                          backgroundColor: Color(0xFF2E7D32),
                          child:
                              Icon(Icons.check, size: 40, color: Colors.white)),
                      const SizedBox(height: 15),
                      const Text("Transaksi Berhasil",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(tgl,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDetailRow("Nasabah", nama),
                      _buildDetailRow("Keperluan", barang),
                      const Divider(height: 25),
                      _buildDetailRow(
                          "Bayar", _currencyFormatter.format(nominal),
                          isBold: true, color: Colors.green),
                      _buildDetailRow(
                          "Sisa Pinjaman", _currencyFormatter.format(sisa),
                          isBold: true, color: Colors.red),
                    ],
                  ),
                ),
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
                          onPressed: () {
                            String msg =
                                "✅ *BUKTI PEMBAYARAN CICILAN PINJAMAN LUNAK (QARDHUL HASAN)*\n"
                                "🏛 *BMT AL MUKMININ*\n"
                                "----------------------------------------------\n"
                                "Nasabah : $nama\n"
                                "Keperluan  : $barang\n"
                                "Tanggal : $tgl\n"
                                "----------------------------------------------\n"
                                "💰 *BAYAR : ${_currencyFormatter.format(nominal)}*\n"
                                "📉 *SISA  : ${_currencyFormatter.format(sisa)}*\n"
                                "----------------------------------------------\n"
                                "Terima kasih. Jazakumullah khairan.";
                            _launchWhatsApp(telepon ?? '', msg);
                          },
                          icon: const Icon(Icons.share, color: Colors.white),
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
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black87,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          _currencyFormatter.format(value),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Transaksi Cicilan"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // HEADER SUMMARY
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
                const Text("Sisa Uang Terpinjam (Outstanding)",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(
                  _currencyFormatter.format(_sisaUangTerpinjam),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildSummaryItem(
                            "Total Disetujui", _totalPinjamanDisetujui)),
                    Container(width: 1, height: 40, color: Colors.white30),
                    Expanded(
                        child: _buildSummaryItem(
                            "Total Masuk", _totalCicilanMasuk)),
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
              child: Text("Riwayat Cicilan Masuk",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),

          // LIST RIWAYAT
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => await _loadData(isRefresh: true),
                    child: _riwayatCicilan.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.history,
                                        size: 60, color: Colors.grey[300]),
                                    const SizedBox(height: 10),
                                    const Text("Belum ada transaksi cicilan",
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _riwayatCicilan.length,
                            separatorBuilder: (ctx, i) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _riwayatCicilan[index];
                              // Parsing Aman
                              double jumlah = double.tryParse(
                                      item['jumlah_bayar'].toString()) ??
                                  0;

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  onTap: () => _showDetailCicilanSheet(
                                      item), // BUKA DETAIL SAAT KLIK LIST
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[50],
                                    child: const Icon(Icons.download,
                                        color: Colors.blue),
                                  ),
                                  title: Text(
                                    item['nama_nasabah'] ?? 'Tanpa Nama',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['tgl_bayar'] ?? '-'),
                                      Text(item['keterangan'] ?? '-',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                  trailing: Text(
                                    _currencyFormatter.format(jumlah),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInputCicilanSheet,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Cicilan",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
