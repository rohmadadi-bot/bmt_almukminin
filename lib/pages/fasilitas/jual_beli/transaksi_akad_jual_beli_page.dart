import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/db_helper.dart';
import 'detail_akad_jual_beli_page.dart';

// --- BAGIAN 1: DASHBOARD ---
class TransaksiAkadJualBeliPage extends StatefulWidget {
  const TransaksiAkadJualBeliPage({super.key});

  @override
  State<TransaksiAkadJualBeliPage> createState() =>
      _TransaksiAkadJualBeliPageState();
}

class _TransaksiAkadJualBeliPageState extends State<TransaksiAkadJualBeliPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _riwayatAkad = [];
  double _totalPiutang = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await _dbHelper.database;
    final data = await db.rawQuery('''
      SELECT m.*, a.nama as nama_nasabah, a.telepon 
      FROM murabahah_akad m
      JOIN anggota a ON m.nasabah_id = a.id
      ORDER BY m.id DESC
    ''');

    double total = 0;
    for (var item in data) {
      if (item['status'] == 'Disetujui') {
        total += (item['total_piutang'] as num).toDouble();
      }
    }

    if (mounted) {
      setState(() {
        _riwayatAkad = data;
        _totalPiutang = total;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(int id, String currentStatus) async {
    String newStatus = currentStatus == 'Pengajuan' ? 'Disetujui' : 'Pengajuan';
    final db = await _dbHelper.database;
    await db.rawUpdate(
        'UPDATE murabahah_akad SET status = ? WHERE id = ?', [newStatus, id]);
    _loadData();
  }

  // --- LOGIKA WA (UPDATE: Tambah Status) ---
  String _formatPhone(String rawPhone) {
    String digitsOnly = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.startsWith('0')) return '62${digitsOnly.substring(1)}';
    if (digitsOnly.startsWith('8')) return '62$digitsOnly';
    return digitsOnly;
  }

  void _kirimWAAkadBaru(Map<String, dynamic> akad) async {
    String phone = _formatPhone(akad['telepon'] ?? '');
    if (phone.length < 10) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Nomor WA tidak valid")));
      return;
    }

    // UPDATE: Menambahkan Status ke pesan WA
    String pesan = "📄 *AKAD MURABAHAH BARU*\n"
        "🏛 *BMT AL MUKMININ*\n"
        "--------------------------------\n"
        "Assalamu'alaikum, ${akad['nama_nasabah']}\n\n"
        "Berikut detail akad pembiayaan Anda:\n"
        "📦 Barang : *${akad['nama_barang']}*\n"
        "📊 Status : *${akad['status']}*\n" // <--- Status Ditambahkan
        "💰 Total Piutang : ${_formatter.format(akad['total_piutang'])}\n"
        "🗓 Tenor : ${akad['jangka_waktu']} Bulan\n"
        "💵 Angsuran : ${_formatter.format(akad['angsuran_bulanan'])} /bulan\n"
        "--------------------------------\n"
        "Mohon disimpan sebagai bukti akad.\n"
        "_Terima kasih. Jazakumullah khairan._";

    final String url =
        "https://wa.me/$phone?text=${Uri.encodeComponent(pesan)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // --- STEP 1: INPUT AKAD (SHEET) ---
  void _showTambahAkadSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FormInputAkadSheet(),
    );

    if (result != null) {
      if (!mounted) return;
      _loadData(); // Refresh Dashboard

      // STEP 2: TAMPILKAN HASIL SIMPAN (SHEET)
      _showSuccessAkadSheet(result);
    }
  }

  // --- STEP 2: SUKSES SIMPAN (SHEET UPDATE) ---
  void _showSuccessAkadSheet(Map<String, dynamic> akad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Tentukan warna status
        Color statusColor =
            akad['status'] == 'Disetujui' ? Colors.green : Colors.orange;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 15),
              const Text("Akad Berhasil Disimpan",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32))),
              const Divider(height: 30),

              // Detail
              _buildDetailRow("Nasabah", akad['nama_nasabah']),
              _buildDetailRow("Barang", akad['nama_barang']),

              // UPDATE: Menampilkan Status dengan Highlight Warna
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Status", style: TextStyle(color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(akad['status'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),

              _buildDetailRow(
                  "Total Piutang", _formatter.format(akad['total_piutang'])),
              _buildDetailRow("Tenor", "${akad['jangka_waktu']} Bulan"),

              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Angsuran/bln:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_formatter.format(akad['angsuran_bulanan']),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                            fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Tombol
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Tutup Sheet Sukses
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DetailAkadJualBeliPage(dataAkad: akad)));
                      },
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
                      onPressed: () => _kirimWAAkadBaru(akad),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text("KIRIM WA",
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Data Akad Murabahah'),
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
                  bottomRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Text("Total Piutang Disetujui",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(
                  _formatter.format(_totalPiutang),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Riwayat Akad",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(height: 10),

          // LIST RIWAYAT
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _riwayatAkad.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _riwayatAkad[index];
                      String status = item['status'] ?? 'Pengajuan';
                      bool isApproved = status == 'Disetujui';
                      bool isRejected = status == 'Tidak Disetujui';

                      Color statusColor = isApproved
                          ? Colors.green
                          : (isRejected ? Colors.red : Colors.orange);

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            DetailAkadJualBeliPage(
                                                dataAkad: item)))
                                .then((_) => _loadData());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          statusColor.withOpacity(0.1),
                                      child: Icon(
                                          isApproved
                                              ? Icons.check
                                              : (isRejected
                                                  ? Icons.close
                                                  : Icons.access_time),
                                          color: statusColor),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item['nama_nasabah'] ?? '-',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(item['nama_barang'],
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    isRejected
                                        ? const Text("DITOLAK",
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12))
                                        : Switch(
                                            value: isApproved,
                                            activeColor: Colors.green,
                                            onChanged: (val) {
                                              _toggleStatus(
                                                  item['id'], item['status']);
                                            },
                                          )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(status,
                                          style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                      Text(
                                          _formatter
                                              .format(item['total_piutang']),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTambahAkadSheet,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Akad Baru", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// --- BAGIAN 2: FORM INPUT SHEET (BOTTOM SHEET) ---
class FormInputAkadSheet extends StatefulWidget {
  const FormInputAkadSheet({super.key});

  @override
  State<FormInputAkadSheet> createState() => _FormInputAkadSheetState();
}

class _FormInputAkadSheetState extends State<FormInputAkadSheet> {
  final _dbHelper = DbHelper();
  final _formKey = GlobalKey<FormState>();

  final _barangController = TextEditingController();
  final _hargaController = TextEditingController();
  final _marginController = TextEditingController();
  final _tenorController = TextEditingController();
  final _nasabahController = TextEditingController();

  Map<String, dynamic>? _selectedNasabah;
  double _cicilanPerBulan = 0;
  String _statusDipilih = 'Pengajuan';

  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // --- CARI NASABAH (SHEET) ---
  void _showCariNasabahSheet() async {
    List<Map<String, dynamic>> allNasabah = await _dbHelper.getAllAnggota();
    List<Map<String, dynamic>> filteredNasabah = List.from(allNasabah);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSearch) {
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
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          autofocus: false,
                          decoration: InputDecoration(
                            hintText: 'Cari nama nasabah...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            setStateSearch(() {
                              filteredNasabah = allNasabah
                                  .where((n) => n['nama']
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filteredNasabah.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) => ListTile(
                            title: Text(filteredNasabah[i]['nama'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle:
                                Text("ID: ${filteredNasabah[i]['nik'] ?? '-'}"),
                            onTap: () {
                              setState(() {
                                _selectedNasabah = filteredNasabah[i];
                                _nasabahController.text =
                                    filteredNasabah[i]['nama'];
                              });
                              Navigator.pop(context); // Tutup Sheet Cari
                            },
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
      },
    );
  }

  void _hitungCicilan() {
    double harga =
        double.tryParse(_hargaController.text.replaceAll('.', '')) ?? 0;
    double margin =
        double.tryParse(_marginController.text.replaceAll('.', '')) ?? 0;
    int tenor = int.tryParse(_tenorController.text) ?? 0;
    if (tenor > 0) {
      setState(() => _cicilanPerBulan = (harga + margin) / tenor);
    }
  }

  void _simpanAkad() async {
    if (_formKey.currentState!.validate() && _selectedNasabah != null) {
      double harga = double.parse(_hargaController.text.replaceAll('.', ''));
      double margin = double.parse(_marginController.text.replaceAll('.', ''));

      Map<String, dynamic> row = {
        'nasabah_id': _selectedNasabah!['id'],
        'nama_barang': _barangController.text,
        'harga_beli': harga,
        'margin': margin,
        'total_piutang': harga + margin,
        'jangka_waktu': int.parse(_tenorController.text),
        'angsuran_bulanan': _cicilanPerBulan,
        'tgl_akad': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'status': _statusDipilih
      };

      await _dbHelper.insertMurabahahAkad(row);

      row['nama_nasabah'] = _selectedNasabah!['nama'];
      row['telepon'] = _selectedNasabah!['telepon'];

      if (mounted) {
        Navigator.pop(context, row); // Return data ke Dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
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
                const Text("Input Akad Baru",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nasabahController,
                  readOnly: true,
                  onTap: _showCariNasabahSheet,
                  decoration: const InputDecoration(
                      labelText: 'Pilih Nasabah',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.arrow_drop_down)),
                  validator: (v) => v!.isEmpty ? 'Wajib' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _barangController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Nama Barang',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _hargaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Harga Beli (Rp)',
                        border: OutlineInputBorder()),
                    onChanged: (v) {
                      if (v.isNotEmpty) {
                        double h = double.tryParse(v.replaceAll('.', '')) ?? 0;
                        _marginController.text =
                            (h * 0.05).toStringAsFixed(0); // Auto Margin 5%
                        _hitungCicilan();
                      }
                    }),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _marginController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Margin / Keuntungan (Rp)',
                        border: OutlineInputBorder()),
                    onChanged: (_) => _hitungCicilan()),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _tenorController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Tenor (Bulan)',
                        border: OutlineInputBorder()),
                    onChanged: (_) => _hitungCicilan()),
                const SizedBox(height: 20),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Status Awal:",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setState(() => _statusDipilih = 'Pengajuan'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _statusDipilih == 'Pengajuan'
                                ? Colors.orange
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text("Pengajuan",
                              style: TextStyle(
                                  color: _statusDipilih == 'Pengajuan'
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setState(() => _statusDipilih = 'Disetujui'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _statusDipilih == 'Disetujui'
                                ? Colors.green
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text("Disetujui",
                              style: TextStyle(
                                  color: _statusDipilih == 'Disetujui'
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Estimasi Cicilan:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_formatter.format(_cicilanPerBulan),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: _simpanAkad,
                    child: const Text("SIMPAN & LANJUT",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
