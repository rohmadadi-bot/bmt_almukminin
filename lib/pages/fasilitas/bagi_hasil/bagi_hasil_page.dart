import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// UBAH: Gunakan ApiService
import '../../../services/api_service.dart';
import 'menu_bagi_hasil_page.dart';

class BagiHasilPage extends StatefulWidget {
  const BagiHasilPage({super.key});

  @override
  State<BagiHasilPage> createState() => _BagiHasilPageState();
}

class _BagiHasilPageState extends State<BagiHasilPage> {
  // UBAH: Inisialisasi ApiService
  final ApiService _apiService = ApiService();

  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<dynamic> _listMudharabah = [];
  List<dynamic> _listAnggota = []; // Data Nasabah dari API
  bool _isLoading = true;

  // Variabel Statistik Header
  double _totalDanaTerserap = 0;
  int _countAktif = 0;
  int _countPengajuan = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAnggota();
  }

  // LOAD DATA DARI API
  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final result = await _apiService.getMudharabah();

      if (mounted) {
        if (result['status'] == true) {
          final stats = result['stats'];
          final data = result['data'] ?? [];

          setState(() {
            _listMudharabah = data;

            // Parsing Statistik Aman
            if (stats != null) {
              _totalDanaTerserap =
                  double.tryParse(stats['total_dana'].toString()) ?? 0;
              _countAktif = int.tryParse(stats['aktif'].toString()) ?? 0;
              _countPengajuan =
                  int.tryParse(stats['pengajuan'].toString()) ?? 0;
            }

            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnggota() async {
    final data = await _apiService.getAllAnggota();
    if (mounted) {
      setState(() {
        _listAnggota = data;
      });
    }
  }

  // --- 1. SEARCH NASABAH (BOTTOM SHEET - ONLINE) ---
  Future<dynamic> _showSearchAnggotaSheet() {
    List<dynamic> filtered = List.from(_listAnggota);
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
                        child: Text("Pilih Nasabah",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          autofocus: false,
                          decoration: InputDecoration(
                              hintText: "Cari nama nasabah...",
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
                              filtered = _listAnggota
                                  .where((a) => a['nama']
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
                                child: Text("Tidak ditemukan",
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (ctx, i) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final item = filtered[i];
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
                                    subtitle: Text("ID: ${item['nik'] ?? '-'}"),
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

  // --- 2. TAMBAH AKAD (BOTTOM SHEET - ONLINE) ---
  void _showTambahSheet() {
    final namaUsahaController = TextEditingController();
    final deskripsiController = TextEditingController();
    final nominalController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Map<String, dynamic>? selectedNasabah; // Perbaikan Tipe
    String? namaNasabahTampil;
    String selectedNisbah = '60 : 40';

    final List<String> opsiNisbah = [
      '70 : 30',
      '60 : 40',
      '50 : 50',
      '40 : 60',
      '30 : 70'
    ];

    Future<void> prosesSimpan(String statusSimpan) async {
      if (formKey.currentState!.validate() && selectedNasabah != null) {
        // Parsing
        double nominal = double.tryParse(nominalController.text
                .replaceAll('.', '')
                .replaceAll(',', '')) ??
            0;
        List<String> parts = selectedNisbah.split(' : ');
        double nNasabah = double.parse(parts[0]);
        double nBmt = double.parse(parts[1]);

        int nasabahId = int.tryParse(selectedNasabah!['id'].toString()) ?? 0;

        // UBAH: Kirim ke API
        int newId = await _apiService.insertMudharabah({
          'nasabah_id': nasabahId,
          'nama_usaha': namaUsahaController.text,
          'deskripsi_usaha': deskripsiController.text,
          'nominal_modal': nominal,
          'nisbah_nasabah': nNasabah,
          'nisbah_bmt': nBmt,
          'tgl_akad':
              DateFormat('yyyy-MM-dd').format(DateTime.now()), // Format SQL
          'status': statusSimpan
        });

        if (mounted) {
          if (newId > 0) {
            Navigator.pop(context); // Tutup Sheet
            _loadData(); // Refresh list

            // Data untuk pindah halaman
            Map<String, dynamic> newData = {
              'id': newId,
              'nasabah_id': nasabahId,
              'nama_nasabah': selectedNasabah!['nama'],
              'nama_usaha': namaUsahaController.text,
              'deskripsi_usaha': deskripsiController.text,
              'nominal_modal': nominal,
              'nisbah_nasabah': nNasabah,
              'nisbah_bmt': nBmt,
              'tgl_akad': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              'status': statusSimpan
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MenuBagiHasilPage(akadData: newData),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Gagal menyimpan data ke Server"),
                backgroundColor: Colors.red));
          }
        }
      } else if (selectedNasabah == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Pilih Nasabah dulu!")));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
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
                      // Header Hijau
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
                              child: const Icon(Icons.handshake,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Akad Baru",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text("Mudharabah (Bagi Hasil)",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            )
                          ],
                        ),
                      ),

                      // Form Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Nasabah Pengelola",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.grey)),
                                const SizedBox(height: 5),
                                InkWell(
                                  onTap: () async {
                                    final result =
                                        await _showSearchAnggotaSheet();
                                    if (result != null) {
                                      setStateSheet(() {
                                        selectedNasabah =
                                            Map<String, dynamic>.from(result);
                                        namaNasabahTampil = result['nama'];
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 15),
                                    decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.person,
                                            color: selectedNasabah == null
                                                ? Colors.grey
                                                : Colors.green),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            namaNasabahTampil ??
                                                "Pilih Nasabah...",
                                            style: TextStyle(
                                                color: namaNasabahTampil == null
                                                    ? Colors.grey
                                                    : Colors.black87,
                                                fontWeight:
                                                    namaNasabahTampil == null
                                                        ? FontWeight.normal
                                                        : FontWeight.bold),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down,
                                            color: Colors.grey)
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Text("Informasi Usaha",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.grey)),
                                const SizedBox(height: 5),
                                _buildInput(namaUsahaController, "Nama Usaha",
                                    Icons.store),
                                const SizedBox(height: 10),
                                _buildInput(deskripsiController,
                                    "Rencana/Deskripsi", Icons.description,
                                    maxLines: 2),
                                const SizedBox(height: 15),
                                const Text("Skema Keuangan",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.grey)),
                                const SizedBox(height: 5),
                                _buildInput(
                                    nominalController,
                                    "Modal Pengajuan (Rp)",
                                    Icons.monetization_on,
                                    isNumber: true),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedNisbah,
                                      isExpanded: true,
                                      icon: const Icon(Icons.pie_chart_outline),
                                      items: opsiNisbah
                                          .map((val) => DropdownMenuItem(
                                              value: val,
                                              child: Text("$val %",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null)
                                          setStateSheet(
                                              () => selectedNisbah = val);
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, left: 5),
                                  child: Row(
                                    children: [
                                      Text(
                                          "Nasabah: ${selectedNisbah.split(' : ')[0]}%",
                                          style: TextStyle(
                                              color: Colors.blue[800],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 15),
                                      Text(
                                          "BMT: ${selectedNisbah.split(' : ')[1]}%",
                                          style: TextStyle(
                                              color: Colors.green[800],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Footer Buttons
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration:
                            BoxDecoration(color: Colors.white, boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5))
                        ]),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => prosesSimpan('Pengajuan'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange[800],
                                    side:
                                        BorderSide(color: Colors.orange[800]!),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: const Text("AJUKAN DRAFT",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => prosesSimpan('Disetujui'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: const Text("DISETUJUI (ACC)",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
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

  Widget _buildInput(
      TextEditingController controller, String hint, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        prefixText: isNumber ? "Rp " : null,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E7D32))),
      ),
      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Mudharabah (Bagi Hasil)"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- HEADER DASHBOARD ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Dana Terserap",
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 5),
                Text(_formatter.format(_totalDanaTerserap),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.greenAccent[100], size: 16),
                                const SizedBox(width: 5),
                                const Text("Akad Aktif",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("$_countAktif",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_filled,
                                    color: Colors.orangeAccent, size: 16),
                                const SizedBox(width: 5),
                                const Text("Pengajuan",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("$_countPengajuan",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- SECTION TITLE ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Daftar Akad",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10)),
                  child: Text("${_listMudharabah.length} Total",
                      style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- LIST DATA ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadData(),
                    child: _listMudharabah.isEmpty
                        ? ListView(
                            // Wrap with ListView to allow pull refresh on empty
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.15),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.handshake_outlined,
                                        size: 80, color: Colors.grey[300]),
                                    const SizedBox(height: 15),
                                    const Text("Belum ada akad",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 16)),
                                    const SizedBox(height: 5),
                                    const Text(
                                        "Tekan tombol + untuk membuat akad baru",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              )
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _listMudharabah.length,
                            separatorBuilder: (ctx, i) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _listMudharabah[index];
                              String status = item['status'] ?? 'Pengajuan';
                              double modal = double.tryParse(
                                      item['nominal_modal'].toString()) ??
                                  0;
                              double nisbahN = double.tryParse(
                                      item['nisbah_nasabah'].toString()) ??
                                  0;
                              double nisbahB = double.tryParse(
                                      item['nisbah_bmt'].toString()) ??
                                  0;

                              // --- LOGIKA WARNA STATUS ---
                              Color statusColor;
                              Color bgStatus;

                              if (status == 'Disetujui') {
                                statusColor =
                                    const Color(0xFF2E7D32); // Hijau Tua
                                bgStatus = Colors.green[50]!;
                              } else if (status == 'Ditolak') {
                                statusColor = Colors.red[800]!; // Merah
                                bgStatus = Colors.red[50]!;
                              } else if (status == 'Selesai') {
                                statusColor = Colors.blueGrey[800]!; // Abu-abu
                                bgStatus = Colors.blueGrey[50]!;
                              } else {
                                // Default: Pengajuan
                                statusColor =
                                    Colors.orange[800]!; // Kuning/Orange
                                bgStatus = Colors.orange[50]!;
                              }

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(color: Colors.grey[200]!)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                MenuBagiHasilPage(
                                                    akadData: item)));
                                    _loadData(); // Refresh list saat kembali
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: const Icon(Icons.store,
                                                  color: Colors.blue),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      item['nama_usaha'] ??
                                                          'Tanpa Nama',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16)),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                      item['nama_nasabah'] ??
                                                          '-',
                                                      style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                  color: bgStatus,
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: Text(status,
                                                  style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11)),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        const Divider(height: 1),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text("Modal Usaha",
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey)),
                                                Text(_formatter.format(modal),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text("Bagi Hasil (N:B)",
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey)),
                                                Text(
                                                    "${nisbahN.toInt()} : ${nisbahB.toInt()}",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14)),
                                              ],
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
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
        onPressed: _showTambahSheet,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 4,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text("Akad Baru",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
