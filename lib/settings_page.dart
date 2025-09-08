import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SettingsPage extends StatefulWidget {
  final List<Map<String, dynamic>> addedSites;
  final Function(Map<String, dynamic>) onSiteAdded;

  const SettingsPage({super.key, required this.addedSites, required this.onSiteAdded});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  Map<String, bool> _siteStatus = {}; // 每個 barcode 的線上狀態
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    // 每 2 秒刷新一次
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refreshStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 刷新所有案場的線上狀態
  Future<void> _refreshStatus() async {
    for (var site in widget.addedSites) {
      final barcode = site['barcode'];
      try {
        final resp = await http.get(Uri.parse("http://10.13.13.84:5000/status/$barcode"));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          setState(() {
            _siteStatus[barcode] = data['online'] ?? false;
          });
        } else {
          setState(() {
            _siteStatus[barcode] = false;
          });
        }
      } catch (e) {
        setState(() {
          _siteStatus[barcode] = false;
        });
      }
    }
  }

  // 新增案場
  void _addSite() async {
    String siteName = _siteNameController.text.trim();
    String barcode = _barcodeController.text.trim();
    if (siteName.isEmpty || barcode.isEmpty) return;

    // 檢查 barcode 是否存在 server
    try {
      final response =
          await http.get(Uri.parse("http://10.13.13.84:5000/check/$barcode"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exists'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("此 Barcode 在伺服器不存在！")),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("伺服器檢查失敗")),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("連線錯誤: $e")),
      );
      return;
    }

    // 取得上線狀態
    bool online = false;
    try {
      final statusResp =
          await http.get(Uri.parse("http://10.13.13.84:5000/status/$barcode"));
      if (statusResp.statusCode == 200) {
        final statusData = jsonDecode(statusResp.body);
        online = statusData['online'] ?? false;
      }
    } catch (e) {
      online = false;
    }

    final site = {"barcode": barcode, "name": siteName, "online": online};

    // 通知外層 DataPage
    widget.onSiteAdded(site);
    setState(() {});
    _siteNameController.clear();
    _barcodeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 上卡片：新增案場
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("新增案場",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20, thickness: 1),
                    const Text("案場名稱"),
                    const SizedBox(height: 5),
                    Container(
                      height: 50,
                      child: TextField(
                        controller: _siteNameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: "輸入案場名稱",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Barcode"),
                    const SizedBox(height: 5),
                    Container(
                      height: 50,
                      child: TextField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: "輸入Barcode",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _addSite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 26, 0, 176),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("新增"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 下卡片：已接入案場
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("已接入案場",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20, thickness: 1),
                    if (widget.addedSites.isEmpty)
                      const Center(
                          child: Text("尚未新增案場",
                              style: TextStyle(color: Colors.grey)))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.addedSites.map((site) {
                          final online = _siteStatus[site['barcode']] ?? site['online'];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${site['barcode']}: ${site['name']}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(online ? "上線" : "離線",
                                      style: TextStyle(
                                          color: online
                                              ? Colors.green
                                              : Colors.red)),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: online
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              const Divider(
                                  thickness: 1, color: Colors.grey),
                            ],
                          );
                        }).toList(),
                      ),
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
