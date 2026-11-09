import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../receipt_screen.dart';
import 'admin_common.dart';

// ============================================================ Daftar member
class AdminMemberListScreen extends StatefulWidget {
  const AdminMemberListScreen({super.key});
  @override
  State<AdminMemberListScreen> createState() => _AdminMemberListScreenState();
}

class _AdminMemberListScreenState extends State<AdminMemberListScreen> {
  String _q = '';
  MemberStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = app.members;
    final list = app.searchMembers(_q, status: _filter);
    const filters = <(String, MemberStatus?)>[
      ('Semua', null),
      ('Aktif', MemberStatus.active),
      ('Akan berakhir', MemberStatus.expiring),
      ('Dibekukan', MemberStatus.frozen),
      ('Diblokir', MemberStatus.blocked),
      ('Berakhir', MemberStatus.expired),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          AdminHeader('Daftar Member', subtitle: '${all.length} member terdaftar', showBack: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SearchBox(
                hint: 'Cari nama, email, atau ID member',
                onChanged: (v) => setState(() => _q = v)),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final f in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PillChip(f.$1,
                        selected: _filter == f.$2,
                        onTap: () => setState(() => _filter = f.$2)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text('Member tidak ditemukan',
                        style: AppText.body(13, color: AppColors.muted)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Column(children: [
                          for (var i = 0; i < list.length; i++) ...[
                            _MemberRow(user: list[i]),
                            if (i < list.length - 1) const Divider(height: 1),
                          ],
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text('Menampilkan ${list.length} dari ${all.length} member',
                              style: AppText.body(11.5, color: AppColors.muted)),
                        ),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.user});
  final AppUser user;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final st = app.statusOf(user);
    return InkWell(
      onTap: () => context.push('/admin/members/${user.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          MemberAvatar(user, size: 42, status: st),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: AppText.body(14, weight: FontWeight.w700)),
              Text(user.memberId, style: AppText.body(11.5, color: AppColors.muted)),
            ]),
          ),
          StatusBadge(st),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) {
              if (v == 'detail') context.push('/admin/members/${user.id}');
              if (v == 'block') showBlockSheet(context, user);
              if (v == 'unblock') showUnblockSheet(context, user);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'detail', child: Text('Lihat detail')),
              if (user.blocked)
                const PopupMenuItem(value: 'unblock', child: Text('Buka blokir'))
              else
                PopupMenuItem(
                    value: 'block',
                    child: Text('Blokir Member', style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ]),
      ),
    );
  }
}

// =========================================================== Detail member
class AdminMemberDetailScreen extends StatelessWidget {
  const AdminMemberDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.userById(userId);
    if (u == null) {
      return Scaffold(
          body: SafeArea(
              child: Column(children: [
        const AdminHeader('Detail Member', showBack: true),
        Expanded(
            child: Center(
                child: Text('Member tidak ditemukan',
                    style: AppText.body(13, color: AppColors.muted)))),
      ])));
    }
    final m = app.membershipOf(u.id);
    final st = app.statusOf(u);
    final last = app.lastVisitOf(u.id);
    final block = app.activeBlockOf(u.id);

