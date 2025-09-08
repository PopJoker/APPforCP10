import 'package:flutter/material.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'history_page.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  int _currentIndex = 0;

  // 對應 BottomNavigationBar 的頁面
  late final List<Widget> _pages;

  // 已接入案場資料，由 DataPage 管理
  final List<Map<String, dynamic>> _addedSites = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(addedSites: _addedSites), // HomePage 讀 _addedSites
      SettingsPage(
        addedSites: _addedSites,         // 傳給 SettingsPage
        onSiteAdded: (site) {            // 新增案場時回傳 DataPage
          setState(() {
            _addedSites.add(site);
          });
        },
      ),
      const HistoryPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "儲能系統",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "總欄",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "設定",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "歷史",
          ),
        ],
      ),
    );
  }
}
