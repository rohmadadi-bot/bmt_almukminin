import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk InputFormatter
import 'package:intl/intl.dart';
import '../../data/db_helper.dart';

class RegistrasiPage extends StatefulWidget {
  const RegistrasiPage({super.key});

  @override
  State<RegistrasiPage> createState() => _RegistrasiPageState();
}

class _RegistrasiPageState extends State<RegistrasiPage> {
  final _formKey = GlobalKey<FormState>();
  final DbHelper _dbHelper = DbHelper();

  // Controller Input
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _namaPemilikRekeningController =
      TextEditingController();
  final TextEditingController _nomorRekeningController =
      TextEditingController();
  final TextEditingController _bankManualController = TextEditingController();

  // State untuk Switch dan Dropdown
  bool _isLoading = false;
  bool _tambahRekening = false;
  String? _bankTerpilih;

  // Daftar Bank
  final List<String> _daftarBank = [
    'BCA',
    'MANDIRI',
    'BNI',
    'BRI',
    'BSI',
    'Lainnya',
  ];

  String _capitalize(String value) {
    if (value.trim().isEmpty) return "";
    return value.split(' ').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _simpanNasabah() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    String finalNik = _nikController.text.trim();
    if (finalNik.isEmpty) {
      finalNik = "TMP-${DateTime.now().millisecondsSinceEpoch}";
    }

    String namaBank = _bankTerpilih == 'Lainnya'
        ? _capitalize(_bankManualController.text.trim())
        : (_bankTerpilih ?? '-');

    String infoRekening = "";
    if (_tambahRekening) {
      infoRekening =
          "$namaBank | ${_nomorRekeningController.text} a/n ${_capitalize(_namaPemilikRekeningController.text)}";
    }

    Map<String, dynamic> dataNasabah = {
      'nik': finalNik.toUpperCase(),
      'nama': _capitalize(_namaController.text.trim()),
      'telepon': _teleponController.text.trim(),
      'alamat': _capitalize(_alamatController.text.trim()),
      'rekening_bank': infoRekening,
      'status': 'Aktif',
      'tgl_daftar': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    };

    try {
      final result = await _dbHelper.insertAnggota(dataNasabah);

      if (result > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nasabah Berhasil Didaftarkan!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _resetForm();
        }
      }
    } catch (e) {
      String errorMsg = e.toString().contains('UNIQUE')
          ? 'Gagal: NIK/ID tersebut sudah terdaftar!'
          : 'Gagal menyimpan: $e';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nikController.clear();
    _namaController.clear();
    _teleponController.clear();
    _alamatController.clear();
    _namaPemilikRekeningController.clear();
    _nomorRekeningController.clear();
    _bankManualController.clear();
    setState(() {
      _tambahRekening = false;
      _bankTerpilih = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Latar belakang abu-abu muda
      appBar: AppBar(
        title: const Text('Registrasi Nasabah'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: DATA DIRI ---
                    _buildSectionTitle("Informasi Pribadi"),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nikController,
                              keyboardType:
                                  TextInputType.number, // Keyboard Angka
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly // Hanya Angka
                              ],
                              decoration: InputDecoration(
                                labelText: 'NIK (Nomor Induk Kependudukan)',
                                hintText: 'Kosongkan jika belum ada',
                                prefixIcon: const Icon(Icons.credit_card),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _namaController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Nama Lengkap *',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) {
                                if (_tambahRekening) {
                                  _namaPemilikRekeningController.text = value;
                                }
                              },
                              validator: (value) =>
                                  value!.isEmpty ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _teleponController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Nomor Telepon / WA',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _alamatController,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Alamat Lengkap',
                                prefixIcon: const Icon(Icons.home),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- SECTION 2: DATA BANK (OPSIONAL) ---
                    _buildSectionTitle("Informasi Rekening Bank"),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Tambah Rekening Bank?',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                                "Aktifkan jika nasabah memiliki rekening"),
                            value: _tambahRekening,
                            activeColor: const Color(0xFF2E7D32),
                            secondary: const Icon(Icons.account_balance),
                            onChanged: (bool value) {
                              setState(() {
                                _tambahRekening = value;
                                if (value) {
                                  _namaPemilikRekeningController.text =
                                      _namaController.text;
                                }
                              });
                            },
                          ),
                          if (_tambahRekening)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _namaPemilikRekeningController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: InputDecoration(
                                      labelText: 'Atas Nama Rekening',
                                      prefixIcon: const Icon(Icons.badge),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: DropdownButtonFormField<String>(
                                          value: _bankTerpilih,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            labelText: 'Bank',
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            prefixIcon: const Icon(
                                                Icons.account_balance_wallet),
                                          ),
                                          items: _daftarBank.map((String bank) {
                                            return DropdownMenuItem<String>(
                                              value: bank,
                                              child: Text(bank,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _bankTerpilih = value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 5,
                                        child: TextFormField(
                                          controller: _nomorRekeningController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          decoration: InputDecoration(
                                            labelText: 'No. Rekening',
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_bankTerpilih == 'Lainnya') ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _bankManualController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: InputDecoration(
                                        labelText: 'Nama Bank Lainnya',
                                        prefixIcon: const Icon(Icons.edit_note),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- TOMBOL SIMPAN ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _simpanNasabah,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'SIMPAN DATA NASABAH',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget Helper Judul Section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
