import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await DBService.getReminders();
    if (mounted) setState(() => _reminders = r);
  }

  Future<void> _toggle(Reminder r, bool val) async {
    final updated = r.copyWith(enabled: val);
    await DBService.updateReminder(updated);
    await NotificationService.scheduleReminder(updated);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(val ? '🔔 تم تفعيل التنبيه — ${r.time}' : '🔕 تم إيقاف التنبيه',
            style: GoogleFonts.cairo()),
        backgroundColor: val ? Colors.green[700] : Colors.grey[700],
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _editTime(Reminder r) async {
    final parts = r.time.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (ctx, child) => Directionality(
          textDirection: TextDirection.rtl, child: child!),
    );
    if (picked == null) return;
    final newTime =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final updated = r.copyWith(time: newTime);
    await DBService.updateReminder(updated);
    if (updated.enabled) await NotificationService.scheduleReminder(updated);
    await _load();
  }

  Future<void> _addReminder(String type) async {
    final notifId = DateTime.now().millisecondsSinceEpoch % 100000;
    final r = Reminder(
      type: type,
      label: type == 'glucose' ? 'موعد جديد — سكر' : 'موعد جديد — ضغط',
      time: '09:00',
      whenTaken: type == 'glucose' ? 'عشوائي' : null,
      enabled: true,
      notifId: notifId,
    );
    await DBService.addReminder(r);
    await NotificationService.scheduleReminder(r);
    await _load();
  }

  Future<void> _delete(Reminder r) async {
    await NotificationService.cancelReminder(r.notifId);
    await DBService.deleteReminder(r.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final glucoseRems = _reminders.where((r) => r.type == 'glucose').toList();
    final bpRems = _reminders.where((r) => r.type == 'bp').toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('🔔 التنبيهات', style: GoogleFonts.tajawal(fontWeight: FontWeight.w900)),
          actions: [
            TextButton.icon(
              onPressed: () => NotificationService.testNow('glucose'),
              icon: const Icon(Icons.notifications_active, color: Colors.white),
              label: Text('اختبار', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'المنبه يشتغل بصوت هاتفك الحقيقي حتى لو الشاشة مغلقة أو التطبيق مغلق',
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.green[800],
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            // Glucose reminders
            _sectionHeader('🩸 تنبيهات السكر', const Color(0xFFb71c1c),
                () => _addReminder('glucose')),
            ...glucoseRems.map((r) => _reminderCard(r, const Color(0xFFb71c1c))),

            const SizedBox(height: 16),

            // BP reminders
            _sectionHeader('💉 تنبيهات الضغط', const Color(0xFF1a237e),
                () => _addReminder('bp')),
            ...bpRems.map((r) => _reminderCard(r, const Color(0xFF1a237e))),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.tajawal(
                  fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const Spacer(),
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add, color: color, size: 18),
            label: Text('إضافة', style: GoogleFonts.cairo(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(Reminder r, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: r.enabled ? color.withOpacity(0.4) : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Time button
            GestureDetector(
              onTap: () => _editTime(r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: r.enabled ? color.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: r.enabled ? color.withOpacity(0.3) : Colors.grey.shade300),
                ),
                child: Text(r.time,
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: r.enabled ? color : Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.label,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: r.enabled ? Colors.black87 : Colors.grey)),
                  if (r.whenTaken != null)
                    Text(r.whenTaken!,
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            // Toggle
            Switch(
              value: r.enabled,
              activeColor: color,
              onChanged: (val) => _toggle(r, val),
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _delete(r),
            ),
          ],
        ),
      ),
    );
  }
}
