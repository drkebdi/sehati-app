import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/db_service.dart';

// ══════════════════════════════════════════
// GLUCOSE SCREEN
// ══════════════════════════════════════════
class GlucoseScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  const GlucoseScreen({super.key, required this.onDataChanged});
  @override
  State<GlucoseScreen> createState() => _GlucoseScreenState();
}

class _GlucoseScreenState extends State<GlucoseScreen> {
  List<GlucoseReading> _readings = [];
  final _valCtrl = TextEditingController();
  String _when = 'صائم';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await DBService.getGlucose();
    if (mounted) setState(() => _readings = r);
  }

  Future<void> _add() async {
    final val = double.tryParse(_valCtrl.text);
    if (val == null || val < 0.1 || val > 30) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('أدخل قيمة صحيحة (0.1 — 30 g/L)',
              style: GoogleFonts.cairo())));
      return;
    }
    final now = DateTime.now();
    await DBService.addGlucose(GlucoseReading(
      val: val, whenTaken: _when,
      date: '${now.day}/${now.month}/${now.year}',
      time: '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
      createdAt: now.millisecondsSinceEpoch,
    ));
    _valCtrl.clear();
    await _load();
    widget.onDataChanged();
    if (mounted) Navigator.pop(context);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('🩸 تسجيل قراءة السكر',
                style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            TextField(
              controller: _valCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'القيمة (g/L)',
                hintText: 'مثال: 1.10',
                labelStyle: GoogleFonts.cairo(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixText: 'g/L',
              ),
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _when,
              items: ['صائم','بعد الأكل','قبل النوم','عشوائي']
                  .map((w) => DropdownMenuItem(
                      value: w,
                      child: Text(w, style: GoogleFonts.cairo(fontSize: 16))))
                  .toList(),
              onChanged: (v) => setState(() => _when = v!),
              decoration: InputDecoration(
                labelText: 'وقت القياس',
                labelStyle: GoogleFonts.cairo(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _add,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFb71c1c),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text('💾 حفظ', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFb71c1c),
          title: Text('🩸 جدول السكري',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(icon: const Icon(Icons.add), onPressed: _showAddSheet),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddSheet,
          backgroundColor: const Color(0xFFb71c1c),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('إضافة قراءة',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        body: _readings.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🩸', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text('لا قراءات بعد',
                      style: GoogleFonts.tajawal(fontSize: 20, color: Colors.grey)),
                ]))
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _readings.length,
                itemBuilder: (ctx, i) {
                  final r = _readings[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Color(r.statusColor).withOpacity(0.3))),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(r.statusColor).withOpacity(0.15),
                        child: Text('🩸', style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text('${r.val} g/L',
                          style: GoogleFonts.cairo(
                              fontSize: 20, fontWeight: FontWeight.w900,
                              color: Color(r.statusColor))),
                      subtitle: Text('${r.whenTaken} — ${r.date} ${r.time}',
                          style: GoogleFonts.cairo(fontSize: 12)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Color(r.statusColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r.status,
                              style: GoogleFonts.cairo(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Color(r.statusColor))),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () async {
                            await DBService.deleteGlucose(r.id!);
                            await _load();
                            widget.onDataChanged();
                          },
                        ),
                      ]),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// BP SCREEN
// ══════════════════════════════════════════
class BPScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  const BPScreen({super.key, required this.onDataChanged});
  @override
  State<BPScreen> createState() => _BPScreenState();
}

