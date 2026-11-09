import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _day = today();
  String _cat = 'Semua';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final locked = !app.hasActiveMembership;
    final frozen = app.isFrozen;
    final all = app.classesOn(_day);
    final list = all
        .where((c) => _cat == 'Semua' || c.category == _cat)
        .toList();

    return Column(
      children: [
        const PageHeader('Booking Kelas', showBack: false),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (locked) _LockedCard(onTap: () => context.go('/packages')),
              if (frozen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    color: const Color(0xFFEAF5FB),
                    child: Row(children: [
                      const Icon(Icons.ac_unit, color: Color(0xFF1E5870)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              'Booking dijeda selama membership dibekukan.',
                              style: AppText.body(12.5,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF1E5870)))),
                    ]),
                  ),
                ),
              if (!locked) ...[
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final d = today().add(Duration(days: i));
                      final sel = dateOnly(d) == dateOnly(_day);
                      return GestureDetector(
                        onTap: () => setState(() => _day = d),
                        child: Container(
                          width: 56,
                          decoration: BoxDecoration(
                            color: sel ? AppColors.teal : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(fmtDate(d, 'E'),
                                  style: AppText.body(11,
                                      weight: FontWeight.w600,
                                      color: sel ? Colors.white : Colors.black54)),
                              Text('${d.day}',
                                  style: AppText.heading(18,
                                      color: sel ? Colors.white : AppColors.ink)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final c in ['Semua', 'Yoga', 'HIIT', 'Zumba'])
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: PillChip(c,
                            selected: _cat == c,
                            onTap: () => setState(() => _cat = c)),
                      ),
                  ]),
                ),
                const SizedBox(height: 14),
              ] else ...[
                const SizedBox(height: 6),
                Text('Jadwal hari ini', style: AppText.heading(18)),
                const SizedBox(height: 10),
              ],
              for (final c in (locked ? app.classesOn(today()) : list))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ClassTile(c: c, app: app, locked: locked, frozen: frozen),
                ),
              if (!locked && list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                      child: Text('Tidak ada kelas untuk filter ini',
                          style: AppText.body(13, color: AppColors.muted))),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.lock_outline, color: AppColors.tealDark),
            ),
            const SizedBox(height: 14),
            Text('Booking kelas khusus member', style: AppText.heading(18)),
            const SizedBox(height: 6),
            Text(
                'Kamu belum punya membership aktif. Pilih paket untuk mulai booking Yoga, HIIT, dan Zumba.',
                style: AppText.body(12.5, color: AppColors.muted)),
            const SizedBox(height: 16),
            PrimaryButton('Pilih paket membership', onPressed: onTap),
          ],
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile(
      {required this.c, required this.app, required this.locked, required this.frozen});
  final GymClass c;
  final AppState app;
  final bool locked;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    final booked = app.isBooked(c);
    final slots = app.slotsLeft(c);
    final full = slots <= 0 && !booked;
    final past = c.start.isBefore(DateTime.now());

    Widget action;
    if (locked) {
      action = _pill('Terkunci', Colors.black12, Colors.black45,
          icon: Icons.lock_outline);
    } else if (booked) {
      action = _pill('Terbooking', AppColors.tealSoft, AppColors.tealDark,
          onTap: () => _cancel(context));
    } else if (full) {
      action = _pill('Penuh', Colors.black12, Colors.black45);
    } else if (past || frozen) {
      action = _pill(past ? 'Selesai' : 'Dijeda', Colors.black12, Colors.black45);
    } else {
      action = _pill('Booking', AppColors.ink, Colors.white,
          onTap: () {
        final err = app.book(c);
        toast(context, err ?? 'Berhasil booking ${c.title}');
      });
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(children: [
              Text(fmtTime(c.start),
                  style: AppText.body(14, weight: FontWeight.w800)),
              Text('Wib', style: AppText.body(11, color: AppColors.muted)),
            ]),
          ),
          Container(
              width: 1,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.black12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: AppText.body(15, weight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('${c.studio} ${c.coach}',
                    style: AppText.body(11.5, color: AppColors.muted)),
                const SizedBox(height: 3),
                Text(full ? 'Slot habis' : '$slots slot tersisa',
                    style: AppText.body(11.5,
                        weight: FontWeight.w600,
                        color: full ? AppColors.danger : AppColors.tealDark)),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }

  Widget _pill(String t, Color bg, Color fg, {VoidCallback? onTap, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(t, style: AppText.body(12, weight: FontWeight.w700, color: fg)),
        ]),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await confirmSheet(context,
        title: 'Batalkan booking?',
        message: '${c.title} • ${fmtTime(c.start)} WIB',
        confirmLabel: 'Ya, batalkan',
        cancelLabel: 'Tidak',
        danger: true);
    if (!ok || !context.mounted) return;
    final err = app.cancelBooking(c);
    toast(context, err ?? 'Booking dibatalkan');
  }
}