    Widget kv(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(a, style: AppText.body(12.5, color: AppColors.muted)),
            Flexible(
                child: Text(b,
                    textAlign: TextAlign.right,
                    style: AppText.body(13, weight: FontWeight.w700))),
          ]),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const AdminHeader('Detail Member', subtitle: null, showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(children: [
                    MemberAvatar(u, size: 64, status: st),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u.name, style: AppText.heading(19, color: Colors.white)),
                        Text(u.hasFace ? 'Foto wajah terdaftar' : 'Foto wajah belum terdaftar',
                            style: AppText.body(11.5, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          if (m != null)
                            const StatusChip('Premium', bg: AppColors.lime, fg: AppColors.ink),
                          StatusBadge(st),
                        ]),
                      ]),
                    ),
                  ]),
                ),
                if (block != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFBE3E3), borderRadius: BorderRadius.circular(16)),
                    child: Text(
                        'Diblokir ${fmtDate(block.at)} oleh ${block.by}\nAlasan: ${block.reason}',
                        style: AppText.body(12.5, color: AppColors.danger)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: AppCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Check-in bulan ini', style: AppText.body(11.5, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Text('${app.visitsInMonthOf(u.id, DateTime.now())} kali',
                            style: AppText.heading(20)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Terakhir datang', style: AppText.body(11.5, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Text(relDay(last), style: AppText.heading(15)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Data member', style: AppText.heading(16)),
                    const SizedBox(height: 6),
                    kv('ID Member', u.memberId),
                    kv('No. HP', u.phone.isEmpty ? '-' : u.phone),
                    kv('Email', u.email),
                    kv('Tanggal lahir',
                        u.birthDate == null ? '-' : '${fmtDate(u.birthDate!, 'd MMMM yyyy')} (${ageOf(u.birthDate)} th)'),
                    kv('Jenis kelamin', u.gender.isEmpty ? '-' : u.gender),
                    kv('Bergabung', u.joinedAt == null ? '-' : fmtDate(u.joinedAt!)),
                  ]),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Membership', style: AppText.heading(16)),
                      StatusBadge(st),
                    ]),
                    const SizedBox(height: 8),
                    if (m == null)
                      Text('Belum punya paket membership.',
                          style: AppText.body(13, color: AppColors.muted))
                    else ...[
                      Text('Premium ${m.totalDays >= 360 ? '${(m.totalDays / 360).round()} Tahun' : '${(m.totalDays / 30).round()} Bulan'}',
                          style: AppText.body(14, weight: FontWeight.w800)),
                      Text('Mulai ${fmtDate(m.start)} · Berakhir ${fmtDate(m.end)}',
                          style: AppText.body(11.5, color: AppColors.muted)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 1 - m.progress,
                          minHeight: 8,
                          backgroundColor: AppColors.tealSoft,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Terpakai ${m.totalDays - m.remainingDays} hari',
                            style: AppText.body(11.5, color: AppColors.tealDark)),
                        Text('Sisa ${m.remainingDays} hari',
                            style: AppText.body(11.5, color: AppColors.tealDark)),
                      ]),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
                PrimaryButton('Lihat riwayat check-in dan pembayaran',
                    outlined: true,
                    color: AppColors.tealDark,
                    onPressed: () => _historySheet(context, u)),
                const SizedBox(height: 10),
                PrimaryButton('Catat kunjungan manual',
                    icon: Icons.how_to_reg_outlined,
                    onPressed: () {
                      final err = context
                          .read<AppState>()
                          .adminCheckIn(u, method: 'Check-in manual');
                      toast(context, err ?? 'Kunjungan ${u.name} tercatat (manual)');
                    }),
                const SizedBox(height: 10),
                if (u.blocked)
                  PrimaryButton('Buka Blokir',
                      color: AppColors.teal, onPressed: () => showUnblockSheet(context, u))
                else
                  PrimaryButton('Blokir Member',
                      outlined: true,
                      color: AppColors.danger,
                      onPressed: () => showBlockSheet(context, u)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _historySheet(BuildContext context, AppUser u) {
    final app = context.read<AppState>();
    final cis = app.checkInsOf(u.id).take(10).toList();
    final txns = app.txnsOf(u.id);
    showAppSheet<void>(context, (ctx) {
      return DefaultTabController(
        length: 2,
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: Column(children: [
            const SizedBox(height: 14),
            Text('Riwayat ${u.name}', style: AppText.heading(19)),
            const TabBar(tabs: [Tab(text: 'Check-in'), Tab(text: 'Pembayaran')]),
            Expanded(
              child: TabBarView(children: [
                cis.isEmpty
                    ? Center(child: Text('Belum ada check-in', style: AppText.body(13, color: AppColors.muted)))
                    : ListView(children: [
                        for (final c in cis)
                          ListTile(
                            leading: const Icon(Icons.check_circle_outline, color: AppColors.tealDark),
                            title: Text(fmtDate(c.at, 'EEEE, d MMM yyyy'),
                                style: AppText.body(13.5, weight: FontWeight.w700)),
                            subtitle: Text('${fmtTime(c.at)} · ${c.method}',
                                style: AppText.body(12, color: AppColors.muted)),
                          ),
                      ]),
                txns.isEmpty
                    ? Center(child: Text('Belum ada pembayaran', style: AppText.body(13, color: AppColors.muted)))
                    : ListView(children: [
                        for (final t in txns)
                          ListTile(
                            leading: const Icon(Icons.receipt_long, color: AppColors.tealDark),
                            title: Text(t.planName, style: AppText.body(13.5, weight: FontWeight.w700)),
                            subtitle: Text('${t.id} · ${fmtDate(t.at)}',
                                style: AppText.body(12, color: AppColors.muted)),
                            trailing: Text(rupiah(t.amount),
                                style: AppText.body(13, weight: FontWeight.w800)),
                            onTap: () => ReceiptScreen.open(context, t),
                          ),
                      ]),
              ]),
            ),
          ]),
        ),
      );
    });
  }
}

