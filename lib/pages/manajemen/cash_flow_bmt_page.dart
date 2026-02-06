import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/db_helper.dart';

class CashFlowBmtPage extends StatefulWidget {
  const CashFlowBmtPage({super.key});

  @override
  State<CashFlowBmtPage> createState() => _CashFlowBmtPageState();
}

class _CashFlowBmtPageState extends State<CashFlowBmtPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // Filter State
  String _selectedFilter = 'Bulan Ini'; // Default
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // Data State
  Map<String, double> _data = {
    'modal_bmt': 0,
    'tabungan_wadiah': 0,
    'total_modal_terkumpul': 0,
    'serapan_murabahah': 0,
    'serapan_mudharabah': 0,
    'serapan_pinjaman': 0,
    'total_serapan': 0,
    'untung_jualbeli': 0,
    'untung_bagihasil': 0,
    'total_keuntungan': 0,
    'total_beban': 0,
    'estimasi_laba_bersih': 0,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setFilter('Bulan Ini'); // Load default data
  }

  // --- LOGIKA FILTER TANGGAL ---
  void _setFilter(String filter) async {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    if (filter == 'Hari Ini') {
      start = now;
      end = now;
    } else if (filter == 'Kemarin') {
      start = now.subtract(const Duration(days: 1));
      end = now.subtract(const Duration(days: 1));
    } else if (filter == 'Bulan Ini') {
      start = DateTime(now.year, now.month, 1);
      end = now;
    } else {
      // Custom range dihandle terpisah
      start = _startDate;
      end = _endDate;
    }

    setState(() {
      _selectedFilter = filter;
      _startDate = start;
      _endDate = end;
      _isLoading = true;
    });

    // Format tanggal ke string yyyy-MM-dd
    String startStr = DateFormat('yyyy-MM-dd').format(start);
    String endStr = DateFormat('yyyy-MM-dd').format(end);

    final result = await _dbHelper.getCashFlowReport(startStr, endStr);

    if (mounted) {
      setState(() {
        _data = result;
        _isLoading = false;
      });
    }
  }

  // Pilih Rentang Tanggal Manual
  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 'Rentang Waktu';
      });
      _setFilter('Rentang Waktu'); // Refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Arus Keuangan BMT"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- 1. FILTER WIDGET ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('Hari Ini'),
                      const SizedBox(width: 8),
                      _buildFilterButton('Kemarin'),
                      const SizedBox(width: 8),
                      _buildFilterButton('Bulan Ini'),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: Text(_selectedFilter == 'Rentang Waktu'
                            ? "${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}"
                            : "Pilih Tanggal"),
                        avatar: const Icon(Icons.calendar_today,
                            size: 16, color: Colors.white),
                        backgroundColor: _selectedFilter == 'Rentang Waktu'
                            ? const Color(0xFF2E7D32)
                            : Colors.grey,
                        labelStyle: const TextStyle(color: Colors.white),
                        onPressed: _pickDateRange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} s/d ${DateFormat('dd MMM yyyy').format(_endDate)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                )
              ],
            ),
          ),

          // --- 2. KONTEN DASHBOARD ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // CARD 1: TOTAL MODAL TERKUMPUL
                      _buildCard(
                          title: "1. Total Modal Terkumpul",
                          icon: Icons.savings,
                          color: Colors.blue,
                          total: _data['total_modal_terkumpul']!,
                          children: [
                            _buildRowItem(
                                "Permodalan BMT", _data['modal_bmt']!),
                            _buildRowItem(
                                "Tabungan Nasabah", _data['tabungan_wadiah']!),
                          ]),

                      const SizedBox(height: 16),

                      // CARD 2: TOTAL SERAPAN MODAL
                      _buildCard(
                          title: "2. Total Serapan Modal (Disalurkan)",
                          icon: Icons.outbound,
                          color: Colors.orange[800]!,
                          total: _data['total_serapan']!,
                          children: [
                            _buildRowItem("Jual Beli (Murabahah)",
                                _data['serapan_murabahah']!),
                            _buildRowItem("Bagi Hasil (Mudharabah)",
                                _data['serapan_mudharabah']!),
                            _buildRowItem(
                                "Pinjaman Lunak", _data['serapan_pinjaman']!),
                          ]),

                      const SizedBox(height: 16),

                      // CARD 3: PROFITABILITAS
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.pie_chart, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text("3. Profitabilitas & Beban",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ],
                              ),
                              const Divider(height: 20),

                              // Keuntungan
                              const Text("Pemasukan (Keuntungan)",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              _buildRowItem("Keuntungan Jual Beli",
                                  _data['untung_jualbeli']!),
                              _buildRowItem("Keuntungan Bagi Hasil",
                                  _data['untung_bagihasil']!),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Total Keuntungan",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        _formatter
                                            .format(_data['total_keuntungan']),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green)),
                                  ],
                                ),
                              ),

                              const Divider(),

                              // Beban
                              _buildRowItem(
                                  "4. Total Beban Usaha", _data['total_beban']!,
                                  isMinus: true),

                              const Divider(thickness: 2),

                              // NET PROFIT
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("5. Estimasi Keuntungan Bersih",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  Text(
                                      _formatter.format(
                                          _data['estimasi_laba_bersih']),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color:
                                              (_data['estimasi_laba_bersih']! >=
                                                      0)
                                                  ? const Color(0xFF2E7D32)
                                                  : Colors.red)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildFilterButton(String text) {
    bool isSelected = _selectedFilter == text;
    return ChoiceChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) _setFilter(text);
      },
      selectedColor: const Color(0xFF2E7D32),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required double total,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          title: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(_formatter.format(total),
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: children),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(String label, double value, {bool isMinus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(
            "${isMinus ? '(-)' : ''} ${_formatter.format(value)}",
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isMinus ? Colors.red : Colors.black87),
          ),
        ],
      ),
    );
  }
}
