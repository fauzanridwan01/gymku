import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'selamat pagi';
  if (h < 15) return 'selamat siang';
  if (h < 18) return 'selamat sore';
  return 'selamat malam';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.currentUser!;
    final m = app.membership;
    final active = app.hasActiveMembership;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.navy,
              child: Text(user.initials,
                  style: AppText.heading(16, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(),
                      style: AppText.body(12,
                          weight: FontWeight.w600, color: Colors.black54)),
                  Text(user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading(22)),
                ],
              ),
            ),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go('/info'),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_none, size: 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        MemberCard(user: user, membership: m),
        if (m != null && m.isFrozen) ...[
          const SizedBox(height: 14),
          _FrozenBanner(onActivate: () => context.push('/freeze/status')),
        ],
        const SizedBox(height: 20),
        _QuickActions(app: app),
        const SizedBox(height: 22),
        Text('Streak Mingguan', style: AppText.heading(18)),
        const SizedBox(height: 10),
        _StreakCard(app: app, active: active),
        const SizedBox(height: 22),
        Text('Kelas Hari Ini', style: AppText.heading(18)),
        const SizedBox(height: 10),
        _TodayClasses(app: app),
      ],
    );
  }
}

class MemberCard extends StatelessWidget {
  const MemberCard({super.key, required this.user, required this.membership});
  final AppUser user;
  final Membership? membership;

