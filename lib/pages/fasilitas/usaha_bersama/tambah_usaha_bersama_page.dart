import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/db_helper.dart';

class TambahUsahaBersamaPage extends StatefulWidget {
  const TambahUsahaBersamaPage({super.key});

  @override
  State<TambahUsahaBersamaPage> createState() => _TambahUsahaBersamaPageState();
}

class _TambahUsahaBersamaPageState extends State<TambahUsahaBersamaPage> {
  final _formKey = GlobalKey<FormState>();
  final DbHelper _dbHelper = DbHelper();

  // Controllers
  final TextEditingController _namaUsahaController = TextEditingController();
  final TextEditingController _jenisUsahaController = TextEditingController();
  final TextEditingController _modalController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _namaUsahaController.dispose();
    _jenisUsahaController.dispose();
    _modalController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _simpanUsaha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Parsing Data Angka (Bersihkan format ribuan jika ada)
      String cleanModal =
          _modalController.text.replaceAll('.', '').replaceAll(',', '');
      double modalAwal = double.tryParse(cleanModal) ?? 0;

      // 2. Siapkan Data
      Map<String, dynamic> row = {
        'nama_usaha': _namaUsahaController.text.trim(),
        'jenis_usaha': _jenisUsahaController.text.trim(),
        'modal_awal': modalAwal,
        'deskripsi': _deskripsiController.text.trim(),
        'tgl_mulai': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'status': 'Aktif',
      };

      // 3. Simpan ke Database
      await _dbHelper.insertUsahaBersama(row);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil Usaha Berhasil Dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Kembali & Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan: $e'),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Buat Profil Usaha Baru'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informasi Usaha",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32)),
                  ),
                  const Divider(),
                  const SizedBox(height: 15),

                  // 1. Nama Usaha
                  TextFormField(
                    controller: _namaUsahaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nama Usaha',
                      hintText: 'Contoh: Ternak Lele Barokah',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.store_mall_directory,
                          color: Color(0xFF2E7D32)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Nama usaha wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Jenis Usaha
                  TextFormField(
                    controller: _jenisUsahaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Kategori / Jenis',
                      hintText: 'Contoh: Perikanan, Pertanian',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon:
                          const Icon(Icons.category, color: Color(0xFF2E7D32)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Jenis usaha wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Modal Awal
                  TextFormField(
                    controller: _modalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Modal Awal (Rencana)',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.monetization_on,
                          color: Color(0xFF2E7D32)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Nominal modal wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Deskripsi Usaha
                  TextFormField(
                    controller: _deskripsiController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Singkat Usaha',
                      hintText:
                          'Jelaskan detail rencana usaha, lokasi, dan target pasar...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child:
                            Icon(Icons.description, color: Color(0xFF2E7D32)),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Deskripsi wajib diisi'
                        : null,
                  ),

                  const SizedBox(height: 30),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                      ),
                      onPressed: _isLoading ? null : _simpanUsaha,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading ? 'MENYIMPAN...' : 'SIMPAN PROFIL USAHA',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
