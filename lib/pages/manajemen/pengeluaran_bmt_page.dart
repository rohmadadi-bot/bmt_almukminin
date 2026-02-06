import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/db_helper.dart';

// Karena semua file ini SATU FOLDER, import cukup nama filenya saja
import 'pengeluaran_rutin_bmt_page.dart';
import 'pengeluaran_tidak_rutin_bmt_page.dart';

class PengeluaranBmtPage extends StatefulWidget {
  const PengeluaranBmtPage({super.key});

  @override
  State<PengeluaranBmtPage> createState() => _PengeluaranBmtPageState();
}

class _PengeluaranBmtPageState extends State<PengeluaranBmtPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  int _totalRutin = 0;
  int _totalTidakRutin = 0;
  int _totalSemua = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRekap();
  }

  Future<void> _loadRekap() async {
    final rekap = await _dbHelper.getRekapPengeluaranBulanIni();
    if (mounted) {
      setState(() {
        _totalRutin = rekap['rutin'] ?? 0;
        _totalTidakRutin = rekap['tidak_rutin'] ?? 0;
        _totalSemua = rekap['total'] ?? 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String bulanIni = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pengeluaran BMT"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // HEADER INFORMASI
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
                Text("Total Pengeluaran Bulan Ini\n($bulanIni)",
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _formatter.format(_totalSemua),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildMiniInfo("Rutin", _totalRutin, Colors.blue[100]!,
                        Colors.blue[900]!),
                    const SizedBox(width: 15),
                    _buildMiniInfo("Tidak Rutin", _totalTidakRutin,
                        Colors.orange[100]!, Colors.orange[900]!),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 30),

          // MENU TOMBOL
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildMenuButton(
                    title: "Pengeluaran Rutin",
                    desc: "Gaji, Listrik, Air, Wifi, dll.",
                    icon: Icons.repeat,
                    color: Colors.blue,
                    onTap: () async {
                      // Navigate to Page 1 (Tanpa const)
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PengeluaranRutinBmtPage()));
                      _loadRekap();
                    }),
                const SizedBox(height: 15),
                _buildMenuButton(
                    title: "Pengeluaran Tidak Rutin",
                    desc: "Perbaikan, Pembelian Aset, ATK, dll.",
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                    onTap: () async {
                      // Navigate to Page 2 (Tanpa const)
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PengeluaranTidakRutinBmtPage()));
                      _loadRekap();
                    }),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniInfo(
      String label, int nominal, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: 12, color: textColor.withOpacity(0.8))),
            const SizedBox(height: 5),
            Text(_formatter.format(nominal),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      {required String title,
      required String desc,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(desc,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400])
            ],
          ),
        ),
      ),
    );
  }
}
