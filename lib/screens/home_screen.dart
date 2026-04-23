import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glucose_screen.dart';
import 'bp_screen.dart';
import 'reminders_screen.dart';
import 'profile_screen.dart';
import '../services/db_service.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  GlucoseReading? _lastGlucose;
  BPReading? _lastBP;
  String _patientName = 'المريض';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final glucose = await DBService.getGlucose();
    final bp = await DBService.getBP();
    final name = await DBService.getProfile('name');
    if (mounted) {
      setState(() {
        _lastGlucose = glucose.isNotEmpty ? glucose.first : null;
        _lastBP = bp.isNotEmpty ? bp.first : null;
        _patientName = name ?? 'المريض';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: [
            _buildHome(),
            GlucoseScreen(onDataChanged: _loadData),
            BPScreen(onDataChanged: _loadData),
            RemindersScreen(),
            ProfileScreen(onSaved: _loadData),
          ],
        ),
        bottomNavigationBar: _buildTabBar(),
      ),
    );
  }

  Widget _buildHome() {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: const Color(0xFF0f4c75),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0f4c75), Color(0xFF1b6ca8), Color(0xFF00897b)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('مرحباً 👋',
                                    style: GoogleFonts.cairo(
                                        color: Colors.white70, fontSize: 14)),
                                Text(_patientName,
                                    style: GoogleFonts.tajawal(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _tab = 4),
                            icon: const Icon(Icons.person_outline,
                                color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Quick stats
                      Row(
                        children: [
                          _statCard('🩸 آخر سكر',
                              _lastGlucose != null
                                  ? '${_lastGlucose!.val} g/L'
                                  : '—',
                              _lastGlucose != null
                                  ? Color(_lastGlucose!.statusColor)
                                  : Colors.white54),
                          const SizedBox(width: 10),
                          _statCard('💉 آخر ضغط',
                              _lastBP != null
                                  ? '${_lastBP!.sys}/${_lastBP!.dia}'
                                  : '—',
                              _lastBP != null
                                  ? Color(_lastBP!.statusColor)
                                  : Colors.white54),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          title: const Text('صحتي',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Quick action buttons
              Row(
                children: [
                  _actionBtn('🩸', 'قياس السكر', const Color(0xFFb71c1c),
                      () => setState(() => _tab = 1)),
                  const SizedBox(width: 12),
                  _actionBtn('💉', 'قياس الضغط', const Color(0xFF1a237e),
                      () => setState(() => _tab = 2)),
                ],
              ),
              const SizedBox(height: 12),
              // Reminders card
              _remindersCard(),
              const SizedBox(height: 12),
              // Clinic info
              _clinicCard(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.cairo(
                    color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.cairo(
                    color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String emoji, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _remindersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('🔔',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('التنبيهات',
                    style: GoogleFonts.tajawal(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _tab = 3),
                  child: Text('إدارة التنبيهات',
                      style: GoogleFonts.cairo(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('المنبه يشتغل بصوت هاتفك حتى لو الشاشة مغلقة ✅',
                style: GoogleFonts.cairo(
                    fontSize: 13, color: Colors.green[700],
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _clinicCard() {
    return Card(
      elevation: 1,
      color: const Color(0xFF0f4c75).withOpacity(0.05),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: const Color(0xFF0f4c75).withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('🏥', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('د. كبدي إبراهيم — طبيب عام',
                      style: GoogleFonts.tajawal(
                          fontSize: 15, fontWeight: FontWeight.w900,
                          color: const Color(0xFF0f4c75))),
                  Text('📍 برج بونعامة — تيسمسيلت',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final items = [
      (Icons.home_rounded, 'الرئيسية'),
      (Icons.water_drop_rounded, 'السكر'),
      (Icons.monitor_heart_rounded, 'الضغط'),
      (Icons.alarm_rounded, 'التنبيهات'),
      (Icons.person_rounded, 'ملفي'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = _tab == i;
            final color = selected ? const Color(0xFF0f4c75) : Colors.grey;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, color: color, size: selected ? 26 : 22),
                      const SizedBox(height: 2),
                      Text(items[i].$2,
                          style: GoogleFonts.cairo(
                              color: color,
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
