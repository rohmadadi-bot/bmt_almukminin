import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../utils/backup_restore_helper.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  final BackupRestoreHelper _backupHelper = BackupRestoreHelper();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (mounted) {
        setState(() {
          _currentUser = account;
        });
      }
    });
    _googleSignIn.signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Backup & Restore Data"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: AKUN PENGELOLA ---
            const Text(
              "Akun Pengelola & Cloud",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  if (_currentUser != null)
                    _buildLoggedInView()
                  else
                    _buildLoggedOutView(),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- BAGIAN 2: PENYIMPANAN LOKAL ---
            const Text(
              "Penyimpanan Lokal (Manual)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // TOMBOL SHARE (BACKUP LOKAL)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.share, color: Colors.black54, size: 30),
                ),
                title: const Text("Backup Database (Lokal)",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Kirim manual via WhatsApp / Email"),
                onTap: () => _backupHelper.backupDatabase(context),
              ),
            ),

            const SizedBox(height: 15),

            // TOMBOL RESTORE LOKAL
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restore_page,
                      color: Colors.orange, size: 30),
                ),
                title: const Text("Restore Database (Lokal)",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Pilih file .db dari penyimpanan HP"),
                onTap: () {
                  _showWarningDialog(context, () {
                    _backupHelper.restoreDatabase(context);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG PERINGATAN RESTORE ---
  void _showWarningDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Peringatan Restore"),
        content: const Text(
            "Tindakan ini akan MENGHAPUS seluruh data saat ini dan menggantinya dengan file backup.\n\nPastikan Anda memilih file yang benar. Lanjutkan?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child:
                const Text("TIMPA DATA", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildLoggedOutView() {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.red[50],
            child: const Icon(Icons.mail, color: Colors.red),
          ),
          title: const Text("Login dengan Google"),
          subtitle: const Text("Untuk mengaktifkan Backup ke Drive"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            _backupHelper.loginWithGoogle(context, _googleSignIn);
          },
        ),
      ],
    );
  }

  Widget _buildLoggedInView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GoogleUserCircleAvatar(identity: _currentUser!),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.displayName ?? "Tanpa Nama",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentUser?.email ?? "-",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: Colors.blue, size: 20),
            ],
          ),
        ),
        const Divider(height: 1),

        // TOMBOL 1: BACKUP KE DRIVE
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green[50],
            child: const Icon(Icons.add_to_drive, color: Colors.green),
          ),
          title: const Text("Backup ke Google Drive",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          subtitle: const Text("Upload ke folder 'BMT Al-Mukminin/Backup'"),
          onTap: () =>
              _backupHelper.backupToGoogleDrive(context, _googleSignIn),
        ),

        const Divider(height: 1),

        // TOMBOL 2: RESTORE DARI DRIVE (BARU)
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: const Icon(Icons.cloud_download, color: Colors.blue),
          ),
          title: const Text("Restore dari Google Drive",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          subtitle: const Text("Download & Timpa data dari Cloud"),
          onTap: () {
            _showWarningDialog(context, () {
              _backupHelper.restoreFromGoogleDrive(context, _googleSignIn);
            });
          },
        ),

        const Divider(height: 1),

        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.logout, color: Colors.black54),
          ),
          title: const Text("Logout"),
          onTap: () {
            _backupHelper.logoutGoogle(context, _googleSignIn);
          },
        ),
      ],
    );
  }
}
