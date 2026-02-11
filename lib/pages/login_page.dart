import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  void _handleLogin() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username dan Password wajib diisi'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(username, password);

      if (!mounted) return;

      if (response['status'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Login Gagal'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal terhubung ke server.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ukuran layar
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        // Agar keyboard tidak menutupi form & bisa discroll
        child: Stack(
          children: [
            // 1. BACKGROUND HEADER (HIJAU)
            Container(
              height: size.height * 0.45, // Tinggi header 45% layar
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),

            // 2. KONTEN (LOGO + FORM)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.05), // Jarak dari atas

                    // --- LOGO & JUDUL (YANG DIUBAH) ---
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: const Color(0xFF2E7D32),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Padding agar gambar tidak mentok pinggir
                        child: Image.asset(
                          'assets/logo.png', // Ganti dengan path icon Anda
                          width: 150,
                          height: 150,
                          // Jika icon Anda transparan dan ingin diwarnai hijau, uncomment baris bawah:
                          // color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'BMT AL MUKMININ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Sistem Informasi Manajemen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    SizedBox(
                        height:
                            size.height * 0.05), // Jarak antara Judul & Kartu

                    // --- KARTU FORM LOGIN ---
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Login Aplikasi",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Masukkan akun untuk melanjutkan",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 25),

                            // Input Username
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: const Icon(Icons.person_outline,
                                    color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Input Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  _handleLogin(), // Enter langsung login
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Tombol Login
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'MASUK',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Footer Version
                    const Text(
                      "Versi 1.0.0",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(
                        height: 20), // Padding bawah agar scroll mentok nyaman
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
