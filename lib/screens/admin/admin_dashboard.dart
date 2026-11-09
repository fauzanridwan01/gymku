import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../receipt_screen.dart';
import 'admin_common.dart';

IconData _logIcon(String k) => switch (k) {
  'price' => Icons.edit_outlined,
  'payment' => Icons.credit_card,
  'checkin' => Icons.check,
  'block' => Icons.block,
  'unblock' => Icons.lock_open,
  'promo' => Icons.sell_outlined,
  'info' => Icons.campaign_outlined,
  'freeze' => Icons.ac_unit,
  _ => Icons.info_outline,
};

Color _logColor(String k) => switch (k) {
  'block' => AppColors.danger,
  'unblock' => AppColors.tealDark,
  _ => AppColors.tealDark,
};

class LogRow extends StatelessWidget {
  const LogRow(this.e, {super.key});
  final LogEntry e;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _logColor(e.kind).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(_logIcon(e.kind), size: 19, color: _logColor(e.kind)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.text, style: AppText.body(13, weight: FontWeight.w700)),
              Text(
                '${e.detail.isEmpty ? '' : '${e.detail} · '}${relDay(e.at)}',
                style: AppText.body(11.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ================================================================ Dashboard
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pendingFreeze = app.freezeRequestsBy('Menunggu').length;
    final expiring = app.expiringMembers;
    final buckets = app.hourlyBuckets;
    final maxB = buckets.fold<int>(1, (a, b) => b > a ? b : a);
    final peakI = buckets.indexOf(maxB);
    final hours = ['06', '08', '10', '12', '14', '16', '18', '20'];
    final logs = app.logs.take(6).toList();

    Widget iconBtn(IconData i, VoidCallback onTap, {bool dot = false}) =>
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(i, size: 22),
                if (dot)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

    Widget action(
      IconData icon,
      String title,
      String sub,
      VoidCallback onTap,
    ) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBC8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFFB26A00)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body(13.5, weight: FontWeight.w700),
                  ),
                  Text(sub, style: AppText.body(11.5, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: AppText.heading(24)),
                  Text(
                    fmtDate(DateTime.now(), 'EEEE, d MMMM yyyy'),
                    style: AppText.body(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            iconBtn(Icons.people_outline, () => context.push('/admin/members')),
            iconBtn(
              Icons.notifications_none,
              () => _notifSheet(context, app),
              dot: pendingFreeze + expiring.length > 0,
            ),
            iconBtn(Icons.logout, () async {
              final ok = await confirmSheet(
                context,
                title: 'Keluar dari akun admin?',
                message: 'Kamu perlu login lagi untuk membuka panel admin.',
                confirmLabel: 'Ya, keluar',
                danger: true,
              );
              if (ok && context.mounted) context.read<AppState>().logout();
            }),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2A33), Color(0xFF0E5A57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengunjung hari ini',
                      style: AppText.body(11.5, color: Colors.white70),
                    ),
                    Text(
                      '${app.visitsToday}',
                      style: AppText.heading(46, color: AppColors.lime),
                    ),
                    StatusChip(
                      '${pctChange(app.visitsToday, app.visitsYesterday)} dari kemarin',
                      bg: Colors.white12,
                      fg: Colors.white,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendapatan 30 hari',
                      style: AppText.body(11.5, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shortRupiah(app.revenue30),
                      style: AppText.heading(24, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    StatusChip(
                      '${pctChange(app.revenue30, app.revenuePrev30)} vs 30 hari lalu',
                      bg: Colors.white12,
                      fg: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_outlined,
                      color: AppColors.tealDark,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Member baru', style: AppText.body(11.5)),
                        Text(
                          '${app.newMembersToday}',
                          style: AppText.heading(24),
                        ),
                        Text(
                          'hari ini',
                          style: AppText.body(11, color: AppColors.tealDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      color: AppColors.tealDark,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Member aktif', style: AppText.body(11.5)),
                        Text(
                          '${app.activeMemberCount}',
                          style: AppText.heading(24),
                        ),
                        Text(
                          '${expiring.length} akan berakhir',
                          style: AppText.body(
                            11,
                            color: const Color(0xFFB26A00),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                'Perlu tindakan',
                trailing: TextButton(
                  onPressed: () => context.go('/admin/security'),
                  child: const Text('Lihat semua'),
                ),
              ),
              if (pendingFreeze == 0 && expiring.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Semua beres, tidak ada yang perlu ditindak.',
                    style: AppText.body(13, color: AppColors.muted),
                  ),
                ),
              if (pendingFreeze > 0)
                action(
                  Icons.lock_outline,
                  'Permintaan pembekuan',
                  '$pendingFreeze member menunggu persetujuan',
                  () => context.push('/admin/unfreeze'),
                ),
              if (expiring.isNotEmpty)
                action(
                  Icons.event_outlined,
                  '${expiring.length} member berakhir 7 hari lagi',
                  'Kirim pengingat perpanjangan',
                  () => _expiringSheet(context, expiring),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => context.go('/admin/scan'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tealDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan wajah member masuk',
                        style: AppText.body(
                          14.5,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Pindai wajah di pintu masuk',
                        style: AppText.body(12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jam ramai', style: AppText.heading(17)),
                  if (buckets.any((b) => b > 0))
                    StatusChip(
                      'Puncak ${hours[peakI]}.00',
                      bg: AppColors.lime,
                      fg: AppColors.ink,
                    ),
                ],
              ),
              Text(
                'Rata-rata 14 hari terakhir',
                style: AppText.body(11, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 90,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < buckets.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            height: 8 + 82 * (buckets[i] / maxB),
                            decoration: BoxDecoration(
                              color: i == peakI
                                  ? AppColors.tealDark
                                  : AppColors.tealSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final h in hours)
                    Expanded(
                      child: Text(
                        h,
                        textAlign: TextAlign.center,
                        style: AppText.body(10.5, color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                'Log Aktivitas',
                trailing: TextButton(
                  onPressed: () => context.push('/admin/logs'),
                  child: const Text('Lihat semua'),
                ),
              ),
              for (final e in logs) LogRow(e),
            ],
          ),
        ),
      ],
    );
  }

  void _notifSheet(BuildContext context, AppState app) {
    final pending = app.freezeRequestsBy('Menunggu').length;
    final exp = app.expiringMembers.length;
    showAppSheet<void>(context, (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notifikasi', style: AppText.heading(20)),
            const SizedBox(height: 12),
            if (pending + exp == 0)
              Text(
                'Belum ada notifikasi baru.',
                style: AppText.body(13, color: AppColors.muted),
              ),
            if (pending > 0)
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text('$pending permintaan pembekuan'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/admin/unfreeze');
                },
              ),
            if (exp > 0)
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text('$exp member hampir berakhir'),
                onTap: () {
                  Navigator.pop(ctx);
                  _expiringSheet(context, app.expiringMembers);
                },
              ),
          ],
        ),
      );
    });
  }

  void _expiringSheet(BuildContext context, List<AppUser> list) {
    showAppSheet<void>(context, (ctx) {
      final app = ctx.read<AppState>();
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Member akan berakhir', style: AppText.heading(20)),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final u in list)
                    ListTile(
                      leading: MemberAvatar(
                        u,
                        size: 38,
                        status: MemberStatus.expiring,
                      ),
                      title: Text(
                        u.name,
                        style: AppText.body(14, weight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Sisa ${app.membershipOf(u.id)?.remainingDays ?? 0} hari · ${u.memberId}',
                        style: AppText.body(12, color: AppColors.muted),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/admin/members/${u.id}');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              'Kirim pengingat ke ${list.length} member',
              icon: Icons.notifications_active_outlined,
              onPressed: () {
                Navigator.pop(ctx);
                toast(
                  context,
                  'Pengingat perpanjangan dikirim ke ${list.length} member',
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

// ================================================================ Log penuh
class AdminLogsScreen extends StatelessWidget {
  const AdminLogsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final logs = context.watch<AppState>().logs;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AdminHeader(
              'Log Aktivitas',
              subtitle: 'Semua tindakan admin dan sistem',
              showBack: true,
            ),
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada aktivitas',
                        style: AppText.body(13, color: AppColors.muted),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        AppCard(
                          child: Column(
                            children: [for (final e in logs) LogRow(e)],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================== Laporan
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  int _monthIdx = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final months = app.reportMonths;
    final m = months[_monthIdx];
    final prev = DateTime(m.year, m.month - 1, 1);
    final visits = app.visitsInMonth(m);
    final revenue = app.revenueInMonth(m);
    final weeks = app.weeklyVisits(m);
    final maxW = weeks.fold<int>(1, (a, b) => b > a ? b : a);
    final inactive = app.inactiveMembers();
    final txns = app.allTxns
        .where((t) => t.at.year == m.year && t.at.month == m.month)
        .take(5)
        .toList();

    Widget stat(String label, String value, String delta) => Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.body(11.5, color: AppColors.muted)),
            const SizedBox(height: 6),
            Text(value, style: AppText.heading(22)),
            const SizedBox(height: 4),
            Text(delta, style: AppText.body(11, color: AppColors.tealDark)),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const AdminHeader(
          'Laporan Bulanan',
          subtitle: 'Ringkasan kunjungan dan pendapatan',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: PopupMenuButton<int>(
            onSelected: (i) => setState(() => _monthIdx = i),
            itemBuilder: (_) => [
              for (var i = 0; i < months.length; i++)
                PopupMenuItem(
                  value: i,
                  child: Text(fmtDate(months[i], 'MMMM yyyy')),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fmtDate(m, 'MMMM yyyy'),
                    style: AppText.body(
                      13,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            stat(
              'Total kunjungan',
              '$visits',
              '${pctChange(visits, app.visitsInMonth(prev))} vs bulan lalu',
            ),
            const SizedBox(width: 12),
            stat(
              'Pendapatan',
              shortRupiah(revenue),
              '${pctChange(revenue, app.revenueInMonth(prev))} vs bulan lalu',
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kunjungan per minggu', style: AppText.heading(16)),
              const SizedBox(height: 14),
              SizedBox(
                height: 130,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < weeks.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${weeks[i]}',
                                style: AppText.body(11, color: AppColors.muted),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 8 + 90 * (weeks[i] / maxW),
                                decoration: BoxDecoration(
                                  color: weeks[i] == maxW && maxW > 1
                                      ? AppColors.tealDark
                                      : AppColors.tealSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i < weeks.length; i++)
                    Expanded(
                      child: Text(
                        'Mg ${i + 1}',
                        textAlign: TextAlign.center,
                        style: AppText.body(11, color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaksi bulan ini', style: AppText.heading(16)),
                  StatusChip('${txns.length} terbaru'),
                ],
              ),
              if (txns.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Belum ada transaksi di bulan ini.',
                    style: AppText.body(13, color: AppColors.muted),
                  ),
                ),
              for (final t in txns)
                InkWell(
                  onTap: () => ReceiptScreen.open(context, t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.memberName,
                                style: AppText.body(
                                  13,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${t.planName} · ${t.method} · ${fmtDate(t.at, 'd MMM')}',
                                style: AppText.body(
                                  11.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          rupiah(t.amount),
                          style: AppText.body(13, weight: FontWeight.w800),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Member tidak aktif', style: AppText.heading(16)),
                  StatusChip(
                    '${inactive.length} member',
                    bg: const Color(0xFFFBE3E3),
                    fg: AppColors.danger,
                  ),
                ],
              ),
              Text(
                'Aktif tapi tidak datang 30 hari atau lebih',
                style: AppText.body(11, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              if (inactive.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Semua member aktif rutin datang.',
                    style: AppText.body(13, color: AppColors.muted),
                  ),
                ),
              for (final e in inactive.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      MemberAvatar(e.user, size: 38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.user.name,
                              style: AppText.body(13, weight: FontWeight.w700),
                            ),
                            Text(
                              e.days >= 999
                                  ? 'Belum pernah datang'
                                  : 'Terakhir datang ${e.days} hari lalu',
                              style: AppText.body(11.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _contactSheet(context, e.user),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.tealSoft,
                          foregroundColor: AppColors.tealDark,
                        ),
                        child: const Text('Hubungi'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _contactSheet(BuildContext context, AppUser u) {
    showAppSheet<void>(context, (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hubungi ${u.name}', style: AppText.heading(19)),
            const SizedBox(height: 14),
            Text(
              u.phone.isEmpty ? 'Nomor HP belum diisi' : u.phone,
              style: AppText.heading(21),
            ),
            const SizedBox(height: 4),
            Text(u.email, style: AppText.body(12.5, color: AppColors.muted)),
            const SizedBox(height: 16),
            PrimaryButton(
              'Salin nomor HP',
              icon: Icons.copy,
              onPressed: u.phone.isEmpty
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: u.phone));
                      Navigator.pop(ctx);
                      toast(context, 'Nomor disalin');
                    },
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              'Kirim pesan ajakan kembali',
              outlined: true,
              onPressed: () {
                Navigator.pop(ctx);
                toast(context, 'Pesan ajakan dikirim ke ${u.name}');
              },
            ),
          ],
        ),
      );
    });
  }
}