// ============================================================== Cari member
class AdminSearchScreen extends StatefulWidget {
  const AdminSearchScreen({super.key});
  @override
  State<AdminSearchScreen> createState() => _AdminSearchScreenState();
}

class _AdminSearchScreenState extends State<AdminSearchScreen> {
  String _q = '';
  bool _onlyActive = false;
  String? _gender;
  int _ageBand = 0; // 0 semua, 1 <20, 2 20-29, 3 30+
  String? _selectedId;

  bool _ageOk(AppUser u) {
    final a = ageOf(u.birthDate);
    return switch (_ageBand) {
      1 => a < 20,
      2 => a >= 20 && a < 30,
      3 => a >= 30,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app
        .searchMembers(_q, gender: _gender)
        .where((u) => !_onlyActive ||
            app.statusOf(u) == MemberStatus.active ||
            app.statusOf(u) == MemberStatus.expiring)
        .where(_ageOk)
        .toList();
    final selected = list.where((u) => u.id == _selectedId).firstOrNull;
    const bands = ['Rentang usia', '< 20 th', '20–29 th', '30+ th'];

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const AdminHeader('Cari Member',
              subtitle: 'Catat kunjungan manual bila scan bermasalah', showBack: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SearchBox(
                hint: 'Nama, email, atau ID member',
                autofocus: true,
                onChanged: (v) => setState(() => _q = v)),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                PillChip('Semua',
                    selected: !_onlyActive && _gender == null && _ageBand == 0,
                    onTap: () => setState(() {
                          _onlyActive = false;
                          _gender = null;
                          _ageBand = 0;
                        })),
                const SizedBox(width: 8),
                PillChip('Aktif',
                    selected: _onlyActive, onTap: () => setState(() => _onlyActive = !_onlyActive)),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (v) => setState(() => _gender = v == 'all' ? null : v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'all', child: Text('Semua')),
                    PopupMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                    PopupMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                  ],
                  child: IgnorePointer(
                      child: PillChip(_gender ?? 'Jenis kelamin',
                          selected: _gender != null, onTap: () {})),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<int>(
                  onSelected: (v) => setState(() => _ageBand = v),
                  itemBuilder: (_) => [
                    for (var i = 0; i < bands.length; i++)
                      PopupMenuItem(value: i, child: Text(i == 0 ? 'Semua usia' : bands[i])),
                  ],
                  child: IgnorePointer(
                      child: PillChip(bands[_ageBand],
                          selected: _ageBand != 0, onTap: () {})),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${list.length} hasil ditemukan',
                  style: AppText.body(12, color: AppColors.muted)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              children: [
                for (final u in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => setState(() => _selectedId = u.id),
                      borderColor: _selectedId == u.id ? AppColors.teal : null,
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        MemberAvatar(u, size: 42, status: app.statusOf(u)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(u.name, style: AppText.body(14, weight: FontWeight.w800)),
                            Text('${u.memberId} · ${ageOf(u.birthDate)} tahun',
                                style: AppText.body(11.5, color: AppColors.muted)),
                          ]),
                        ),
                        StatusBadge(app.statusOf(u)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Text('Kunjungan tercatat dengan tanda "manual"',
                    style: AppText.body(11, color: AppColors.muted)),
              ]),
              const SizedBox(height: 10),
              PrimaryButton('Catat kunjungan',
                  onPressed: selected == null
                      ? null
                      : () {
                          final err = context
                              .read<AppState>()
                              .adminCheckIn(selected, method: 'Check-in manual');
                          toast(context, err ?? 'Kunjungan ${selected.name} tercatat (manual)');
                          if (err == null) context.go('/admin/scan');
                        }),
            ]),
          ),
        ]),
      ),
    );
  }
}
