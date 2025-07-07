import 'package:flutter/material.dart';
import 'home_page.dart';
import 'diagram_page.dart';
import 'history_page.dart';

class BottomNavigasiPage extends StatefulWidget {
  const BottomNavigasiPage({super.key});

  @override
  State<BottomNavigasiPage> createState() => _BottomNavigasiPageState();
}

class _BottomNavigasiPageState extends State<BottomNavigasiPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    const DiagramPage(),
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
      body: IndexedStack(
        // Use IndexedStack to keep the state of each page
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Diagram',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
