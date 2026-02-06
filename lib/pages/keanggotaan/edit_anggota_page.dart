import 'package:flutter/material.dart';
import '../../data/db_helper.dart';

class EditAnggotaPage extends StatefulWidget {
  final Map<String, dynamic> nasabah;
  const EditAnggotaPage({super.key, required this.nasabah});

  @override
  State<EditAnggotaPage> createState() => _EditAnggotaPageState();
}

class _EditAnggotaPageState extends State<EditAnggotaPage> {
  final _formKey = GlobalKey<FormState>();
  final DbHelper _dbHelper = DbHelper();

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
  String? _bankTerpilih;
  String _selectedStatus = 'Aktif';

  final List<String> _daftarBank = [
    'BCA',
    'MANDIRI',
    'BNI',
    'BRI',
    'BSI',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _initDataNasabah();
  }

  void _initDataNasabah() {
    // 1. Data Dasar
    _nikController = TextEditingController(text: widget.nasabah['nik']);
    _namaController = TextEditingController(text: widget.nasabah['nama']);
    _teleponController = TextEditingController(text: widget.nasabah['telepon']);
    _alamatController = TextEditingController(text: widget.nasabah['alamat']);
    _selectedStatus = widget.nasabah['status'] ?? 'Aktif';

    // 2. Logika Parsing Rekening Bank
    String rekInfo = widget.nasabah['rekening_bank'] ?? "";
    if (rekInfo.isNotEmpty && rekInfo.contains('|')) {
      _tambahRekening = true;
      try {
        // Format tersimpan: "BANK | NO_REK a/n NAMA"
        List<String> parts = rekInfo.split(' | ');
        String bankName = parts[0].trim();
        List<String> details = parts[1].split(' a/n ');

        String rekNo = details[0].trim();
        String owner = details[1].trim();

        if (_daftarBank.contains(bankName)) {
          _bankTerpilih = bankName;
          _bankManualController = TextEditingController();
        } else {
          _bankTerpilih = 'Lainnya';
          _bankManualController = TextEditingController(text: bankName);
        }
        _nomorRekeningController = TextEditingController(text: rekNo);
        _namaPemilikRekeningController = TextEditingController(text: owner);
      } catch (e) {
        _resetRekeningControllers(); // Jika format lama tidak cocok
      }
    } else {
      _resetRekeningControllers();
    }
  }

  void _resetRekeningControllers() {
    _nomorRekeningController = TextEditingController();
    _namaPemilikRekeningController = TextEditingController();
    _bankManualController = TextEditingController();
  }

  String _capitalize(String value) {
    if (value.trim().isEmpty) return "";
    return value.split(' ').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _updateNasabah() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    String namaBank = _bankTerpilih == 'Lainnya'
        ? _capitalize(_bankManualController.text.trim())
        : (_bankTerpilih ?? '-');

    String infoRekening = "";
    if (_tambahRekening) {
      infoRekening =
          "$namaBank | ${_nomorRekeningController.text} a/n ${_capitalize(_namaPemilikRekeningController.text)}";
    }

    Map<String, dynamic> dataUpdate = {
      'id': widget.nasabah['id'], // ID Database tetap
      'nik': _nikController.text.trim().toUpperCase(),
      'nama': _capitalize(_namaController.text.trim()),
      'telepon': _teleponController.text.trim(),
      'alamat': _capitalize(_alamatController.text.trim()),
      'rekening_bank': infoRekening,
      'status': _selectedStatus,
      'updated_at': DateTime.now().toString(),
    };

    try {
      await _dbHelper.updateAnggota(dataUpdate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data Berhasil Diperbarui!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali dengan sinyal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
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
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                          labelText: 'Status Keanggotaan',
                          border: OutlineInputBorder()),
                      items: ['Aktif', 'Suspend', 'Blok']
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nikController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                          labelText: 'NIK / ID',
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
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Gunakan Nomor Rekening Bank'),
                      value: _tambahRekening,
                      activeColor: const Color(0xFF2E7D32),
                      onChanged: (bool value) =>
                          setState(() => _tambahRekening = value),
                    ),
                    if (_tambahRekening) ...[
                      const Divider(),
                      TextFormField(
                        controller: _namaPemilikRekeningController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: 'Nama Atas Nama Rekening',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_pin)),
                      ),
                      const SizedBox(height: 16),
                      if (_bankTerpilih == 'Lainnya') ...[
                        TextFormField(
                          controller: _bankManualController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Masukkan Nama Bank Manual',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.edit_note)),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _bankTerpilih,
                              decoration: const InputDecoration(
                                  labelText: 'Bank',
                                  border: OutlineInputBorder()),
                              items: _daftarBank
                                  .map((bank) => DropdownMenuItem(
                                      value: bank, child: Text(bank)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _bankTerpilih = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nomorRekeningController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'No. Rekening',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateNasabah,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white),
                        child: const Text('UPDATE DATA NASABAH'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
