import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/db_helper.dart';
import 'detail_akad_pinjaman_lunak_page.dart';

class AkadPinjamanLunakPage extends StatefulWidget {
  const AkadPinjamanLunakPage({super.key});

  @override
  State<AkadPinjamanLunakPage> createState() => _AkadPinjamanLunakPageState();
}

class _AkadPinjamanLunakPageState extends State<AkadPinjamanLunakPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _listPinjaman = [];
  List<Map<String, dynamic>> _listAnggota = [];
  bool _isLoading = true;

  // Variabel Header Summary
  double _totalDanaDipinjamkan = 0;
  int _countDisetujui = 0;
  int _countDiajukan = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAnggota();
  }

  // --- 1. LOAD DATA DARI DATABASE ---
  Future<void> _loadData() async {
    final data = await _dbHelper.getAllPinjamanLunak();

    double totalDana = 0;
    int cSetuju = 0;
    int cAju = 0;

    for (var item in data) {
      if (item['status'] == 'Disetujui' || item['status'] == 'Lunas') {
        totalDana += (item['nominal'] as num).toDouble();
        cSetuju++;
      } else if (item['status'] == 'Pengajuan') {
        cAju++;
      }
    }

    if (mounted) {
      setState(() {
        _listPinjaman = data;
        _totalDanaDipinjamkan = totalDana;
        _countDisetujui = cSetuju;
        _countDiajukan = cAju;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnggota() async {
    final data = await _dbHelper.getAllAnggota();
    setState(() {
      _listAnggota = data;
    });
  }

  // --- 2. LOGIKA UPDATE STATUS (BOTTOM SHEET) ---
  void _showStatusConfirmationSheet(int id, String currentStatus) {
    String newStatus =
        (currentStatus == 'Pengajuan') ? 'Disetujui' : 'Pengajuan';
    String actionText =
        (newStatus == 'Disetujui') ? "Menyetujui" : "Membatalkan persetujuan";
    Color actionColor =
        (newStatus == 'Disetujui') ? const Color(0xFF2E7D32) : Colors.orange;

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
              const Text("Konfirmasi Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Apakah Anda yakin ingin $actionText akad ini?",
                  textAlign: TextAlign.center),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: const Text("Batal",
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _dbHelper.updateStatusPinjaman(id, newStatus);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Status berhasil diubah ke $newStatus"),
                                backgroundColor: actionColor),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: const Text("YA, Lanjutkan",
                          style: TextStyle(color: Colors.white)),
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

  // --- 3. PENCARIAN NASABAH (BOTTOM SHEET DRAGGABLE) ---
  Future<Map<String, dynamic>?> _showSearchAnggotaSheet() {
    List<Map<String, dynamic>> filtered = List.from(_listAnggota);

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
                          onChanged: (val) {
                            setStateSheet(() {
                              filtered = _listAnggota
                                  .where((a) => a['nama']
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
                                      child: Text(item['nama'][0].toUpperCase(),
                                          style: TextStyle(
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(item['nama'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle:
                                        Text("NIK: ${item['nik'] ?? '-'}"),
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

  // --- 4. TAMBAH AKAD (BOTTOM SHEET FIXED KEYBOARD) ---
  void _showTambahAkadSheet() {
    final formKey = GlobalKey<FormState>();
    final nominalController = TextEditingController();
    final deskripsiController = TextEditingController();
    Map<String, dynamic>? selectedNasabah;
    String? namaNasabahTampil;
    String statusDipilih = 'Pengajuan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Wajib true
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Padding(
            // Padding bawah mengikuti keyboard
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
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
                              child: Text("Buat Akad Pinjaman",
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
                                const Text("Pilih Nasabah",
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
                                        selectedNasabah = result;
                                        namaNasabahTampil = result['nama'];
                                      });
                                    }
                                  },
                                  child: IgnorePointer(
                                    child: TextFormField(
                                      key: Key(namaNasabahTampil ?? 'nasabah'),
                                      initialValue: namaNasabahTampil,
                                      decoration: InputDecoration(
                                        hintText: "Ketuk untuk cari nasabah...",
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        prefixIcon:
                                            const Icon(Icons.person_search),
                                        suffixIcon:
                                            const Icon(Icons.arrow_drop_down),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      validator: (val) =>
                                          selectedNasabah == null
                                              ? "Wajib pilih nasabah"
                                              : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text("Nominal Pinjaman",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: nominalController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    prefixText: "Rp ",
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? "Wajib diisi" : null,
                                ),
                                const SizedBox(height: 20),
                                const Text("Keperluan / Deskripsi",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: deskripsiController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: "Cth: Biaya Berobat",
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.description),
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? "Wajib diisi" : null,
                                ),
                                const SizedBox(height: 25),
                                const Text("Status Awal:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setStateSheet(() {
                                            statusDipilih = 'Pengajuan';
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: statusDipilih == 'Pengajuan'
                                                ? Colors.orange
                                                : Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color:
                                                    statusDipilih == 'Pengajuan'
                                                        ? Colors.orange
                                                        : Colors.grey[300]!),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text("Pengajuan",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: statusDipilih ==
                                                          'Pengajuan'
                                                      ? Colors.white
                                                      : Colors.black54)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setStateSheet(() {
                                            statusDipilih = 'Disetujui';
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: statusDipilih == 'Disetujui'
                                                ? Colors.green
                                                : Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color:
                                                    statusDipilih == 'Disetujui'
                                                        ? Colors.green
                                                        : Colors.grey[300]!),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text("Disetujui",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: statusDipilih ==
                                                          'Disetujui'
                                                      ? Colors.white
                                                      : Colors.black54)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Tombol Simpan (Sticky Bottom)
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
                              if (formKey.currentState!.validate() &&
                                  selectedNasabah != null) {
                                double nominal = double.parse(nominalController
                                    .text
                                    .replaceAll('.', '')
                                    .replaceAll(',', ''));
                                String tgl = DateFormat('dd/MM/yyyy')
                                    .format(DateTime.now());

                                Map<String, dynamic> newData = {
                                  'nasabah_id': selectedNasabah!['id'],
                                  'tgl_pengajuan': tgl,
                                  'nominal': nominal,
                                  'deskripsi': deskripsiController.text,
                                  'status': statusDipilih,
                                };

                                await _dbHelper.insertPinjamanLunak(newData);

                                newData['nama_nasabah'] =
                                    selectedNasabah!['nama'];
                                newData['telepon'] =
                                    selectedNasabah!['telepon'];

                                if (mounted) {
                                  Navigator.pop(context);
                                  _loadData();
                                  Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailAkadPinjamanLunakPage(
                                                      dataPinjaman: newData)))
                                      .then((_) => _loadData());
                                }
                              }
                            },
                            child: const Text("SIMPAN DATA",
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Akad Pinjaman Lunak"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- HEADER SUMMARY ---
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
                const Text("Total Dana Dipinjamkan (Disetujui)",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(
                  _currencyFormatter.format(_totalDanaDipinjamkan),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text("Disetujui",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text("$_countDisetujui Akad",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text("Diajukan",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text("$_countDiajukan Akad",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellowAccent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Riwayat Akad",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),

          // --- LIST RIWAYAT ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listPinjaman.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_edu,
                                size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            const Text("Belum ada data akad",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _listPinjaman.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _listPinjaman[index];

                          final bool isApproved =
                              item['status'] == 'Disetujui' ||
                                  item['status'] == 'Lunas';
                          final bool isRejected =
                              item['status'] == 'Tidak Disetujui';

                          Color statusColor;
                          IconData statusIcon;
                          String statusText;

                          if (isApproved) {
                            statusColor = Colors.green;
                            statusIcon = Icons.check_circle;
                            statusText = "Status: Disetujui";
                          } else if (isRejected) {
                            statusColor = Colors.red;
                            statusIcon = Icons.cancel;
                            statusText = "Status: Tidak Disetujui";
                          } else {
                            statusColor = Colors.orange;
                            statusIcon = Icons.access_time_filled;
                            statusText = "Status: Pengajuan";
                          }

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailAkadPinjamanLunakPage(
                                            dataPinjaman: item),
                                  ),
                                ).then((_) => _loadData());
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 4.0),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        statusColor.withOpacity(0.1),
                                    child: Icon(statusIcon, color: statusColor),
                                  ),
                                  title: Text(
                                      item['nama_nasabah'] ?? 'Tanpa Nama',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        _currencyFormatter
                                            .format(item['nominal']),
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(item['deskripsi'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor),
                                        ),
                                      )
                                    ],
                                  ),
                                  // Switch Konfirmasi Status
                                  trailing: isRejected
                                      ? const SizedBox(width: 10)
                                      : Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: isApproved,
                                            activeColor: Colors.green,
                                            inactiveThumbColor: Colors.orange,
                                            inactiveTrackColor:
                                                Colors.orange[100],
                                            onChanged: (val) {
                                              // Panggil Bottom Sheet Konfirmasi
                                              _showStatusConfirmationSheet(
                                                  item['id'], item['status']);
                                            },
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTambahAkadSheet, // Panggil Bottom Sheet
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Akad",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
