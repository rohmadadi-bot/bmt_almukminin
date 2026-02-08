import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // Pastikan path ini benar

class EditAnggotaPage extends StatefulWidget {
  final Map<String, dynamic> nasabah;
  const EditAnggotaPage({super.key, required this.nasabah});

  @override
  State<EditAnggotaPage> createState() => _EditAnggotaPageState();
}

class _EditAnggotaPageState extends State<EditAnggotaPage> {
  final _formKey = GlobalKey<FormState>();

  // 1. Inisialisasi API Service
  final ApiService _apiService = ApiService();

  // Controller Input
  late TextEditingController _nikController;
  late TextEditingController _namaController;
  late TextEditingController _teleponController;
  late TextEditingController _alamatController;
  late TextEditingController _namaPemilikRekeningController;
  late TextEditingController _nomorRekeningController;
  late TextEditingController _bankManualController;

  bool _isLoading = false;
  bool _tambahRekening = false;

  // Variabel untuk Dropdown Bank
  String? _bankTerpilih;
  String _selectedStatus = 'Aktif';

  final List<String> _daftarBank = [
    'BCA',
    'MANDIRI',
    'BNI',
    'BRI',
    'BSI',
    'JATENG',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _initDataNasabah();
  }

  // --- INISIALISASI DATA AWAL (PARSING DARI DATA YANG DIKIRIM) ---
  void _initDataNasabah() {
    // 1. Data Dasar
    _nikController = TextEditingController(text: widget.nasabah['nik']);
    _namaController = TextEditingController(text: widget.nasabah['nama']);
    _teleponController = TextEditingController(text: widget.nasabah['telepon']);
    _alamatController = TextEditingController(text: widget.nasabah['alamat']);

    // Set Status (Default Aktif jika null)
    _selectedStatus = widget.nasabah['status'] ?? 'Aktif';

    // 2. Logika Parsing Rekening Bank (Format: "BANK | NO_REK a/n NAMA")
    String rekInfo = widget.nasabah['rekening_bank'] ?? "";

    _bankManualController = TextEditingController(); // Init awal

    if (rekInfo.isNotEmpty && rekInfo.contains('|')) {
      _tambahRekening = true;
      try {
        List<String> parts = rekInfo.split(' | ');
        String bankName = parts[0].trim();

        // Cek bagian kedua (No Rek & Nama)
        if (parts.length > 1 && parts[1].contains(' a/n ')) {
          List<String> details = parts[1].split(' a/n ');
          String rekNo = details[0].trim();
          String owner = details.length > 1 ? details[1].trim() : "";

          // Set Controller
          _nomorRekeningController = TextEditingController(text: rekNo);
          _namaPemilikRekeningController = TextEditingController(text: owner);

          // Cek apakah bank ada di list dropdown
          if (_daftarBank.contains(bankName)) {
            _bankTerpilih = bankName;
          } else {
            _bankTerpilih = 'Lainnya';
            _bankManualController.text = bankName;
          }
        } else {
          _resetRekeningControllers();
        }
      } catch (e) {
        _resetRekeningControllers();
      }
    } else {
      _resetRekeningControllers();
    }
  }

  void _resetRekeningControllers() {
    _nomorRekeningController = TextEditingController();
    _namaPemilikRekeningController = TextEditingController();
    _bankManualController = TextEditingController();
    _bankTerpilih = null;
  }

  // Helper untuk format teks Title Case
  String _capitalize(String value) {
    if (value.trim().isEmpty) return "";
    return value.split(' ').map((word) {
      if (word.isEmpty) return "";
      return "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}";
    }).join(' ');
  }

  // --- LOGIKA UPDATE KE SERVER ---
  void _updateNasabah() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. Siapkan String Rekening
      String infoRekening = "";
      if (_tambahRekening) {
        String namaBank = _bankTerpilih == 'Lainnya'
            ? _bankManualController.text.trim().toUpperCase()
            : (_bankTerpilih ?? '-');

        infoRekening =
            "$namaBank | ${_nomorRekeningController.text} a/n ${_capitalize(_namaPemilikRekeningController.text)}";
      }

      // 2. Siapkan Data Map untuk API
      Map<String, dynamic> dataUpdate = {
        'id': widget.nasabah['id'], // ID WAJIB ADA UNTUK UPDATE
        'nik': _nikController.text.trim().toUpperCase(),
        'nama': _capitalize(_namaController.text.trim()),
        'telepon': _teleponController.text.trim(),
        'alamat': _capitalize(_alamatController.text.trim()),
        'rekening_bank': infoRekening,
        'status': _selectedStatus,
      };

      // 3. Panggil API
      final success = await _apiService.updateAnggota(dataUpdate);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Data Berhasil Diperbarui!'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Kembali & Refresh halaman sebelumnya
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Gagal mengupdate data. Cek koneksi server.'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Terjadi Kesalahan: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Anggota'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- STATUS KEANGGOTAAN ---
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                          labelText: 'Status Keanggotaan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.verified_user)),
                      items: ['Aktif', 'Non-Aktif', 'Blacklist']
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                    const SizedBox(height: 16),

                    // --- DATA PRIBADI ---
                    TextFormField(
                      controller: _nikController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                          labelText: 'NIK / ID (KTP)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          labelText: 'Nama Lengkap *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person)),
                      validator: (value) =>
                          value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _teleponController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Alamat Lengkap',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home)),
                    ),

                    const SizedBox(height: 20),
                    const Divider(thickness: 2),

                    // --- DATA REKENING ---
                    SwitchListTile(
                      title: const Text('Data Rekening Bank',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          const Text("Aktifkan jika nasabah memiliki rekening"),
                      value: _tambahRekening,
                      activeColor: const Color(0xFF2E7D32),
                      onChanged: (bool value) =>
                          setState(() => _tambahRekening = value),
                    ),

                    if (_tambahRekening) ...[
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _bankTerpilih,
                              decoration: const InputDecoration(
                                  labelText: 'Pilih Bank',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white),
                              items: _daftarBank
                                  .map((bank) => DropdownMenuItem(
                                      value: bank, child: Text(bank)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _bankTerpilih = v),
                            ),
                            if (_bankTerpilih == 'Lainnya') ...[
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _bankManualController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                    labelText: 'Ketik Nama Bank',
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: Icon(Icons.account_balance)),
                              ),
                            ],
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _nomorRekeningController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Nomor Rekening',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.credit_card)),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _namaPemilikRekeningController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                  labelText: 'Atas Nama (Pemilik Rekening)',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.person_pin)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // --- TOMBOL SIMPAN ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateNasabah,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('SIMPAN PERUBAHAN',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