class _BPScreenState extends State<BPScreen> {
  List<BPReading> _readings = [];
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  String _position = 'جالس';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await DBService.getBP();
    if (mounted) setState(() => _readings = r);
  }

  Future<void> _add() async {
    final sys = double.tryParse(_sysCtrl.text);
    final dia = double.tryParse(_diaCtrl.text);
    if (sys == null || dia == null || sys < 4 || dia < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('أدخل قيم صحيحة (cmHg)', style: GoogleFonts.cairo())));
      return;
    }
    final now = DateTime.now();
    await DBService.addBP(BPReading(
      sys: sys, dia: dia,
      pulse: int.tryParse(_pulseCtrl.text),
      position: _position,
      date: '${now.day}/${now.month}/${now.year}',
      time: '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
      createdAt: now.millisecondsSinceEpoch,
    ));
    _sysCtrl.clear(); _diaCtrl.clear(); _pulseCtrl.clear();
    await _load();
    widget.onDataChanged();
    if (mounted) Navigator.pop(context);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('💉 تسجيل قراءة الضغط',
                style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(
                controller: _sysCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'الانقباضي', hintText: '12.0',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: 'cmHg',
                ),
                style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900),
              )),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _diaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'الانبساطي', hintText: '8.0',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: 'cmHg',
                ),
                style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900),
              )),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(
                controller: _pulseCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'النبض (اختياري)',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: 'bpm',
                ),
                style: GoogleFonts.cairo(fontSize: 18),
              )),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(
                value: _position,
                items: ['جالس','واقف','مستلقٍ']
                    .map((p) => DropdownMenuItem(value: p,
                        child: Text(p, style: GoogleFonts.cairo(fontSize: 14))))
                    .toList(),
                onChanged: (v) => setState(() => _position = v!),
                decoration: InputDecoration(
                  labelText: 'الوضعية',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _add,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a237e),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text('💾 حفظ', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a237e),
          title: Text('💉 جدول الضغط',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(icon: const Icon(Icons.add), onPressed: _showAddSheet),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddSheet,
          backgroundColor: const Color(0xFF1a237e),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('إضافة قراءة',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        body: _readings.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('💉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text('لا قراءات بعد',
                    style: GoogleFonts.tajawal(fontSize: 20, color: Colors.grey)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _readings.length,
                itemBuilder: (ctx, i) {
                  final r = _readings[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Color(r.statusColor).withOpacity(0.3))),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(r.statusColor).withOpacity(0.15),
                        child: const Text('💉', style: TextStyle(fontSize: 20)),
                      ),
                      title: Text('${r.sys}/${r.dia} cmHg',
                          style: GoogleFonts.cairo(
                              fontSize: 18, fontWeight: FontWeight.w900,
                              color: Color(r.statusColor))),
                      subtitle: Text('${r.position} — ${r.date} ${r.time}${r.pulse != null ? ' — ${r.pulse} bpm' : ''}',
                          style: GoogleFonts.cairo(fontSize: 12)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Color(r.statusColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r.status,
                              style: GoogleFonts.cairo(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Color(r.statusColor))),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () async {
                            await DBService.deleteBP(r.id!);
                            await _load();
                            widget.onDataChanged();
                          },
                        ),
                      ]),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// PROFILE SCREEN
// ══════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const ProfileScreen({super.key, required this.onSaved});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _diseasesCtrl = TextEditingController();
  final _medsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _nameCtrl.text = await DBService.getProfile('name') ?? '';
    _phoneCtrl.text = await DBService.getProfile('phone') ?? '';
    _dobCtrl.text = await DBService.getProfile('dob') ?? '';
    _diseasesCtrl.text = await DBService.getProfile('diseases') ?? '';
    _medsCtrl.text = await DBService.getProfile('meds') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await DBService.setProfile('name', _nameCtrl.text);
    await DBService.setProfile('phone', _phoneCtrl.text);
    await DBService.setProfile('dob', _dobCtrl.text);
    await DBService.setProfile('diseases', _diseasesCtrl.text);
    await DBService.setProfile('meds', _medsCtrl.text);
    widget.onSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ تم حفظ الملف الشخصي', style: GoogleFonts.cairo()),
        backgroundColor: Colors.green[700],
      ));
    }
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboard, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        style: GoogleFonts.cairo(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('👤 ملفي الشخصي',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w900)),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text('حفظ', style: GoogleFonts.cairo(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('الاسم الكامل', _nameCtrl),
              _field('رقم الهاتف', _phoneCtrl, keyboard: TextInputType.phone),
              _field('تاريخ الميلاد (مثال: 15/06/1970)', _dobCtrl),
              _field('أمراض مزمنة', _diseasesCtrl, maxLines: 2),
              _field('أدوية دائمة', _medsCtrl, maxLines: 3),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0f4c75),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('💾 حفظ الملف',
                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
