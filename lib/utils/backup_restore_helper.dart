import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';

import '../data/db_helper.dart';

class BackupRestoreHelper {
  final DbHelper _dbHelper = DbHelper();

  // --- LOGIN GOOGLE ---
  Future<void> loginWithGoogle(
      BuildContext context, GoogleSignIn googleSignIn) async {
    try {
      await googleSignIn.signIn();
    } catch (e) {
      _showSnackBar(context, "Gagal Login Google: $e", Colors.red);
    }
  }

  // --- LOGOUT GOOGLE ---
  Future<void> logoutGoogle(
      BuildContext context, GoogleSignIn googleSignIn) async {
    await googleSignIn.signOut();
    _showSnackBar(context, "Berhasil Logout", Colors.grey);
  }

  // --- GET DATABASE FILE ---
  Future<File> _getDatabaseFile() async {
    final Database db = await _dbHelper.database;
    String path = db.path;
    return File(path);
  }

  // --- FUNGSI 1: BACKUP LOKAL (SHARE) ---
  Future<void> backupDatabase(BuildContext context) async {
    try {
      File dbFile = await _getDatabaseFile();
      if (await dbFile.exists()) {
        await Share.shareXFiles([XFile(dbFile.path)],
            subject: 'Backup Database BMT',
            text: 'Simpan file ini ke WhatsApp atau Google Drive Anda.');
      } else {
        _showSnackBar(
            context, "File database fisik tidak ditemukan.", Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, "Gagal Backup Lokal: $e", Colors.red);
    }
  }

  // --- FUNGSI 2: BACKUP KE GOOGLE DRIVE ---
  Future<void> backupToGoogleDrive(
      BuildContext context, GoogleSignIn googleSignIn) async {
    try {
      if (await googleSignIn.isSignedIn() == false) {
        _showSnackBar(
            context, "Harap Login Google terlebih dahulu", Colors.orange);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      var httpClient = await googleSignIn.authenticatedClient();
      if (httpClient == null) throw "Gagal autentikasi.";

      var driveApi = drive.DriveApi(httpClient);

      // Folder Structure
      String? parentId =
          await _getOrCreateFolder(driveApi, "BMT Al-Mukminin", null);
      if (parentId == null) throw "Gagal membuat folder induk";
      String? backupFolderId =
          await _getOrCreateFolder(driveApi, "Backup", parentId);
      if (backupFolderId == null) throw "Gagal membuat folder backup";

      // File
      File localFile = await _getDatabaseFile();
      if (!localFile.existsSync()) throw "Database lokal belum tersedia";

      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = "backup_bmt_$timestamp.db";

      var driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = [backupFolderId];

      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(localFile.openRead(), localFile.lengthSync()),
      );

      if (context.mounted) {
        Navigator.pop(context); // Tutup Loading
        _showSnackBar(
            context, "Sukses Backup ke Drive: $fileName", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar(context, "Gagal Upload: $e", Colors.red);
      }
    }
  }

  // --- FUNGSI 3: RESTORE DARI GOOGLE DRIVE (BARU) ---
  Future<void> restoreFromGoogleDrive(
      BuildContext context, GoogleSignIn googleSignIn) async {
    try {
      // 1. Cek Login
      if (await googleSignIn.isSignedIn() == false) {
        _showSnackBar(
            context, "Harap Login Google terlebih dahulu", Colors.orange);
        return;
      }

      // 2. Loading Awal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      var httpClient = await googleSignIn.authenticatedClient();
      if (httpClient == null) throw "Gagal autentikasi client.";
      var driveApi = drive.DriveApi(httpClient);

      // 3. Cari Folder Backup
      String? parentId =
          await _getOrCreateFolder(driveApi, "BMT Al-Mukminin", null);
      if (parentId == null) throw "Folder BMT tidak ditemukan di Drive.";

      String? backupFolderId =
          await _getOrCreateFolder(driveApi, "Backup", parentId);
      if (backupFolderId == null) throw "Folder Backup tidak ditemukan.";

      // 4. List File di Folder Backup
      var fileList = await driveApi.files.list(
        q: "'$backupFolderId' in parents and trashed = false",
        orderBy: "createdTime desc", // Urutkan dari yang terbaru
        $fields: "files(id, name, createdTime, size)",
      );

      if (context.mounted) {
        Navigator.pop(context); // Tutup Loading Awal
      }

      if (fileList.files == null || fileList.files!.isEmpty) {
        if (context.mounted) {
          _showSnackBar(
              context, "Tidak ada file backup di Google Drive.", Colors.orange);
        }
        return;
      }

      // 5. Tampilkan Dialog Pilih File
      if (context.mounted) {
        _showFileSelectionDialog(context, driveApi, fileList.files!);
      }
    } catch (e) {
      if (context.mounted) {
        // Pastikan loading tertutup jika error
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showSnackBar(context, "Gagal Mengambil Data Drive: $e", Colors.red);
      }
    }
  }

  // --- HELPER: Dialog Pilih File Drive ---
  void _showFileSelectionDialog(
      BuildContext context, drive.DriveApi driveApi, List<drive.File> files) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pilih File Backup",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (ctx, index) {
                    final file = files[index];
                    // Format Tanggal
                    String dateStr = "?";
                    if (file.createdTime != null) {
                      dateStr = DateFormat('dd MMM yyyy, HH:mm')
                          .format(file.createdTime!.toLocal());
                    }

                    return ListTile(
                      leading:
                          const Icon(Icons.description, color: Colors.blue),
                      title: Text(file.name ?? "Tanpa Nama"),
                      subtitle: Text(dateStr),
                      onTap: () {
                        Navigator.pop(ctx); // Tutup Dialog
                        _downloadAndRestore(
                            context, driveApi, file); // Proses Restore
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HELPER: Download & Overwrite Database ---
  Future<void> _downloadAndRestore(BuildContext context,
      drive.DriveApi driveApi, drive.File driveFile) async {
    // Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Download File dari Drive
      drive.Media media = await driveApi.files.get(
        driveFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      List<int> dataStore = [];
      await media.stream.forEach((data) {
        dataStore.addAll(data);
      });

      // 2. Persiapan Timpa Database Lokal
      final Database db = await _dbHelper.database;
      String dbPath = db.path;
      await db.close(); // PENTING: Tutup koneksi dulu

      // 3. Tulis File
      File localFile = File(dbPath);
      await localFile.writeAsBytes(dataStore, flush: true);

      if (context.mounted) {
        Navigator.pop(context); // Tutup Loading
        _showSnackBar(
            context, "Restore SUKSES! Silakan RESTART Aplikasi.", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar(context, "Gagal Restore: $e", Colors.red);
      }
    }
  }

  // --- HELPER: CARI/BUAT FOLDER ---
  Future<String?> _getOrCreateFolder(
      drive.DriveApi driveApi, String folderName, String? parentId) async {
    String query =
        "mimeType = 'application/vnd.google-apps.folder' and name = '$folderName' and trashed = false";
    if (parentId != null) query += " and '$parentId' in parents";

    var response = await driveApi.files.list(q: query);

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id;
    } else {
      var folder = drive.File();
      folder.name = folderName;
      folder.mimeType = "application/vnd.google-apps.folder";
      if (parentId != null) folder.parents = [parentId];
      var createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    }
  }

  // --- RESTORE LOKAL (FILE PICKER) ---
  Future<void> restoreDatabase(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File sourceFile = File(result.files.single.path!);
        final Database db = await _dbHelper.database;
        String targetPath = db.path;
        await db.close();

        await sourceFile.copy(targetPath);
        _showSnackBar(context, "Restore Berhasil! Silakan RESTART Aplikasi.",
            Colors.green);
      }
    } catch (e) {
      _showSnackBar(context, "Gagal Restore: $e", Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}
