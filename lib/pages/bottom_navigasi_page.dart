import 'package:bilionare_budget_app/pages/categori_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'diagram_page.dart';
import 'history_page.dart';
import 'neraca_page.dart'; // <-- IMPORT HALAMAN BARU

class BottomNavigasiPage extends StatefulWidget {
  const BottomNavigasiPage({super.key});

  @override
  State<BottomNavigasiPage> createState() => _BottomNavigasiPageState();
}

class _BottomNavigasiPageState extends State<BottomNavigasiPage> {
  int _selectedIndex = 0;

  // --- TAMBAHKAN HALAMAN NERACA KE DALAM LIST ---
  final List<Widget> _pages = [
    HomePage(),
    const DiagramPage(),
    const NeracaPage(), // <-- HALAMAN BARU
    CategoryPage(),
    const HistoryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Penting agar semua item terlihat
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Diagram',
          ),
          // --- TAMBAHKAN ITEM NAVIGASI BARU ---
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet), // Icon untuk neraca
            label: 'Neraca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey.shade600,
      ),
    );
  }
}
