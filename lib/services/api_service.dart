import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔗 ALAMAT KANTOR PUSAT (SERVER)
  static const String baseUrl = "https://bmt-almukminin.optimisapp.my.id/api";

  // --- 1. LOGIN ADMIN ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": false,
          "message": "Server Error: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"status": false, "message": "Gagal Konek: $e"};
    }
  }

  // --- 2. AMBIL DATA ANGGOTA ---
  Future<List<dynamic>> getAllAnggota() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/anggota.php'));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == true) {
          return result['data']; // Kembalikan list anggota
        }
      }
      return [];
    } catch (e) {
      print("Error ambil anggota: $e");
      return [];
    }
  }

  // --- 3. TAMBAH ANGGOTA BARU ---
  Future<bool> insertAnggota(Map<String, dynamic> data) async {
    try {
      // Tambahkan action 'insert' agar PHP tahu ini data baru
      data['action'] = 'insert';

      final response = await http.post(
        Uri.parse('$baseUrl/anggota.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'];
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- 4. UPDATE ANGGOTA ---
  Future<bool> updateAnggota(Map<String, dynamic> data) async {
    try {
      data['action'] = 'update'; // Beritahu PHP ini update
      final response = await http.post(
        Uri.parse('$baseUrl/anggota.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'];
      }
      return false;
    } catch (e) {
      return false;
    }
  }
// --- FITUR TABUNGAN / WADIAH ---

  // A. Ambil Data Per Nasabah (Untuk Cek Saldo & Detail di Sheet)
  Future<Map<String, dynamic>> getWadiah(int nasabahId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/tabungan.php?nasabah_id=$nasabahId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": false, "message": "Server Error"};
    } catch (e) {
      return {"status": false, "message": "Koneksi Error: $e"};
    }
  }

  // B. Ambil SEMUA Riwayat Global (Untuk Halaman Utama Tabungan)
  Future<List<dynamic>> getAllTransaksiWadiah() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tabungan.php'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // C. Kirim Transaksi (Setor/Tarik)
  Future<Map<String, dynamic>> inputWadiah(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tabungan.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": false, "message": "Gagal menghubungi server"};
    } catch (e) {
      return {"status": false, "message": "Error: $e"};
    }
  }

  // D. Hapus Transaksi
  Future<bool> deleteTransaksiWadiah(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tabungan.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }
  // --- FITUR: AKAD JUAL BELI ---

  // A. Ambil Daftar Akad
  Future<List<dynamic>> getAkadJualBeli() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/akad_jual_beli.php'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // B. Input Akad Baru
  Future<bool> insertAkadJualBeli(Map<String, dynamic> data) async {
    try {
      data['action'] = 'insert';
      final response = await http.post(
        Uri.parse('$baseUrl/akad_jual_beli.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // C. Update Status (Approve/Reject)
  Future<bool> updateStatusAkad(int id, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/akad_jual_beli.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"action": "update_status", "id": id, "status": newStatus}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // D. Hapus Akad (Fitur Tambahan)
  Future<bool> deleteAkadJualBeli(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/akad_jual_beli.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }
  // --- FITUR: TRANSAKSI JUAL BELI (CICILAN) ---

  // A. Ambil Riwayat & Statistik
  Future<Map<String, dynamic>> getTransaksiJualBeli() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/transaksi_jual_beli.php'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": false};
    } catch (e) {
      return {"status": false};
    }
  }

  // B. Ambil List Akad Aktif (Untuk Input Bayar)
  Future<List<dynamic>> getAkadAktifForBayar() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_jual_beli.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "get_akad_aktif"}),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // C. Input Bayar Cicilan
  Future<bool> inputBayarCicilan(Map<String, dynamic> data) async {
    try {
      data['action'] = 'input_bayar';
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_jual_beli.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // D. Hapus Cicilan
  Future<bool> deleteCicilan(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_jual_beli.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }
  // --- FITUR 3: MUDHARABAH (BAGI HASIL) ---

  // A. Ambil Data Akad & Statistik
  Future<Map<String, dynamic>> getMudharabah() async {
    try {
      // UBAH: akad_bagi_hasil.php
      final response =
          await http.get(Uri.parse('$baseUrl/akad_bagi_hasil.php'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": false};
    } catch (e) {
      return {"status": false};
    }
  }

  // B. Input Akad Baru
  Future<int> insertMudharabah(Map<String, dynamic> data) async {
    try {
      data['action'] = 'insert';
      // UBAH: akad_bagi_hasil.php
      final response = await http.post(
        Uri.parse('$baseUrl/akad_bagi_hasil.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      if (result['status'] == true) {
        return int.tryParse(result['id'].toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
  // --- FITUR: TRANSAKSI MUDHARABAH (LANJUTAN) ---

  // A. Ambil Riwayat Per Akad
  Future<List<dynamic>> getRiwayatBagiHasil(int akadId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/transaksi_bagi_hasil.php?akad_id=$akadId'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // B. Input Transaksi Bagi Hasil
  Future<bool> insertTransaksiBagiHasil(Map<String, dynamic> data) async {
    try {
      data['action'] = 'insert';
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_bagi_hasil.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }
  // --- TAMBAHAN UNTUK HAPUS BAGI HASIL ---

  Future<bool> deleteTransaksiBagiHasil(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_bagi_hasil.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'];
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  // --- TAMBAHAN KHUSUS BAGI HASIL (MUDHARABAH) ---

  // C. Update Status Akad
  Future<bool> updateStatusAkadBagiHasil(int id, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/akad_bagi_hasil.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"action": "update_status", "id": id, "status": newStatus}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // D. Hapus Akad
  Future<bool> deleteAkadBagiHasil(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/akad_bagi_hasil.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body); // Pastikan PHP return JSON
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // E. Update Data Akad (Edit Form)
  Future<bool> updateDataAkadBagiHasil(Map<String, dynamic> data) async {
    try {
      data['action'] = 'update_data'; // Action sesuai PHP
      final response = await http.post(
        Uri.parse('$baseUrl/akad_bagi_hasil.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }
  // --- FITUR 4: PINJAMAN LUNAK ---

  // A. Ambil Data
  Future<Map<String, dynamic>> getPinjamanLunak() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/akad_pinjaman_lunak.php'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": false};
    } catch (e) {
      return {"status": false};
    }
  }

  // B. Insert Data
  Future<int> insertPinjamanLunak(Map<String, dynamic> data) async {
    try {
      data['action'] = 'insert';
      final response = await http.post(
        Uri.parse('$baseUrl/akad_pinjaman_lunak.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      if (result['status'] == true) {
        return int.tryParse(result['id'].toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // C. Update Status
  Future<bool> updateStatusPinjaman(int id, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/akad_pinjaman_lunak.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"action": "update_status", "id": id, "status": newStatus}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // D. Hapus Pinjaman Lunak (Tambahkan ini)
  Future<bool> deletePinjamanLunak(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/akad_pinjaman_lunak.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // --- FITUR: TRANSAKSI PINJAMAN LUNAK ---

  // A. Ambil Riwayat & Statistik
  Future<Map<String, dynamic>> getTransaksiCicilanPinjaman() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/transaksi_pinjaman_lunak.php'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": false};
    } catch (e) {
      return {"status": false};
    }
  }

  // B. Ambil Peminjam Aktif (Untuk Dropdown)
  Future<List<dynamic>> getPeminjamAktif() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_pinjaman_lunak.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "get_peminjam_aktif"}),
      );
      final result = jsonDecode(response.body);
      return result['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // C. Input Cicilan
  Future<Map<String, dynamic>> insertCicilanPinjaman(
      Map<String, dynamic> data) async {
    try {
      data['action'] = 'insert';
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_pinjaman_lunak.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false};
    }
  }

  // D. Hapus Cicilan
  Future<bool> deleteCicilanPinjaman(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_pinjaman_lunak.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // E. Get Sisa Pinjaman
  Future<double> getSisaPinjaman(int pinjamanId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_pinjaman_lunak.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "get_sisa", "pinjaman_id": pinjamanId}),
      );
      final result = jsonDecode(response.body);
      if (result['status'] == true) {
        return double.tryParse(result['sisa'].toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // --- FITUR 5: USAHA BERSAMA ---

  // A. Get List Usaha
  Future<List<dynamic>> getUsahaBersama() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/usaha_bersama.php'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // B. Tambah Usaha Baru
  Future<bool> addUsahaBersama(Map<String, dynamic> data) async {
    try {
      data['action'] = 'insert';
      final response = await http.post(
        Uri.parse('$baseUrl/usaha_bersama.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // --- LANJUTAN USAHA BERSAMA ---

  // C. Hapus Usaha
  Future<bool> deleteUsahaBersama(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usaha_bersama.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // D. Get Total Modal Terkumpul (Real)
  Future<double> getModalUsahaTerkumpul(int usahaId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usaha_bersama.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "get_modal_real", "usaha_id": usahaId}),
      );
      final result = jsonDecode(response.body);
      if (result['status'] == true) {
        return double.tryParse(result['total'].toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // E. Update PJ & Pelaksana
  Future<bool> updatePjPelaksanaUsaha(
      int id, String pjNama, String dataPelaksana) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usaha_bersama.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "update_pj_pelaksana",
          "id": id,
          "pj_nama": pjNama,
          "data_pelaksana": dataPelaksana
        }),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // --- FITUR: PERMODALAN USAHA ---

  // A. Get List Modal by Usaha ID
  Future<List<dynamic>> getModalUsaha(int usahaId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/usaha_modal.php?usaha_id=$usahaId'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // B. Insert Modal
  Future<int> insertModalUsaha(Map<String, dynamic> data) async {
    try {
      data['action'] = 'insert';
      final response = await http.post(
        Uri.parse('$baseUrl/usaha_modal.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      if (result['status'] == true) {
        return int.tryParse(result['id'].toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // C. Delete Modal
  Future<bool> deleteModalUsaha(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usaha_modal.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // --- FITUR: PEMASUKAN USAHA ---

  // A. Get Pemasukan by Usaha ID
  Future<List<dynamic>> getPemasukanUsaha(int usahaId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/usaha_pemasukan.php?usaha_id=$usahaId'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // B. Insert Pemasukan
  Future<int> insertPemasukanUsaha(Map<String, dynamic> data) async {
    try {
      data['action'] = 'insert';
      final response = await http.post(
        Uri.parse('$baseUrl/usaha_pemasukan.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final result = jsonDecode(response.body);
      if (result['status'] == true) {
        return int.tryParse(result['id'].toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // C. Delete Pemasukan
  Future<bool> deletePemasukanUsaha(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usaha_pemasukan.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // --- FITUR: LAPORAN USAHA ---

  // A. Get Riwayat Laporan
  Future<List<dynamic>> getLaporanUsaha(int usahaId) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/usaha_laporan.php?action=get_laporan&usaha_id=$usahaId'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // B. Get Total Pemasukan Pending
  Future<double> getPemasukanPending(int usahaId) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/usaha_laporan.php?action=get_pending&usaha_id=$usahaId'));
      final result = jsonDecode(response.body);
      if (result['status'] == true) {
        return double.tryParse(result['total'].toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // C. Proses Bagi Hasil (UPDATED: Return Map agar pesan error bisa tampil di UI)
  Future<Map<String, dynamic>> prosesBagiHasil(
      Map<String, dynamic> data) async {
    try {
      print("--- DEBUG BAGI HASIL ---");
      print("URL: $baseUrl/usaha_laporan.php");
      print("Data Dikirim: $data");

      data['action'] = 'proses_bagi_hasil';

      final response = await http.post(
        Uri.parse('$baseUrl/usaha_laporan.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Mengembalikan Map lengkap (status & message)
        return {
          "status": result['status'] ?? false,
          "message": result['message'] ?? "Gagal tanpa pesan error"
        };
      }
      return {
        "status": false,
        "message": "Server Error: ${response.statusCode}"
      };
    } catch (e) {
      print("ERROR EXCEPTION: $e");
      return {"status": false, "message": "Koneksi Error: $e"};
    }
  }

  // D. Hapus Laporan Usaha
  Future<bool> deleteLaporanUsaha(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usaha_laporan.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete_laporan", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'];
    } catch (e) {
      return false;
    }
  }

  // --- TAMBAHAN: HAPUS ANGGOTA ---
  Future<bool> deleteAnggota(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/anggota.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "delete", "id": id}),
      );
      final result = jsonDecode(response.body);
      return result['status'] == true;
    } catch (e) {
      return false;
    }
  }

  // --- TAMBAHAN DI API SERVICE: Get Riwayat Angsuran Spesifik ---
  Future<List<dynamic>> getRiwayatAngsuranMurabahah(int akadId) async {
    try {
      // Pastikan backend PHP Anda mendukung action 'get_riwayat' di transaksi_jual_beli.php
      // Atau sesuaikan dengan endpoint yang tersedia
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_jual_beli.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "get_riwayat", "akad_id": akadId}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Cek jika returnnya list langsung atau dibungkus 'data'
        if (result is List) return result;
        if (result['data'] != null) return result['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- TAMBAHAN DI API SERVICE: Get Riwayat Cicilan Pinjaman ---
  Future<List<dynamic>> getRiwayatCicilanPinjaman(int pinjamanId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi_pinjaman_lunak.php'),
        headers: {"Content-Type": "application/json"},
        // Pastikan PHP Anda menangani action 'get_riwayat' atau sesuaikan
        body: jsonEncode({"action": "get_riwayat", "pinjaman_id": pinjamanId}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Handle jika return langsung list atau dibungkus 'data'
        if (result is List) return result;
        if (result['data'] != null) return result['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- TAMBAHAN DI API SERVICE: Get Modal Usaha Per Nasabah ---
  Future<List<dynamic>> getModalUsahaByNasabah(String namaNasabah) async {
    try {
      // Endpoint ini asumsinya mengambil semua data modal, nanti difilter di aplikasi
      // Atau idealnya buat endpoint khusus di PHP: usaha_modal.php?action=get_by_nasabah&nama=...

      // SEMENTARA: Kita pakai getModalUsaha() yg sudah ada, tapi itu butuh usaha_id.
      // JADI KITA BUAT SOLUSI ALTERNATIF: Ambil semua usaha, lalu loop ambil modalnya.
      // TAPI ITU BERAT.

      // SOLUSI TERBAIK: Tambahkan action baru di PHP atau gunakan endpoint custom.
      // Di sini saya gunakan simulasi ambil data via POST custom jika backend mendukung.

      final response = await http.post(
        Uri.parse('$baseUrl/usaha_modal.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"action": "get_by_nasabah_name", "nama_nasabah": namaNasabah}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['data'] != null) return result['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
