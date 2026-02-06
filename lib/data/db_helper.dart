import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  static Database? _database;

  factory DbHelper() => _instance;

  DbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'bmt_almukminin.db');
    return await openDatabase(
      path,
      // UPDATE: Upgraded to Version 17
      version: 17,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // 1. Admin Table
    await db.execute('''
      CREATE TABLE admin (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        last_login TEXT
      )
    ''');

    // 2. Members Table
    await db.execute('''
      CREATE TABLE anggota (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nik TEXT UNIQUE,             
        nama TEXT NOT NULL,
        telepon TEXT,
        alamat TEXT,
        status TEXT DEFAULT 'Aktif', 
        rekening_bank TEXT,          
        tgl_daftar TEXT,             
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 3. Wadiah Transaction Table
    await _createTableWadiah(db);

    // 4. Murabahah (Buying and Selling) & Installment Table
    await _createTableJualBeli(db);

    // 5. Joint Venture (Usaha Bersama) Table
    await _createTableUsahaBersama(db);

    // 6. Venture Capital Table
    await _createTableModalUsaha(db);

    // 7. Venture Income Table
    await _createTablePemasukanUsaha(db);

    // 8. Venture Report Table
    await _createTableLaporanUsaha(db);

    // 9. Mudharabah Table
    await _createTableMudharabah(db);

    // 10. Mudharabah Transaction Table
    await _createTableMudharabahTransaksi(db);

    // 11. Soft Loan (Pinjaman Lunak) Table
    await _createTablePinjamanLunak(db);

    // 12. Soft Loan Installment Table
    await _createTableCicilanPinjamanLunak(db);

    // 13. BMT Capital Table
    await _createTablePermodalan(db);

    // 14. BMT Fund Table (SPECIAL 5%)
    await _createTableDanaBMT(db);

    // 15. BMT Expenditure Table (NEW - VERSION 16)
    await _createTablePengeluaranBMT(db);

    // Insert Default Admin
    await db.insert('admin', {
      'username': 'admin',
      'password': '123',
      'last_login': DateTime.now().toString(),
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTableWadiah(db);
    }
    if (oldVersion < 3) {
      await _createTableJualBeli(db);
    }
    if (oldVersion < 4) {
      await _createTableUsahaBersama(db);
    }
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE usaha_bersama ADD COLUMN pj_nama TEXT");
        await db.execute(
            "ALTER TABLE usaha_bersama ADD COLUMN data_pelaksana TEXT");
      } catch (e) {
        print("Column might already exist: $e");
      }
      await _createTableModalUsaha(db);
    }
    if (oldVersion < 6) {
      await _createTablePemasukanUsaha(db);
    }
    if (oldVersion < 7) {
      await _createTableLaporanUsaha(db);
    }
    if (oldVersion < 8) {
      await _createTableMudharabah(db);
    }
    if (oldVersion < 9) {
      try {
        await db
            .execute("ALTER TABLE mudharabah_akad ADD COLUMN nama_usaha TEXT");
      } catch (e) {
        print("Column nama_usaha might already exist: $e");
      }
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
            "ALTER TABLE mudharabah_akad ADD COLUMN nominal_modal REAL DEFAULT 0");
        await db.execute(
            "ALTER TABLE mudharabah_akad ADD COLUMN nisbah_nasabah REAL DEFAULT 0");
        await db.execute(
            "ALTER TABLE mudharabah_akad ADD COLUMN nisbah_bmt REAL DEFAULT 0");
      } catch (e) {
        print("Columns v10 might already exist: $e");
      }
    }
    if (oldVersion < 11) {
      await _createTableMudharabahTransaksi(db);
    }
    if (oldVersion < 12) {
      await _createTablePinjamanLunak(db);
    }
    if (oldVersion < 13) {
      await _createTableCicilanPinjamanLunak(db);
    }
    if (oldVersion < 14) {
      await _createTablePermodalan(db);
    }
    if (oldVersion < 15) {
      await _createTableDanaBMT(db);
    }
    if (oldVersion < 16) {
      await _createTablePengeluaranBMT(db);
    }
  }

  // --- TABLE DEFINITIONS ---

  Future _createTableWadiah(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaksi_wadiah (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nasabah_id INTEGER,
        jenis TEXT,
        jumlah REAL,
        keterangan TEXT,
        tgl_transaksi TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nasabah_id) REFERENCES anggota (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTableJualBeli(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS murabahah_akad (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nasabah_id INTEGER,
        nama_barang TEXT,
        harga_beli REAL,
        margin REAL,
        total_piutang REAL,
        jangka_waktu INTEGER,
        angsuran_bulanan REAL,
        tgl_akad TEXT,
        status TEXT DEFAULT 'Aktif',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nasabah_id) REFERENCES anggota (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS murabah_angsuran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        akad_id INTEGER,
        angsuran_ke INTEGER,
        jumlah_bayar REAL,
        tgl_bayar TEXT,
        keterangan TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (akad_id) REFERENCES murabahah_akad (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTableUsahaBersama(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usaha_bersama (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_usaha TEXT,
        jenis_usaha TEXT,
        modal_awal REAL,
        deskripsi TEXT,
        pj_nama TEXT,
        data_pelaksana TEXT,
        tgl_mulai TEXT,
        status TEXT DEFAULT 'Aktif',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future _createTableModalUsaha(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usaha_modal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usaha_id INTEGER,
        nama_pemodal TEXT,
        jumlah_modal REAL,
        tgl_setor TEXT,
        FOREIGN KEY (usaha_id) REFERENCES usaha_bersama (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTablePemasukanUsaha(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usaha_pemasukan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usaha_id INTEGER,
        jumlah REAL,
        tgl_transaksi TEXT,
        keterangan TEXT,
        status TEXT DEFAULT 'Belum Dibagi',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (usaha_id) REFERENCES usaha_bersama (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTableLaporanUsaha(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usaha_laporan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usaha_id INTEGER,
        total_lapor REAL,
        tgl_lapor TEXT,
        keterangan TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (usaha_id) REFERENCES usaha_bersama (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTableMudharabah(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mudharabah_akad (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nasabah_id INTEGER,
        nama_usaha TEXT,
        deskripsi_usaha TEXT,
        tgl_akad TEXT,
        nominal_modal REAL DEFAULT 0,  
        nisbah_nasabah REAL DEFAULT 0, 
        nisbah_bmt REAL DEFAULT 0,     
        status TEXT DEFAULT 'Aktif',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nasabah_id) REFERENCES anggota (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTableMudharabahTransaksi(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mudharabah_transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        akad_id INTEGER,
        tgl_transaksi TEXT,
        total_keuntungan REAL,
        bagian_nasabah REAL,
        bagian_bmt REAL,
        keterangan TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (akad_id) REFERENCES mudharabah_akad (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTablePinjamanLunak(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pinjaman_lunak (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nasabah_id INTEGER,
        tgl_pengajuan TEXT,
        nominal REAL,
        deskripsi TEXT,
        status TEXT DEFAULT 'Pengajuan',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nasabah_id) REFERENCES anggota (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTableCicilanPinjamanLunak(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pinjaman_lunak_cicilan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pinjaman_id INTEGER,
        tgl_bayar TEXT,
        jumlah_bayar REAL,
        keterangan TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (pinjaman_id) REFERENCES pinjaman_lunak (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createTablePermodalan(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS permodalan(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pemodal TEXT,
        nominal INTEGER,
        tanggal TEXT
      )
    ''');
  }

  Future _createTableDanaBMT(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dana_bmt (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sumber TEXT,
        jumlah REAL,
        tanggal TEXT,
        keterangan TEXT
      )
    ''');
  }

  Future _createTablePengeluaranBMT(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pengeluaran_bmt (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kategori TEXT,
        nama_pengeluaran TEXT,
        nominal INTEGER,
        tanggal TEXT,
        keterangan TEXT
      )
    ''');
  }

  // --- CRUD FUNCTIONS (METHODS) ---

  // 1. MEMBER
  Future<int> insertAnggota(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('anggota', row);
  }

  Future<List<Map<String, dynamic>>> getAllAnggota() async {
    Database db = await database;
    return await db.query('anggota', orderBy: 'nama ASC');
  }

  Future<int> updateAnggota(Map<String, dynamic> row) async {
    Database db = await database;
    return await db
        .update('anggota', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteAnggota(int id) async {
    Database db = await database;
    return await db.delete('anggota', where: 'id = ?', whereArgs: [id]);
  }

  // 2. WADIAH
  Future<int> insertTransaksiWadiah(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('transaksi_wadiah', row);
  }

  Future<List<Map<String, dynamic>>> getRiwayatWadiah(int nasabahId) async {
    Database db = await database;
    return await db.query('transaksi_wadiah',
        where: 'nasabah_id = ?', whereArgs: [nasabahId], orderBy: 'id DESC');
  }

  Future<double> getSaldoWadiah(int nasabahId) async {
    Database db = await database;
    var res = await db.rawQuery('''
      SELECT SUM(CASE WHEN jenis = 'Setoran' THEN jumlah ELSE -jumlah END) as saldo
      FROM transaksi_wadiah WHERE nasabah_id = ?
    ''', [nasabahId]);
    return (res.first['saldo'] as num?)?.toDouble() ?? 0.0;
  }

  // 3. BUYING AND SELLING (MURABAHAH)
  Future<int> insertMurabahahAkad(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('murabahah_akad', row);
  }

  Future<List<Map<String, dynamic>>> getAllMurabahahAkad() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT m.*, a.nama as nama_nasabah, a.telepon, a.nik 
      FROM murabahah_akad m
      JOIN anggota a ON m.nasabah_id = a.id
      ORDER BY m.id DESC
    ''');
  }

  Future<int> insertAngsuran(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('murabah_angsuran', row);
  }

  Future<double> getSisaPiutang(int akadId) async {
    Database db = await database;
    var resAkad =
        await db.query('murabahah_akad', where: 'id = ?', whereArgs: [akadId]);
    if (resAkad.isEmpty) return 0.0;

    var resBayar = await db.rawQuery(
        'SELECT SUM(jumlah_bayar) as total FROM murabah_angsuran WHERE akad_id = ?',
        [akadId]);

    double totalPiutang = (resAkad.first['total_piutang'] as num).toDouble();
    double sudahBayar = (resBayar.first['total'] as num?)?.toDouble() ?? 0.0;

    return totalPiutang - sudahBayar;
  }

  Future<List<Map<String, dynamic>>> getRiwayatAngsuran(int akadId) async {
    Database db = await database;
    return await db.query('murabah_angsuran',
        where: 'akad_id = ?', whereArgs: [akadId], orderBy: 'id DESC');
  }

  // 4. JOINT VENTURE (USAHA BERSAMA)
  Future<int> insertUsahaBersama(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('usaha_bersama', row);
  }

  Future<List<Map<String, dynamic>>> getAllUsahaBersama() async {
    Database db = await database;
    return await db.query('usaha_bersama', orderBy: 'id DESC');
  }

  Future<int> updatePjPelaksana(int id, String pj, String pelaksanaJson) async {
    Database db = await database;
    return await db.update(
      'usaha_bersama',
      {
        'pj_nama': pj,
        'data_pelaksana': pelaksanaJson,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 5. VENTURE CAPITAL (MODAL USAHA)
  Future<int> insertModalUsaha(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('usaha_modal', row);
  }

  Future<List<Map<String, dynamic>>> getModalByUsahaId(int usahaId) async {
    Database db = await database;
    return await db.query('usaha_modal',
        where: 'usaha_id = ?',
        whereArgs: [usahaId],
        orderBy: 'jumlah_modal DESC');
  }

  Future<int> deleteModalUsaha(int id) async {
    Database db = await database;
    return await db.delete('usaha_modal', where: 'id = ?', whereArgs: [id]);
  }

  // 6. VENTURE INCOME (PEMASUKAN USAHA)
  Future<int> insertPemasukan(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('usaha_pemasukan', row);
  }

  Future<List<Map<String, dynamic>>> getPemasukanByUsahaId(int usahaId) async {
    Database db = await database;
    return await db.query('usaha_pemasukan',
        where: 'usaha_id = ?',
        whereArgs: [usahaId],
        orderBy: 'tgl_transaksi DESC, id DESC');
  }

  Future<int> deletePemasukan(int id) async {
    Database db = await database;
    return await db.delete('usaha_pemasukan', where: 'id = ?', whereArgs: [id]);
  }

  // 7. [MODIFIED] VENTURE REPORT & DISTRIBUTION (SPLIT 5% and 95%)
  Future<void> buatLaporanUsaha({
    required int usahaId,
    required double totalLapor, // INI NOMINAL KOTOR (100%)
    required String tgl,
    required String ket,
    required String namaUsaha,
  }) async {
    Database db = await database;

    await db.transaction((txn) async {
      // 1. Calculate Distribution
      double danaBmt = totalLapor * 0.05; // 5% Masuk BMT
      double danaSiapDibagi = totalLapor - danaBmt; // 95% Masuk Anggota

      // 2. Simpan Dana BMT ke Tabel Terpisah
      await txn.insert('dana_bmt', {
        'sumber': 'Bagi Hasil: $namaUsaha',
        'jumlah': danaBmt,
        'tanggal': tgl,
        'keterangan': '5% dari Total: $totalLapor. $ket'
      });

      // 3. Simpan Laporan Utama (Simpan NETTO untuk History)
      await txn.insert('usaha_laporan', {
        'usaha_id': usahaId,
        'total_lapor': danaSiapDibagi, // Simpan Netto
        'tgl_lapor': tgl,
        'keterangan': ket
      });

      // 4. Update Income Status
      await txn.rawUpdate('''
        UPDATE usaha_pemasukan 
        SET status = 'Sudah Dibagi' 
        WHERE usaha_id = ? AND status = 'Belum Dibagi'
      ''', [usahaId]);

      // 5. Distribusi ke Anggota (DARI DANA BERSIH)
      List<Map<String, dynamic>> listModal = await txn
          .query('usaha_modal', where: 'usaha_id = ?', whereArgs: [usahaId]);

      double totalModal = 0;
      for (var m in listModal) {
        totalModal += (m['jumlah_modal'] as num).toDouble();
      }

      List<Map<String, dynamic>> listAnggota = await txn.query('anggota');

      if (totalModal > 0) {
        for (var pemodal in listModal) {
          String namaPemodal = pemodal['nama_pemodal'].toString().toLowerCase();
          double modalDia = (pemodal['jumlah_modal'] as num).toDouble();

          // BAGI HASIL MENGGUNAKAN (danaSiapDibagi) BUKAN (totalLapor)
          double jatahBagiHasil = (modalDia / totalModal) * danaSiapDibagi;

          if (jatahBagiHasil > 0) {
            var matchAnggota = listAnggota
                .where((a) => a['nama'].toString().toLowerCase() == namaPemodal)
                .toList();

            if (matchAnggota.isNotEmpty) {
              int nasabahId = matchAnggota.first['id'];

              await txn.insert('transaksi_wadiah', {
                'nasabah_id': nasabahId,
                'jenis': 'Setoran',
                'jumlah': jatahBagiHasil,
                'keterangan': 'Bagi Hasil: $namaUsaha ($tgl)',
                'tgl_transaksi': tgl,
              });
            }
          }
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> getLaporanByUsahaId(int usahaId) async {
    Database db = await database;
    return await db.query('usaha_laporan',
        where: 'usaha_id = ?',
        whereArgs: [usahaId],
        orderBy: 'tgl_lapor DESC, id DESC');
  }

  // --- FUNGSI BARU YANG DITAMBAHKAN ---
  Future<int> deleteLaporanUsaha(int id) async {
    Database db = await database;
    return await db.delete('usaha_laporan', where: 'id = ?', whereArgs: [id]);
  }
  // ------------------------------------

  Future<double> getPemasukanBelumDibagi(int usahaId) async {
    Database db = await database;
    var result = await db.rawQuery('''
      SELECT SUM(jumlah) as total 
      FROM usaha_pemasukan 
      WHERE usaha_id = ? AND status = 'Belum Dibagi'
    ''', [usahaId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // 8. MUDHARABAH CRUD
  Future<int> insertMudharabah(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('mudharabah_akad', row);
  }

  Future<List<Map<String, dynamic>>> getAllMudharabah() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT m.*, a.nama as nama_nasabah, a.nik
      FROM mudharabah_akad m
      JOIN anggota a ON m.nasabah_id = a.id
      ORDER BY m.id DESC
    ''');
  }

  Future<int> updateAkadMudharabah(int id, Map<String, dynamic> values) async {
    Database db = await database;
    return await db.update(
      'mudharabah_akad',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getMudharabahById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT m.*, a.nama as nama_nasabah, a.nik
      FROM mudharabah_akad m
      JOIN anggota a ON m.nasabah_id = a.id
      WHERE m.id = ?
    ''', [id]);

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // MUDHARABAH TRANSACTION CRUD
  Future<int> insertMudharabahTransaksi(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('mudharabah_transaksi', row);
  }

  Future<List<Map<String, dynamic>>> getTransaksiByAkadId(int akadId) async {
    Database db = await database;
    return await db.query(
      'mudharabah_transaksi',
      where: 'akad_id = ?',
      whereArgs: [akadId],
      orderBy: 'id DESC',
    );
  }

  // 9. SOFT LOAN (PINJAMAN LUNAK) CRUD
  Future<int> insertPinjamanLunak(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('pinjaman_lunak', row);
  }

  Future<List<Map<String, dynamic>>> getAllPinjamanLunak() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT p.*, a.nama as nama_nasabah, a.nik, a.telepon
      FROM pinjaman_lunak p
      JOIN anggota a ON p.nasabah_id = a.id
      ORDER BY p.id DESC
    ''');
  }

  Future<int> updateStatusPinjaman(int id, String statusBaru) async {
    Database db = await database;
    return await db.update(
      'pinjaman_lunak',
      {'status': statusBaru},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 10. SOFT LOAN INSTALLMENT CRUD

  // 1. Save Installment
  Future<int> insertCicilanPinjamanLunak(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('pinjaman_lunak_cicilan', row);
  }

  // 2. Get Installment History
  Future<List<Map<String, dynamic>>> getAllCicilanPinjamanLunak() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT c.*, p.nominal as total_pinjaman, a.nama as nama_nasabah, a.telepon
      FROM pinjaman_lunak_cicilan c
      JOIN pinjaman_lunak p ON c.pinjaman_id = p.id
      JOIN anggota a ON p.nasabah_id = a.id
      ORDER BY c.id DESC
    ''');
  }

  // 3. Get Active Borrowers
  Future<List<Map<String, dynamic>>> getPeminjamAktif() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT p.*, a.nama as nama_nasabah, a.telepon
      FROM pinjaman_lunak p
      JOIN anggota a ON p.nasabah_id = a.id
      WHERE p.status = 'Disetujui'
      ORDER BY a.nama ASC
    ''');
  }

  // 4. Calculate Header Statistics
  Future<Map<String, double>> getSummaryPinjamanLunak() async {
    Database db = await database;

    // Total Approved Loans
    var resPinjaman = await db.rawQuery(
        "SELECT SUM(nominal) as total FROM pinjaman_lunak WHERE status = 'Disetujui' OR status = 'Lunas'");

    // Total Installments Received
    var resCicilan = await db.rawQuery(
        "SELECT SUM(jumlah_bayar) as total FROM pinjaman_lunak_cicilan");

    return {
      'total_pinjaman': (resPinjaman.first['total'] as num?)?.toDouble() ?? 0.0,
      'total_cicilan': (resCicilan.first['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // NEW FUNCTION: CALCULATE REMAINING LOAN PER ID
  Future<double> getSisaPinjamanPerId(int pinjamanId) async {
    Database db = await database;

    // 1. Get Initial Loan Total
    var resPinjaman = await db.query(
      'pinjaman_lunak',
      columns: ['nominal'],
      where: 'id = ?',
      whereArgs: [pinjamanId],
    );

    if (resPinjaman.isEmpty) return 0.0;
    double totalPinjaman = (resPinjaman.first['nominal'] as num).toDouble();

    // 2. Calculate Total Paid
    var resBayar = await db.rawQuery(
        "SELECT SUM(jumlah_bayar) as total FROM pinjaman_lunak_cicilan WHERE pinjaman_id = ?",
        [pinjamanId]);

    double totalSudahBayar =
        (resBayar.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Return Remaining
    return totalPinjaman - totalSudahBayar;
  }

  // 11. LOGIN
  Future<Map<String, dynamic>?> cekLogin(String user, String pass) async {
    Database db = await database;
    List<Map<String, dynamic>> res = await db.query('admin',
        where: 'username = ? AND password = ?', whereArgs: [user, pass]);
    return res.isNotEmpty ? res.first : null;
  }

  // 12. BMT CAPITAL (PERMODALAN) CRUD
  Future<int> insertModal(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('permodalan', row);
  }

  Future<List<Map<String, dynamic>>> getModalHistory() async {
    Database db = await database;
    return await db.query('permodalan', orderBy: 'id DESC');
  }

  Future<int> deleteModal(int id) async {
    Database db = await database;
    return await db.delete('permodalan', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getTotalModal() async {
    Database db = await database;
    var result =
        await db.rawQuery("SELECT SUM(nominal) as total FROM permodalan");
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  // 13. BMT FUND (5%) CRUD
  Future<List<Map<String, dynamic>>> getDanaBMT() async {
    Database db = await database;
    return await db.query('dana_bmt', orderBy: 'id DESC');
  }

  Future<double> getTotalDanaBMT() async {
    Database db = await database;
    var result = await db.rawQuery("SELECT SUM(jumlah) as total FROM dana_bmt");
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // 14. BMT EXPENDITURE CRUD (VERSION 16)

  // Add Expenditure
  Future<int> insertPengeluaran(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('pengeluaran_bmt', row);
  }

  // Get Expenditure by Category
  Future<List<Map<String, dynamic>>> getPengeluaranByKategori(
      String kategori) async {
    Database db = await database;
    return await db.query('pengeluaran_bmt',
        where: 'kategori = ?',
        whereArgs: [kategori],
        orderBy: 'tanggal DESC, id DESC');
  }

  // Recap Expenditure This Month
  Future<Map<String, int>> getRekapPengeluaranBulanIni() async {
    Database db = await database;
    String currentMonth =
        DateTime.now().toIso8601String().substring(0, 7); // Format: 2026-02

    var result = await db.rawQuery('''
      SELECT kategori, SUM(nominal) as total 
      FROM pengeluaran_bmt 
      WHERE date(tanggal) LIKE '$currentMonth%' 
      GROUP BY kategori
    ''');

    int totalRutin = 0;
    int totalTidakRutin = 0;

    for (var row in result) {
      if (row['kategori'] == 'Rutin') {
        totalRutin = (row['total'] as int);
      } else if (row['kategori'] == 'Tidak Rutin') {
        totalTidakRutin = (row['total'] as int);
      }
    }

    return {
      'rutin': totalRutin,
      'tidak_rutin': totalTidakRutin,
      'total': totalRutin + totalTidakRutin
    };
  }

  // Delete Expenditure
  Future<int> deletePengeluaran(int id) async {
    Database db = await database;
    return await db.delete('pengeluaran_bmt', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // SPECIAL FUNCTION FOR CASH FLOW (VERSION 17)
  // ============================================

  Future<Map<String, double>> getCashFlowReport(
      String startDate, String endDate) async {
    Database db = await database;

    // Ensure string date format covers hours for accurate 'BETWEEN' filter
    // Assuming startDate at 00:00:00 and endDate at 23:59:59
    String start = "$startDate 00:00:00";
    String end = "$endDate 23:59:59";

    // 1. Total Capital Collected
    // a. BMT Capital (Investors)
    var resModal = await db.rawQuery(
        "SELECT SUM(nominal) as total FROM permodalan WHERE tanggal BETWEEN ? AND ?",
        [start, end]);
    double totalModalBmt = (resModal.first['total'] as num?)?.toDouble() ?? 0.0;

    // b. Wadiah Savings (Member Deposits)
    // We count incoming (Setoran) as 'Collected'
    var resWadiah = await db.rawQuery(
        "SELECT SUM(jumlah) as total FROM transaksi_wadiah WHERE jenis = 'Setoran' AND tgl_transaksi BETWEEN ? AND ?",
        [start, end]);
    double totalWadiah = (resWadiah.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Total Capital Absorption (Funds Out to Members - Active/Paid Off/Approved Status)
    // a. Buying and Selling (Purchase Price of Goods)
    var resMurabahah = await db.rawQuery(
        "SELECT SUM(harga_beli) as total FROM murabahah_akad WHERE status != 'Pengajuan' AND tgl_akad BETWEEN ? AND ?",
        [start, end]);
    double serapanMurabahah =
        (resMurabahah.first['total'] as num?)?.toDouble() ?? 0.0;

    // b. Mudharabah (Capital Handed Over)
    var resMudharabah = await db.rawQuery(
        "SELECT SUM(nominal_modal) as total FROM mudharabah_akad WHERE status != 'Pengajuan' AND tgl_akad BETWEEN ? AND ?",
        [start, end]);
    double serapanMudharabah =
        (resMudharabah.first['total'] as num?)?.toDouble() ?? 0.0;

    // c. Soft Loan (Loan Amount)
    var resPinjaman = await db.rawQuery(
        "SELECT SUM(nominal) as total FROM pinjaman_lunak WHERE (status = 'Disetujui' OR status = 'Lunas') AND tgl_pengajuan BETWEEN ? AND ?",
        [start, end]); // Assuming tgl_pengajuan is disbursement date
    double serapanPinjaman =
        (resPinjaman.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. BMT Profit
    // a. Buying and Selling Profit (Margin from contracts occurring in this period)
    var resMargin = await db.rawQuery(
        "SELECT SUM(margin) as total FROM murabahah_akad WHERE status != 'Pengajuan' AND tgl_akad BETWEEN ? AND ?",
        [start, end]);
    double keuntunganJualBeli =
        (resMargin.first['total'] as num?)?.toDouble() ?? 0.0;

    // b. Profit Sharing Profit (Realized Profit Sharing Income)
    var resBagiHasil = await db.rawQuery(
        "SELECT SUM(bagian_bmt) as total FROM mudharabah_transaksi WHERE tgl_transaksi BETWEEN ? AND ?",
        [start, end]);
    double keuntunganBagiHasil =
        (resBagiHasil.first['total'] as num?)?.toDouble() ?? 0.0;

    // 4. Business Expenses (Expenditure)
    var resPengeluaran = await db.rawQuery(
        "SELECT SUM(nominal) as total FROM pengeluaran_bmt WHERE tanggal BETWEEN ? AND ?",
        [start, end]);
    double totalBeban =
        (resPengeluaran.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'modal_bmt': totalModalBmt,
      'tabungan_wadiah': totalWadiah,
      'total_modal_terkumpul': totalModalBmt + totalWadiah,
      'serapan_murabahah': serapanMurabahah,
      'serapan_mudharabah': serapanMudharabah,
      'serapan_pinjaman': serapanPinjaman,
      'total_serapan': serapanMurabahah + serapanMudharabah + serapanPinjaman,
      'untung_jualbeli': keuntunganJualBeli,
      'untung_bagihasil': keuntunganBagiHasil,
      'total_keuntungan': keuntunganJualBeli + keuntunganBagiHasil,
      'total_beban': totalBeban,
      'estimasi_laba_bersih':
          (keuntunganJualBeli + keuntunganBagiHasil) - totalBeban
    };
  }
}
