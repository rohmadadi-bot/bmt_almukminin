import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// UBAH: Pastikan import ini mengarah ke file api_service.dart Anda
import '../../../services/api_service.dart';

class TransaksiCicilanJualBeliPage extends StatefulWidget {
  const TransaksiCicilanJualBeliPage({super.key});

  @override
  State<TransaksiCicilanJualBeliPage> createState() =>
      _TransaksiCicilanJualBeliPageState();
}

class _TransaksiCicilanJualBeliPageState
    extends State<TransaksiCicilanJualBeliPage> {
  // 1. Inisialisasi ApiService
  final ApiService _apiService = ApiService();

  final _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // Variable State
  List<dynamic> _riwayatList = [];
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

  // --- FUNGSI LOAD DATA (API) ---
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Panggil API
      final result = await _apiService.getTransaksiJualBeli();

      // DEBUG: Cek Data di Console
      print("API Transaksi Status: ${result['status']}");

      if (mounted) {
        if (result['status'] == true) {
          final stats = result['stats'];
          // Pastikan data berupa List, kalau null kasih list kosong
          final List<dynamic> dataList =
              (result['data'] as List<dynamic>?) ?? [];

          setState(() {
            _riwayatList = dataList;

            // Parsing Statistik Aman
            if (stats != null) {
              _totalAkadDisetujui =
                  double.tryParse(stats['total_piutang'].toString()) ?? 0;
              _potensiKeuntungan =
                  double.tryParse(stats['total_margin'].toString()) ?? 0;
              _totalCicilanMasuk =
                  double.tryParse(stats['total_masuk'].toString()) ?? 0;
              _totalBelumTercicil =
                  double.tryParse(stats['sisa_piutang'].toString()) ?? 0;
            } else {
              // Reset jika stats null (misal DB kosong)
              _totalAkadDisetujui = 0;
              _potensiKeuntungan = 0;
              _totalCicilanMasuk = 0;
              _totalBelumTercicil = 0;
            }

            _isLoading = false;
          });
        } else {
          // Jika status false (error server)
          print("API Error: ${result['message']}");
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print("Error Koneksi Load Data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPER WA ---
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

    double bayar = double.tryParse(item['jumlah_bayar'].toString()) ?? 0;

    String pesan = "✅ *BUKTI PEMBAYARAN CICILAN*\n"
        "🏛 *BMT AL MUKMININ*\n"
        "--------------------------------\n"
        "Nasabah : *${item['nama_nasabah']}*\n"
        "Barang  : ${item['nama_barang']}\n"
        "Tanggal : ${item['tgl_bayar']}\n"
        "--------------------------------\n"
        "💰 *BAYAR : ${_formatter.format(bayar)}*\n"
        "--------------------------------\n"
        "_Terima kasih. Jazakumullah khairan._";

    final String url =
        "https://wa.me/$phone?text=${Uri.encodeComponent(pesan)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // --- HAPUS TRANSAKSI (API) ---
  void _hapusTransaksi(int id) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Transaksi"),
            content: const Text(
                "Yakin ingin menghapus pembayaran ini dari SERVER? Sisa hutang nasabah akan bertambah kembali."),
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
      // Panggil API Delete
      bool success = await _apiService.deleteCicilan(id);

      if (mounted) {
        if (success) {
          Navigator.pop(context); // Tutup Bottom Sheet Detail
          _loadData(); // Refresh List
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Transaksi berhasil dihapus dari Server")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Gagal menghapus"), backgroundColor: Colors.red));
        }
      }
    }
  }

  // --- SHOW DETAIL RIWAYAT (BOTTOM SHEET) ---
  void _showDetailBottomSheet(Map<String, dynamic> item) {
    // Parsing ID & Jumlah aman
    int idTransaksi = int.tryParse(item['id'].toString()) ?? 0;
    double jumlahBayar = double.tryParse(item['jumlah_bayar'].toString()) ?? 0;

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
            _buildDetailRow("Nasabah", item['nama_nasabah'] ?? '-'),
            _buildDetailRow("Barang", item['nama_barang'] ?? '-'),
            _buildDetailRow("Tanggal", item['tgl_bayar'] ?? '-'),
            const Divider(height: 30),
            Text(_formatter.format(jumlahBayar),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32))),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _hapusTransaksi(idTransaksi),
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

  // --- STEP 1: CARI NASABAH (BOTTOM SHEET - API) ---
  void _showCariNasabahSheet() async {
    // Ambil Data Akad Aktif dari API
    List<dynamic> allAkad = await _apiService.getAkadAktifForBayar();

    // Grouping Data by Nasabah (Manual Logic)
    Map<int, List<dynamic>> groupedData = {};
    for (var item in allAkad) {
      int nId = int.tryParse(item['nasabah_id'].toString()) ?? 0;
      if (!groupedData.containsKey(nId)) groupedData[nId] = [];
      groupedData[nId]!.add(item);
    }

    List<List<dynamic>> listNasabah = groupedData.values.toList();
    List<List<dynamic>> filtered = List.from(listNasabah);

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
                      child: Text("Pilih Nasabah (Online)",
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
                                        (firstItem['nama_nasabah'] ?? '?')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(firstItem['nama_nasabah'] ?? '-',
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
  void _showFormPembayaranSheet(List<dynamic> nasabahAkads) {
    List<dynamic> selectedItems = List.from(nasabahAkads);

    double hitungTotal() {
      return selectedItems.fold(0, (sum, item) {
        double angsuran =
            double.tryParse(item['angsuran_bulanan'].toString()) ?? 0;
        return sum + angsuran;
      });
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
                            Text(nasabahAkads.first['nama_nasabah'] ?? '-',
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
                      double angsuran = double.tryParse(
                              item['angsuran_bulanan'].toString()) ??
                          0;

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
                                    Text(item['nama_barang'] ?? '-',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Text(
                                        "Cicilan: ${_formatter.format(angsuran)}",
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
                                    // Tampilkan Loading
                                    showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (ctx) => const Center(
                                            child:
                                                CircularProgressIndicator()));

                                    int suksesCount = 0;

                                    // LOOP KIRIM DATA KE API
                                    for (var akad in selectedItems) {
                                      int akadId =
                                          int.tryParse(akad['id'].toString()) ??
                                              0;
                                      double jumlah = double.tryParse(
                                              akad['angsuran_bulanan']
                                                  .toString()) ??
                                          0;

                                      bool berhasil =
                                          await _apiService.inputBayarCicilan({
                                        'akad_id': akadId,
                                        'jumlah_bayar': jumlah,
                                        // FORMAT TANGGAL SQL (yyyy-MM-dd HH:mm:ss)
                                        'tgl_bayar':
                                            DateFormat('yyyy-MM-dd HH:mm:ss')
                                                .format(DateTime.now()),
                                        'keterangan': 'Cicilan Murabahah',
                                      });

                                      if (berhasil) suksesCount++;
                                    }

                                    if (mounted) {
                                      Navigator.pop(context); // Tutup Loading

                                      if (suksesCount > 0) {
                                        Navigator.pop(
                                            context); // Tutup Sheet Input
                                        _loadData(); // Refresh Data Dashboard
                                        _showSuccessBottomSheet(
                                            selectedItems, currentTotal);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    "Gagal Simpan Data. Cek Koneksi/DB."),
                                                backgroundColor: Colors.red));
                                      }
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
  void _showSuccessBottomSheet(List<dynamic> akads, double totalBayar) {
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
                      _buildReceiptRow(
                          "Nasabah", akads.first['nama_nasabah'] ?? '-',
                          isBold: true),
                      const Divider(height: 25),
                      const Text("Rincian:",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      ...akads.map((e) {
                        double jumlah =
                            double.tryParse(e['angsuran_bulanan'].toString()) ??
                                0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(e['nama_barang'] ?? '-',
                                      style: const TextStyle(fontSize: 14))),
                              Text(_formatter.format(jumlah),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 25),
                      _buildReceiptRow(
                          "TOTAL DITERIMA", _formatter.format(totalBayar),
                          isBold: true,
                          size: 18,
                          color: const Color(0xFF2E7D32)),
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
                              double jml = double.tryParse(
                                      item['angsuran_bulanan'].toString()) ??
                                  0;
                              listBarang +=
                                  "- ${item['nama_barang']} (${_formatter.format(jml)})\n";
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
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _riwayatList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.1),
                              const Center(
                                child: Text('Belum ada transaksi cicilan.',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _riwayatList.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final trx = _riwayatList[index];
                              // Parsing Jumlah Bayar aman
                              double bayar = double.tryParse(
                                      trx['jumlah_bayar'].toString()) ??
                                  0;

                              return InkWell(
                                onTap: () => _showDetailBottomSheet(trx),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
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
                                    title: Text(
                                        trx['nama_nasabah'] ?? 'Nasabah',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(trx['nama_barang'] ?? '-',
                                            style: const TextStyle(
                                                color: Colors.black87)),
                                        Text(trx['tgl_bayar'] ?? '-',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                    trailing: Text(_formatter.format(bayar),
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
