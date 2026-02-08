import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; (ditiadakan)
// UBAH: Gunakan ApiService
import '../../../services/api_service.dart';

class AkadBagiHasilPage extends StatefulWidget {
  final Map<String, dynamic> akadData;

  const AkadBagiHasilPage({super.key, required this.akadData});

  @override
  State<AkadBagiHasilPage> createState() => _AkadBagiHasilPageState();
}

class _AkadBagiHasilPageState extends State<AkadBagiHasilPage> {
  // UBAH: Inisialisasi ApiService
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Status Mode Edit
  bool _isEditing = false;
  late String _currentStatus;

  // Controllers
  late TextEditingController _namaUsahaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _modalController;

  // Variabel Dropdown Nisbah
  String? _selectedNisbah;

  // Daftar Pilihan Nisbah
  final List<String> _opsiNisbah = [
    '70 : 30',
    '60 : 40',
    '50 : 50',
    '40 : 60',
    '30 : 70',
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.akadData['status'] ?? 'Pengajuan';
    _resetForm(); // Load data awal
  }

  // --- RESET FORM (LOAD DATA) ---
  void _resetForm() {
    _namaUsahaController =
        TextEditingController(text: widget.akadData['nama_usaha']);
    _deskripsiController =
        TextEditingController(text: widget.akadData['deskripsi_usaha']);

    // Parsing Angka
    double modal =
        double.tryParse(widget.akadData['nominal_modal'].toString()) ?? 0;
    _modalController =
        TextEditingController(text: modal > 0 ? modal.toStringAsFixed(0) : '');

    double nNasabah =
        double.tryParse(widget.akadData['nisbah_nasabah'].toString()) ?? 60;
    double nBmt =
        double.tryParse(widget.akadData['nisbah_bmt'].toString()) ?? 40;

    String dbNisbah = "${nNasabah.toInt()} : ${nBmt.toInt()}";

    if (_opsiNisbah.contains(dbNisbah)) {
      _selectedNisbah = dbNisbah;
    } else {
      _selectedNisbah = '60 : 40';
    }

    if (mounted) setState(() {});
  }

// --- SIMPAN PERUBAHAN DATA (ONLINE) ---
  Future<void> _simpanPerubahan() async {
    if (_formKey.currentState!.validate()) {
      // 1. Parsing Data (Variabel ini sekarang AKAN DIGUNAKAN)
      List<String> parts = _selectedNisbah!.split(' : ');
      double nN = double.parse(parts[0]);
      double nB = double.parse(parts[1]);

      // Bersihkan format uang (hapus titik/koma)
      double modal = double.tryParse(
              _modalController.text.replaceAll('.', '').replaceAll(',', '')) ??
          0;

      int id = int.tryParse(widget.akadData['id'].toString()) ?? 0;

      // 2. Tampilkan Loading (Optional tapi bagus UX-nya)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menyimpan perubahan...")),
      );

      // 3. Panggil API Update
      bool success = await _apiService.updateDataAkadBagiHasil({
        'id': id,
        'nama_usaha': _namaUsahaController.text,
        'deskripsi_usaha': _deskripsiController.text,
        'nominal_modal': modal,
        'nisbah_nasabah': nN,
        'nisbah_bmt': nB,
      });

      // 4. Cek Hasil
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Perubahan data berhasil disimpan ke Server!"),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal menyimpan perubahan. Cek koneksi."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // --- UPDATE STATUS (ONLINE) ---
  Future<void> _updateStatusOnly(String newStatus) async {
    int id = int.tryParse(widget.akadData['id'].toString()) ?? 0;

    // Panggil API
    bool success = await _apiService.updateStatusAkadBagiHasil(id, newStatus);

    if (mounted) {
      if (success) {
        setState(() {
          _currentStatus = newStatus;
        });

        Color snackColor = Colors.orange;
        if (newStatus == 'Disetujui') snackColor = Colors.green;
        if (newStatus == 'Ditolak') snackColor = Colors.red;
        if (newStatus == 'Selesai') snackColor = Colors.blueGrey;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status berhasil diubah menjadi: $newStatus"),
            backgroundColor: snackColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Gagal update status"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Detail Akad"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _resetForm();
                });
              },
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text("BATAL", style: TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER STATUS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _isEditing ? Colors.orange[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _isEditing ? Colors.orange : Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(_isEditing ? Icons.edit_note : Icons.verified_user,
                        color: _isEditing ? Colors.orange : Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? "Mode Edit Aktif"
                            : "Status Saat Ini: ${_currentStatus.toUpperCase()}",
                        style: TextStyle(
                            color: _isEditing
                                ? Colors.orange[800]
                                : Colors.green[800],
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              _buildSectionTitle("Informasi Usaha"),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _namaUsahaController,
                        label: "Nama Usaha",
                        icon: Icons.store,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _deskripsiController,
                        label: "Deskripsi Usaha",
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionTitle("Kesepakatan Dana & Bagi Hasil"),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Nominal Pendanaan (Modal BMT)",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _modalController,
                        label: "",
                        icon: Icons.monetization_on,
                        isCurrency: true,
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text("Skema Bagi Hasil (Nisbah)",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                            color: _isEditing ? Colors.white : Colors.grey[100],
                            border: Border.all(
                                color: _isEditing
                                    ? Colors.grey
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: _selectedNisbah,
                            onChanged: _isEditing
                                ? (newValue) {
                                    setState(() {
                                      _selectedNisbah = newValue;
                                    });
                                  }
                                : null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.pie_chart_outline,
                                  color: Colors.orange),
                            ),
                            items: _opsiNisbah.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  "$value %",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _isEditing
                                        ? Colors.black
                                        : Colors.grey[700],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (_selectedNisbah != null)
                        Container(
                          margin: const EdgeInsets.only(top: 15),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNisbahInfo(
                                  "Nasabah",
                                  _selectedNisbah!.split(' : ')[0],
                                  Colors.blue),
                              const Text("VS",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                              _buildNisbahInfo(
                                  "BMT",
                                  _selectedNisbah!.split(' : ')[1],
                                  Colors.green),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- TOMBOL UPDATE STATUS (GRID) ---
              _buildSectionTitle("Update Status Akad"),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatusBtn(
                                "Pengajuan", Colors.orange, Icons.access_time)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildStatusBtn("Disetujui",
                                const Color(0xFF2E7D32), Icons.check_circle)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatusBtn(
                                "Ditolak", Colors.red, Icons.cancel)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildStatusBtn(
                                "Selesai", Colors.blueGrey, Icons.flag)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // TOMBOL AKSI UTAMA (SIMPAN/EDIT)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            if (_isEditing) {
              _simpanPerubahan();
            } else {
              setState(() {
                _isEditing = true;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isEditing ? const Color(0xFF2E7D32) : Colors.orange[800],
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(
            _isEditing ? Icons.save : Icons.edit,
            color: Colors.white,
          ),
          label: Text(
            _isEditing ? "SIMPAN PERUBAHAN DATA" : "UBAH DATA AKAD",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildStatusBtn(String status, Color color, IconData icon) {
    bool isActive = _currentStatus == status;
    return InkWell(
      onTap: () => _updateStatusOnly(status),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isActive ? color : color.withOpacity(0.3), width: 1.5)),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : color, size: 20),
            const SizedBox(height: 4),
            Text(status,
                style: TextStyle(
                    color: isActive ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12))
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool isCurrency = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      maxLines: maxLines,
      keyboardType: isCurrency ? TextInputType.number : TextInputType.text,
      style: TextStyle(
        fontWeight: isCurrency ? FontWeight.bold : FontWeight.normal,
        color: Colors.black87,
        fontSize: isCurrency ? 18 : 14,
      ),
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : null,
        prefixIcon: Icon(icon, color: _isEditing ? Colors.green : Colors.grey),
        prefixText: isCurrency ? "Rp " : null,
        hintText: isCurrency ? "0" : null,
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: _isEditing ? Colors.green : Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: _isEditing ? Colors.grey[400]! : Colors.transparent),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
      ),
      validator: (val) =>
          _isEditing && (val == null || val.isEmpty) ? "Wajib diisi" : null,
    );
  }

  Widget _buildNisbahInfo(String label, String percent, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            "$percent%",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
