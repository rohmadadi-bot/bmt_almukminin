import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// UBAH: Gunakan ApiService
import '../../../services/api_service.dart';

class DetailAkadJualBeliPage extends StatefulWidget {
  final Map<String, dynamic> dataAkad;

  const DetailAkadJualBeliPage({super.key, required this.dataAkad});

  @override
  State<DetailAkadJualBeliPage> createState() => _DetailAkadJualBeliPageState();
}

class _DetailAkadJualBeliPageState extends State<DetailAkadJualBeliPage> {
  // UBAH: Inisialisasi ApiService
  final ApiService _apiService = ApiService();

  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.dataAkad['status'] ?? 'Pengajuan';
  }

  // --- LOGIKA HAPUS DATA (ONLINE) ---
  Future<void> _hapusAkad() async {
    // 1. Tampilkan Dialog Konfirmasi
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Akad"),
            content: const Text(
                "Yakin ingin menghapus data akad ini dari SERVER? Data yang dihapus tidak dapat dikembalikan."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text("Hapus", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ) ??
        false;

    // 2. Eksekusi Hapus via API
    if (confirm) {
      // Parsing ID aman
      int id = int.tryParse(widget.dataAkad['id'].toString()) ?? 0;

      bool success = await _apiService.deleteAkadJualBeli(id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Data akad berhasil dihapus dari Server")),
          );
          Navigator.pop(context); // Kembali ke halaman list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Gagal menghapus data"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // --- LOGIKA UPDATE STATUS (ONLINE) ---
  Future<void> _updateStatus(String newStatus) async {
    int id = int.tryParse(widget.dataAkad['id'].toString()) ?? 0;

    // Panggil API Update Status
    bool success = await _apiService.updateStatusAkad(id, newStatus);

    if (mounted) {
      if (success) {
        setState(() {
          _currentStatus = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status berubah menjadi: $newStatus"),
            backgroundColor: _getStatusColor(),
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

  // --- LOGIKA WA ---
  Future<void> _launchWA({String? phone, required String message}) async {
    String urlString;

    if (phone == null || phone.isEmpty) {
      urlString = "https://wa.me/?text=${Uri.encodeComponent(message)}";
    } else {
      String formatted = phone;
      if (formatted.startsWith('0')) {
        formatted = "62${formatted.substring(1)}";
      }
      urlString =
          "https://wa.me/$formatted?text=${Uri.encodeComponent(message)}";
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("Gagal membuka WhatsApp. Pastikan aplikasi terinstall.")));
      }
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'Disetujui':
        return Colors.green;
      case 'Tidak Disetujui':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case 'Disetujui':
        return Icons.check_circle;
      case 'Tidak Disetujui':
        return Icons.cancel;
      default:
        return Icons.access_time_filled;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parsing Data untuk Tampilan Aman
    double hargaBeli =
        double.tryParse(widget.dataAkad['harga_beli'].toString()) ?? 0;
    double margin = double.tryParse(widget.dataAkad['margin'].toString()) ?? 0;
    double totalPiutang =
        double.tryParse(widget.dataAkad['total_piutang'].toString()) ?? 0;
    double angsuran =
        double.tryParse(widget.dataAkad['angsuran_bulanan'].toString()) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Akad Jual Beli"),
        backgroundColor: _getStatusColor(),
        foregroundColor: Colors.white,
        actions: [
          // --- TOMBOL HAPUS DI APP BAR ---
          IconButton(
            onPressed: _hapusAkad,
            icon: const Icon(Icons.delete),
            tooltip: "Hapus Data Akad",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. KARTU STATUS
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(_getStatusIcon(), size: 60, color: _getStatusColor()),
                    const SizedBox(height: 10),
                    Text(
                      _currentStatus.toUpperCase(),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor()),
                    ),
                    const SizedBox(height: 5),
                    const Text("Status Akad Saat Ini",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. DATA DETAIL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _rowDetail(
                        "Nasabah", widget.dataAkad['nama_nasabah'] ?? '-'),
                    const Divider(),
                    _rowDetail("Barang", widget.dataAkad['nama_barang'] ?? '-'),
                    const Divider(),
                    _rowDetail("Harga Pokok", _formatter.format(hargaBeli)),
                    _rowDetail("Margin", _formatter.format(margin)),
                    const Divider(),
                    _rowDetail("Total Piutang", _formatter.format(totalPiutang),
                        isBold: true),
                    const Divider(),
                    _rowDetail(
                        "Tenor", "${widget.dataAkad['jangka_waktu']} Bulan"),
                    _rowDetail(
                        "Angsuran", "${_formatter.format(angsuran)}/bln"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. TOMBOL WHATSAPP
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Aksi Komunikasi",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    icon:
                        const Icon(Icons.share, color: Colors.white, size: 18),
                    label: const Text("Tinjau Pimpinan",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () {
                      String msg = "*PENGAJUAN MURABAHAH*\n\n"
                          "Mohon tinjauan Bapak/Ibu Pimpinan untuk pengajuan berikut:\n\n"
                          "Nama: ${widget.dataAkad['nama_nasabah']}\n"
                          "Barang: ${widget.dataAkad['nama_barang']}\n"
                          "Total: ${_formatter.format(totalPiutang)}\n"
                          "Tenor: ${widget.dataAkad['jangka_waktu']} Bulan\n\n"
                          "Terima Kasih.";
                      _launchWA(phone: "", message: msg);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366)),
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    label: const Text("Info ke Nasabah",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () {
                      String statusText = "";
                      if (_currentStatus == 'Disetujui') {
                        statusText =
                            "telah *DISETUJUI*. Silakan datang ke kantor BMT untuk proses serah terima barang.";
                      } else if (_currentStatus == 'Tidak Disetujui') {
                        statusText =
                            "mohon maaf *BELUM DAPAT DISETUJUI* saat ini.";
                      } else {
                        statusText =
                            "saat ini sedang dalam proses *PENGAJUAN/TINJAUAN*.";
                      }

                      String msg =
                          "Assalamu'alaikum ${widget.dataAkad['nama_nasabah']},\n\n"
                          "Informasi mengenai pengajuan Jual Beli (Murabahah) Anda untuk barang: *${widget.dataAkad['nama_barang']}*,\n"
                          "$statusText\n\n"
                          "Terima Kasih.\nBMT Al-Mukminin";

                      _launchWA(
                          phone: widget.dataAkad['telepon'] ?? '',
                          message: msg);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. TOMBOL UPDATE STATUS
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Update Status Akad",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _updateStatus('Pengajuan'),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    backgroundColor: _currentStatus == 'Pengajuan'
                        ? Colors.orange[50]
                        : null),
                child: const Text("Kembalikan ke Status Pengajuan",
                    style: TextStyle(color: Colors.orange)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => _updateStatus('Tidak Disetujui'),
                    child: const Text("TIDAK DISETUJUI",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => _updateStatus('Disetujui'),
                    child: const Text("DISETUJUI",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _rowDetail(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16)),
        ],
      ),
    );
  }
}
