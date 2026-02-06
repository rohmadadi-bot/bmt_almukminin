import 'dart:convert'; // Untuk encode/decode JSON
import 'package:flutter/material.dart';
import '../../../data/db_helper.dart';

class PjPelaksanaPage extends StatefulWidget {
  final Map<String, dynamic> usaha;

  const PjPelaksanaPage({super.key, required this.usaha});

  @override
  State<PjPelaksanaPage> createState() => _PjPelaksanaPageState();
}

class _PjPelaksanaPageState extends State<PjPelaksanaPage> {
  final DbHelper _dbHelper = DbHelper();
  final _pjController = TextEditingController();

  List<Map<String, TextEditingController>> _pelaksanaControllers = [];
  bool _isEditing = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDataAwal();
  }

  void _loadDataAwal() {
    // 1. Muat Nama PJ
    if (widget.usaha['pj_nama'] != null) {
      _pjController.text = widget.usaha['pj_nama'].toString();
    }

    // 2. Muat List Pelaksana
    bool adaDataPelaksana = false;
    if (widget.usaha['data_pelaksana'] != null &&
        widget.usaha['data_pelaksana'].toString().isNotEmpty) {
      try {
        List<dynamic> jsonList = jsonDecode(widget.usaha['data_pelaksana']);
        for (var item in jsonList) {
          _addPelaksana(nama: item['nama'], ket: item['ket']);
        }
        if (jsonList.isNotEmpty) adaDataPelaksana = true;
      } catch (e) {
        debugPrint("Error parsing JSON: $e");
      }
    }

    // Jika data kosong, tambah 1 baris default
    if (_pelaksanaControllers.isEmpty) {
      _addPelaksana();
    } else {
      // Jika data sudah ada (PJ atau Pelaksana), masuk Mode Baca
      if (adaDataPelaksana || _pjController.text.isNotEmpty) {
        setState(() => _isEditing = false);
      }
    }
  }

  void _addPelaksana({String nama = '', String ket = ''}) {
    setState(() {
      _pelaksanaControllers.add({
        'nama': TextEditingController(text: nama),
        'ket': TextEditingController(text: ket),
      });
    });
  }

  void _removePelaksana(int index) {
    setState(() {
      _pelaksanaControllers[index]['nama']?.dispose();
      _pelaksanaControllers[index]['ket']?.dispose();
      _pelaksanaControllers.removeAt(index);
    });
  }

  // --- FUNGSI SIMPAN (DIPERBAIKI DENGAN TRY-CATCH) ---
  void _simpanData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Ambil data PJ
      String pjNama = _pjController.text.trim();

      // 2. Konversi List Controller ke JSON
      List<Map<String, String>> dataPelaksana = [];
      for (var item in _pelaksanaControllers) {
        String nama = item['nama']!.text.trim();
        String ket = item['ket']!.text.trim();
        if (nama.isNotEmpty) {
          dataPelaksana.add({'nama': nama, 'ket': ket});
        }
      }
      String jsonString = jsonEncode(dataPelaksana);

      // 3. Update Database (Pastikan fungsi ini ada di DbHelper!)
      await _dbHelper.updatePjPelaksana(widget.usaha['id'], pjNama, jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data Pengurus Berhasil Disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false; // Kembali ke Mode Baca
        });
      }
    } catch (e) {
      // Tangkap Error jika update gagal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Pastikan Loading berhenti apapun yang terjadi
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pjController.dispose();
    for (var item in _pelaksanaControllers) {
      item['nama']?.dispose();
      item['ket']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('PJ & Pelaksana'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Data',
            )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Tampilkan loading spinner
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Penanggung Jawab (PJ)",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2E7D32))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pjController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap PJ',
                      hintText: 'Masukkan nama ketua/PJ usaha',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person_pin),
                      fillColor: _isEditing ? Colors.white : Colors.grey[200],
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tim Pelaksana",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2E7D32))),
                      if (_isEditing)
                        TextButton.icon(
                          onPressed: _addPelaksana,
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF2E7D32)),
                          label: const Text("Tambah",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pelaksanaControllers.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        color: _isEditing ? Colors.white : Colors.grey[100],
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 15, right: 10),
                                child: Text("${index + 1}.",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _pelaksanaControllers[index]
                                          ['nama'],
                                      enabled: _isEditing,
                                      decoration: const InputDecoration(
                                        labelText: 'Nama Pelaksana',
                                        isDense: true,
                                        border: UnderlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _pelaksanaControllers[index]
                                          ['ket'],
                                      enabled: _isEditing,
                                      decoration: const InputDecoration(
                                          labelText: 'Jabatan / Tugas',
                                          isDense: true,
                                          border: InputBorder.none,
                                          hintText:
                                              'Cth: Sekretaris, Bag. Lapangan',
                                          hintStyle: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isEditing)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _removePelaksana(index),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditing
                            ? const Color(0xFF2E7D32)
                            : Colors.orange[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_isEditing) {
                          _simpanData();
                        } else {
                          setState(() {
                            _isEditing = true;
                          });
                        }
                      },
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                      label: Text(
                        _isEditing ? 'SIMPAN DATA' : 'EDIT DATA',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
