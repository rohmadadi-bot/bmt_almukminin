import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// UBAH: Pastikan import ini benar ke file api_service.dart
import '../../../services/api_service.dart';

class PermodalanPage extends StatefulWidget {
  final Map<String, dynamic> usaha;

  const PermodalanPage({super.key, required this.usaha});

  @override
  State<PermodalanPage> createState() => _PermodalanPageState();
}

class _PermodalanPageState extends State<PermodalanPage> {
  final ApiService _apiService = ApiService();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<dynamic> _listModal = [];
  List<dynamic> _listAnggota = [];
  double _totalTerkumpul = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataAwal();
  }

  Future<void> _loadDataAwal() async {
    await _loadDataModal();
    await _loadDataAnggota();
  }

  Future<void> _loadDataAnggota() async {
    final data = await _apiService.getAllAnggota();
    if (mounted) {
      setState(() {
        _listAnggota = data;
      });
    }
  }

  Future<void> _loadDataModal() async {
    int usahaId = int.tryParse(widget.usaha['id'].toString()) ?? 0;
    final data = await _apiService.getModalUsaha(usahaId);

    double total = 0;
    for (var item in data) {
      total += double.tryParse(item['jumlah_modal'].toString()) ?? 0;
    }

    if (mounted) {
      setState(() {
        _listModal = data;
        _totalTerkumpul = total;
        _isLoading = false;
      });
    }
  }

  // --- LOGIKA KIRIM WA ---
  Future<void> _kirimWA(Map<String, dynamic> modalData) async {
    String rawPhone = modalData['telepon']?.toString() ?? "";

    if (rawPhone.isEmpty) {
      try {
        final anggota = _listAnggota.firstWhere(
            (element) => element['nama'] == modalData['nama_pemodal'],
            orElse: () => {});
        rawPhone = anggota['telepon']?.toString() ?? "";
      } catch (e) {
        // Ignore error
      }
    }

    if (rawPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nomor WA tidak ditemukan.")));
      }
      return;
    }

    String phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
    if (phone.startsWith('8')) phone = '62$phone';

    double jumlah = double.tryParse(modalData['jumlah_modal'].toString()) ?? 0;

    String pesan = "💰 *BUKTI SETORAN MODAL*\n"
        "🏛 *USAHA: ${widget.usaha['nama_usaha']}*\n"
        "--------------------------------\n"
        "Investor: ${modalData['nama_pemodal']}\n"
        "Tanggal : ${modalData['tgl_setor']}\n"
        "--------------------------------\n"
        "Jumlah  : *${_formatter.format(jumlah)}*\n"
        "--------------------------------\n"
        "_Terima kasih telah berinvestasi._";

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

  // --- LOGIKA HAPUS MODAL ---
  Future<void> _hapusModal(int id) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Modal"),
            content: const Text(
                "Yakin ingin menghapus data modal ini? Saldo terkumpul akan berkurang."),
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
      bool success = await _apiService.deleteModalUsaha(id);

      if (mounted) {
        if (success) {
          Navigator.pop(context); // Tutup Sheet Detail
          _loadDataModal(); // Refresh List
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Data modal berhasil dihapus")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Gagal menghapus data"),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  // --- 1. SEARCH NASABAH (BOTTOM SHEET) ---
  Future<Map<String, dynamic>?> _showSearchAnggotaSheet() {
    List<dynamic> filteredAnggota = List.from(_listAnggota);

    return showModalBottomSheet<Map<String, dynamic>>(
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
                        child: Text("Pilih Nasabah",
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
                          onChanged: (value) {
                            setStateSheet(() {
                              filteredAnggota = _listAnggota
                                  .where((anggota) => anggota['nama']
                                      .toString()
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filteredAnggota.isEmpty
                            ? const Center(
                                child: Text("Tidak ditemukan",
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filteredAnggota.length,
                                separatorBuilder: (ctx, i) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final item = filteredAnggota[i];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green[50],
                                      child: Text(
                                          (item['nama'] ?? '?')[0]
                                              .toUpperCase(),
                                          style: TextStyle(
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(item['nama'] ?? '-',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle:
                                        Text("NIK: ${item['nik'] ?? '-'}"),
                                    onTap: () => Navigator.pop(context,
                                        Map<String, dynamic>.from(item)),
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

  // --- 2. DETAIL MODAL (BOTTOM SHEET) ---
  void _showDetailModalSheet(Map<String, dynamic> item, double persentase) {
    int id = int.tryParse(item['id'].toString()) ?? 0;
    double jumlah = double.tryParse(item['jumlah_modal'].toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
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
                child: Icon(Icons.check, color: Color(0xFF2E7D32), size: 30),
              ),
              const SizedBox(height: 15),
              const Text("Detail Setoran Modal",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(height: 30),
              _detailRow("Nama Investor", item['nama_pemodal'] ?? '-'),
              _detailRow("Tanggal Setor", item['tgl_setor'] ?? '-'),
              _detailRow("Jumlah Modal", _formatter.format(jumlah),
                  isBold: true, color: const Color(0xFF2E7D32)),
              _detailRow("Kepemilikan",
                  "${(persentase * 100).toStringAsFixed(1)}% Saham (Estimasi)"),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _hapusModal(id),
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
                      onPressed: () => _kirimWA(item),
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
              )
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black87,
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  // --- 3. TAMBAH MODAL (BOTTOM SHEET) ---
  void _showTambahModalSheet() {
    final namaController = TextEditingController();
    final jumlahController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
              expand: false,
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
                              child: const Icon(Icons.savings,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Text("Tambah Pemodal",
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
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Pilih Investor / Anggota",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final result =
                                        await _showSearchAnggotaSheet();
                                    if (result != null) {
                                      setStateSheet(() {
                                        namaController.text = result['nama'];
                                      });
                                    }
                                  },
                                  child: IgnorePointer(
                                    child: TextFormField(
                                      controller: namaController,
                                      decoration: InputDecoration(
                                        hintText: "Ketuk untuk cari nasabah...",
                                        prefixIcon:
                                            const Icon(Icons.person_search),
                                        suffixIcon:
                                            const Icon(Icons.arrow_drop_down),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      validator: (val) => val!.isEmpty
                                          ? "Wajib pilih nasabah"
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text("Nominal Setoran",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: jumlahController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                      prefixText: "Rp ",
                                      hintText: "0",
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 15)),
                                  validator: (val) =>
                                      val!.isEmpty ? "Wajib diisi" : null,
                                ),
                              ],
                            ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                double jumlah = double.parse(jumlahController
                                    .text
                                    .replaceAll('.', '')
                                    .replaceAll(',', ''));

                                String tgl = DateFormat('dd/MM/yyyy')
                                    .format(DateTime.now());
                                int usahaId = int.tryParse(
                                        widget.usaha['id'].toString()) ??
                                    0;

                                // PANGGIL API INSERT
                                int id = await _apiService.insertModalUsaha({
                                  'usaha_id': usahaId,
                                  'nama_pemodal': namaController.text,
                                  'jumlah_modal': jumlah,
                                  'tgl_setor': tgl,
                                });

                                if (mounted) {
                                  if (id > 0) {
                                    Navigator.pop(context); // Tutup Input Sheet
                                    await _loadDataModal(); // Refresh Total

                                    // Siapkan data untuk Detail Sheet
                                    String telepon = "";
                                    try {
                                      var nasabah = _listAnggota.firstWhere(
                                          (e) =>
                                              e['nama'] == namaController.text);
                                      telepon = nasabah['telepon'] ?? "";
                                    } catch (e) {}

                                    Map<String, dynamic> newItem = {
                                      'id': id,
                                      'nama_pemodal': namaController.text,
                                      'jumlah_modal': jumlah,
                                      'tgl_setor': tgl,
                                      'telepon': telepon
                                    };

                                    // Hitung persentase baru
                                    double persentase = _totalTerkumpul > 0
                                        ? (jumlah / _totalTerkumpul)
                                        : 0.0;

                                    // Tampilkan Detail Sheet
                                    _showDetailModalSheet(newItem, persentase);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("Gagal Simpan Data"),
                                            backgroundColor: Colors.red));
                                  }
                                }
                              }
                            },
                            child: const Text("SIMPAN INVESTASI",
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

  @override
  Widget build(BuildContext context) {
    double modalAwal =
        double.tryParse(widget.usaha['modal_awal'].toString()) ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Permodalan Usaha"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Total Modal Terkumpul",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatter.format(_totalTerkumpul),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Target Awal: ${_formatter.format(modalAwal)}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listModal.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.savings_outlined,
                                size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            const Text("Belum ada pemodal",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _listModal.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _listModal[index];
                          // Parsing Map
                          Map<String, dynamic> itemMap =
                              Map<String, dynamic>.from(item);
                          double modalIni = double.tryParse(
                                  item['jumlah_modal'].toString()) ??
                              0;

                          double persentase = _totalTerkumpul > 0
                              ? (modalIni / _totalTerkumpul)
                              : 0.0;

                          return InkWell(
                            onTap: () =>
                                _showDetailModalSheet(itemMap, persentase),
                            borderRadius: BorderRadius.circular(12),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.orange[100],
                                      child: Text(
                                        (item['nama_pemodal'] ?? '?')[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                            color: Colors.orange[800],
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['nama_pemodal'] ?? '-',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatter.format(modalIni),
                                            style: const TextStyle(
                                                color: Color(0xFF2E7D32),
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: persentase,
                                              backgroundColor: Colors.grey[200],
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(Colors.orange),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      children: [
                                        Text(
                                          "${(persentase * 100).toStringAsFixed(1)}%",
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange),
                                        ),
                                        const Text("Saham",
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                      ],
                                    ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTambahModalSheet,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Pemodal",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