  @override
  Widget build(BuildContext context) {
    final m = membership;
    final hasPlan = m != null && m.isActive;
    final frozen = m?.isFrozen ?? false;
    // aman dipakai di cabang hasPlan (m dijamin tidak null di sana)
    final mm = m ?? Membership(planName: '', start: today(), end: today(), totalDays: 0);

    final colors = frozen
        ? const [Color(0xFF5E7A8A), Color(0xFF3F5663)]
        : hasPlan
            ? const [Color(0xFF16A394), Color(0xFF0E7F74)]
            : const [Color(0xFF42505A), Color(0xFF2B353D)];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusChip(hasPlan ? 'PREMIUM' : 'BELUM AKTIF',
                  bg: hasPlan ? AppColors.lime : Colors.white24,
                  fg: hasPlan ? AppColors.ink : Colors.white),
              if (frozen)
                const StatusChip('Dibekukan',
                    bg: Color(0xFFBFE3F5), fg: Color(0xFF1E5870)),
            ],
          ),
          const SizedBox(height: 14),
          Text(user.name, style: AppText.heading(28, color: Colors.white)),
          Text(user.memberId,
              style: AppText.body(14, color: Colors.white70)),
          const SizedBox(height: 18),
          if (hasPlan) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: frozen
                    ? (mm.freezeDaysLeft /
                        (mm.currentFreeze!.length == 0 ? 1 : mm.currentFreeze!.length))
                    : mm.progress,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(
                    frozen ? const Color(0xFFBFE3F5) : Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(frozen ? 'Sisa masa beku' : 'Sisa masa aktif',
                        style: AppText.body(12, color: Colors.white70)),
                    Row(
                      children: [
                        Text(
                            frozen
                                ? '${mm.freezeDaysLeft} hari'
                                : '${mm.remainingDays} hari',
                            style: AppText.heading(21, color: Colors.white)),
                        if (!frozen) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => context.go('/packages'),
                            child: const Icon(Icons.add_circle_outline,
                                color: Colors.white70, size: 22),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(frozen ? 'Aktif lagi' : 'Berlaku s.d.',
                        style: AppText.body(12, color: Colors.white70)),
                    Text(
                        frozen
                            ? fmtDate(mm.currentFreeze!.end
                                .add(const Duration(days: 1)))
                            : fmtDate(mm.end),
                        style: AppText.heading(21, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ] else ...[
            Text('Belum ada membership aktif',
                style: AppText.body(14, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Pilih paket untuk mulai booking kelas dan check-in wajah.',
                style: AppText.body(12, color: Colors.white70)),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: () => context.go('/packages'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.ink,
                    elevation: 0,
                    shape: const StadiumBorder()),
                child: Text('Lihat paket membership',
                    style: AppText.heading(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FrozenBanner extends StatelessWidget {
  const _FrozenBanner({required this.onActivate});
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFEAF5FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.ac_unit, color: Color(0xFF1E5870), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Check-in dan booking dijeda. Aktif lagi otomatis saat masa beku selesai.',
                    style: AppText.body(12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF1E5870))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton('Aktifkan kembali sekarang',
              icon: Icons.play_arrow_rounded, onPressed: onActivate),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.event_available_outlined, 'Riwayat\nCheck-in',
          () => context.go('/profile/checkins')),
      (Icons.assignment_outlined, 'Booking\nKelas', () => context.go('/classes')),
      (Icons.receipt_long_outlined, 'Beli\nPaket', () => context.go('/packages')),
      (Icons.headset_mic_outlined, 'Customer\nService', () => _cs(context)),
      (Icons.credit_card_off_outlined, 'Bekukan\nMember', () {
        if (!app.hasActiveMembership) {
          toast(context, 'Fitur ini hanya untuk member aktif');
        } else if (app.isFrozen || app.membership!.isFreezeScheduled) {
          context.push('/freeze/status');
        } else {
          context.push('/freeze');
        }
      }),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final it in items)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: it.$3,
            child: SizedBox(
              width: 62,
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(color: Color(0x14000000), blurRadius: 10)
                      ],
                    ),
                    child: Icon(it.$1, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(it.$2,
                      textAlign: TextAlign.center,
                      style: AppText.body(10.5, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _cs(BuildContext context) {
    const wa = '+62 812-0000-1234';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Customer Service', style: AppText.heading(20)),
            const SizedBox(height: 8),
            Text('Hubungi kami di WhatsApp, Senin–Minggu 06.00–21.00',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: AppColors.muted)),
            const SizedBox(height: 16),
            Text(wa, style: AppText.heading(22)),
            const SizedBox(height: 16),
            PrimaryButton('Salin nomor', icon: Icons.copy, onPressed: () {
              Clipboard.setData(const ClipboardData(text: wa));
              Navigator.pop(context);
              toast(context, 'Nomor disalin');
            }),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.app, required this.active});
  final AppState app;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final goal = app.weeklyTarget?.count;
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final dots = app.weekDots;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.go('/target'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_fixed, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Atur Target',
                          style: AppText.body(11,
                              weight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              Text(goal == null ? 'Belum ada target' : 'Target ${goal}x/minggu',
                  style: AppText.body(12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dots[i] && active
                            ? AppColors.teal
                            : AppColors.tealSoft,
                      ),
                      child: dots[i] && active
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(days[i], style: AppText.body(11)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayClasses extends StatelessWidget {
  const _TodayClasses({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final list = app.classesOn(DateTime.now());
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final c = list[i];
          final booked = app.isBooked(c);
          final dark = booked;
          final fg = dark ? Colors.white : AppColors.ink;
          return GestureDetector(
            onTap: () => context.go('/classes'),
            child: Container(
              width: 210,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? AppColors.navy : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 12)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(fmtTime(c.start),
                      bg: dark ? AppColors.lime : AppColors.tealSoft,
                      fg: AppColors.ink),
                  const Spacer(),
                  Text(c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading(18, color: fg)),
                  Text('${c.studio} . ${c.coach}',
                      style: AppText.body(11,
                          color: dark ? Colors.white70 : AppColors.muted)),
                  const SizedBox(height: 6),
                  Text(
                      booked
                          ? 'Terbooking'
                          : app.slotsLeft(c) <= 0
                              ? 'Penuh'
                              : '${app.slotsLeft(c)} slot tersisa',
                      style: AppText.body(11.5,
                          weight: FontWeight.w600, color: fg)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pusat Informasi (pengumuman, kelas, promo).
class InfoCenterScreen extends StatefulWidget {
  const InfoCenterScreen({super.key});
  @override
  State<InfoCenterScreen> createState() => _InfoCenterScreenState();
}

class _InfoCenterScreenState extends State<InfoCenterScreen> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.visibleAnnouncements
        .where((a) => _filter == 'Semua' || a.category == _filter)
        .toList();
    final banner = app.activeBanner;
    return Column(
      children: [
        const PageHeader('Pusat Informasi'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              if (banner != null) ...[
                GestureDetector(
                  onTap: () => _openDetail(banner),
                  child: InfoBanner(
                    category: banner.category,
                    title: banner.title,
                    body: banner.body,
                    validUntil: banner.validUntil,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in ['Semua', 'Pengumuman', 'Kelas', 'Promo'])
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: PillChip(f,
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final a in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoTile(
                    category: a.category,
                    title: a.title,
                    meta: '${a.views}x dilihat • ${_ago(a.at)}',
                    onTap: () => _openDetail(a),
                  ),
                ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                      child: Text('Belum ada informasi',
                          style: AppText.body(13, color: AppColors.muted))),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Detail informasi (bottom sheet). Membuka detail menambah hitungan dilihat.
  void _openDetail(Announcement a) {
    context.read<AppState>().markAnnouncementViewed(a.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDE5E4),
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              StatusChip(a.category),
              const SizedBox(height: 12),
              Text(a.title, style: AppText.heading(20)),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    a.body.trim().isEmpty ? 'Tidak ada keterangan tambahan.' : a.body,
                    style: AppText.body(13.5),
                  ),
                ),
              ),
              if (a.validUntil != null) ...[
                const SizedBox(height: 12),
                Text('Berlaku sampai ${fmtDate(a.validUntil!)}',
                    style: AppText.body(12, color: AppColors.muted)),
              ],
              const SizedBox(height: 20),
              PrimaryButton('Tutup', onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  String _ago(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'Hari ini';
    if (days < 7) return '$days hari yang lalu';
    return '${(days / 7).floor()} Minggu yang lalu';
  }
}
