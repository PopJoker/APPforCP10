import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class HistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> addedSites;

  const HistoryPage({super.key, required this.addedSites});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final String baseUrl = "http://10.255.85.198:5000"; // 改成你的 Flask IP
  List<Map<String, dynamic>> historyData = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHistoryData();
  }

  Future<void> fetchHistoryData() async {
    List<Map<String, dynamic>> results = [];

    for (var site in widget.addedSites) {
      final code = site["barcode"];
      try {
        // 先查在線狀態
        final statusRes = await http.get(Uri.parse("$baseUrl/status/$code"));
        if (statusRes.statusCode == 200) {
          final statusJson = jsonDecode(statusRes.body);
          if (statusJson["online"] == true) {
            // 在線的才抓歷史
            final historyRes = await http.get(Uri.parse("$baseUrl/history/$code"));
            if (historyRes.statusCode == 200) {
              final historyJson = jsonDecode(historyRes.body);
              results.add({
                "barcode": code,
                "history": historyJson["history"],
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching $code: $e");
      }
    }

    setState(() {
      historyData = results;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (historyData.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        body: const Center(
          child: Text(
            "目前沒有在線的裝置",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: ListView.builder(
        itemCount: historyData.length,
        itemBuilder: (context, index) {
          final item = historyData[index];
          final barcode = item["barcode"];
          final history = item["history"] as List;

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("裝置: $barcode",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10, // 可依需求調整或動態計算
                        minY: 0,  // 從 0 開始
                        barGroups: _buildBarGroups(history),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < history.length) {
                                  final date = history[value.toInt()]["date"];
                                  return Text(date.substring(5), // 只顯示 MM-DD
                                      style: const TextStyle(fontSize: 10));
                                }
                                return const Text("");
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List history) {
    return List.generate(history.length, (index) {
      final priceDiff = history[index]["price_diff"].toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: priceDiff,
            color: priceDiff >= 0 ? Colors.green : Colors.red,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}
