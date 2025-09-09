import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> addedSites;

  const HomePage({super.key, required this.addedSites});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> _siteData = {}; // { barcode: 資料或 null }
  Map<String, bool> _loadingMap = {};  // { barcode: 是否 loading }
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchAllSiteData();

    // 每 2 秒自動刷新
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchAllSiteData();
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.addedSites.length != widget.addedSites.length) {
      _fetchAllSiteData();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllSiteData() async {
    if (widget.addedSites.isEmpty) return;

    Map<String, dynamic> newData = {};
    Map<String, bool> newLoading = {};

    for (var site in widget.addedSites) {
      final barcode = site['barcode'];
      newLoading[barcode] = true;

      try {
        final response = await http.get(
          Uri.parse("http://10.255.85.198:5000/data/$barcode"),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          newData[barcode] = data[barcode];
        } else {
          newData[barcode] = null;
        }
      } catch (_) {
        newData[barcode] = null;
      } finally {
        newLoading[barcode] = false;
      }
    }

    setState(() {
      _siteData = newData;
      _loadingMap = newLoading;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onlineSites = widget.addedSites
        .where((site) => _siteData[site['barcode']] != null)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[300], // 背景淺灰
      body: onlineSites.isEmpty
          ? const Center(
              child: Text(
                "尚無在線案場",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchAllSiteData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: onlineSites.map((site) {
                    final barcode = site['barcode'];
                    final name = site['name'];
                    final data = _siteData[barcode];
                    final loading = _loadingMap[barcode] ?? false;
                    final status = data?['status'] ?? "-";

                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: loading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 標題區：案場名稱 + 狀態
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: status == "CHG"
                                              ? Colors.lightBlue[100]
                                              : (status == "DISCHG"
                                                  ? Colors.orange[100]
                                                  : Colors.grey[300]),
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: status == "CHG"
                                                ? Colors.blue[800]
                                                : (status == "DISCHG"
                                                    ? Colors.orange[800]
                                                    : Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "上線",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Table(
                                    columnWidths: const {
                                      0: IntrinsicColumnWidth(),
                                      1: FlexColumnWidth(),
                                      2: IntrinsicColumnWidth(),
                                      3: FlexColumnWidth(),
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          const Text("電壓:", style: TextStyle(fontSize: 14)),
                                          Text("${data['voltage'] ?? '-'} V"),
                                          const Text("電流:", style: TextStyle(fontSize: 14)),
                                          Text("${data['current'] ?? '-'} A"),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          const Text("溫度:", style: TextStyle(fontSize: 14)),
                                          Text("${data['temp'] ?? '-'} ℃"),
                                          const SizedBox(),
                                          const SizedBox(),
                                        ],
                                      ),
                                      const TableRow(
                                        children: [
                                          SizedBox(height: 6),
                                          SizedBox(),
                                          SizedBox(),
                                          SizedBox(),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          const Text("日充:", style: TextStyle(fontSize: 14)),
                                          Text("${data['chgday'] ?? '-'}",
                                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                          const Text("日放:", style: TextStyle(fontSize: 14)),
                                          Text("${data['dsgday'] ?? '-'}",
                                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          const Text("月充:", style: TextStyle(fontSize: 14)),
                                          Text("${data['chgmounth'] ?? '-'}",
                                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                          const Text("月放:", style: TextStyle(fontSize: 14)),
                                          Text("${data['dsgmounth'] ?? '-'}",
                                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
