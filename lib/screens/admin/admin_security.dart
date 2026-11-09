import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';

class AdminSecurityScreen extends StatefulWidget {
  const AdminSecurityScreen({super.key});
  @override
  State<AdminSecurityScreen> createState() => _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends State<AdminSecurityScreen> {
  int _tab = 0;
  int _filter = 0; // 0 semua, 1 diblokir, 2 dibuka kembali
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pending = app.freezeRequestsBy('Menunggu').length;
    final frozenCount = app.members
        .where((u) => app.statusOf(u) == MemberStatus.frozen)
        .length;

    Widget stat(String l, String v, Color c) => Container(
      width: 108,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(11, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(v, style: AppText.heading(20, color: c)),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        AdminHeader(
          'Keamanan',
          subtitle: 'Kelola akses dan keamanan member',
          trailing: IconButton(
            onPressed: () => context.push('/admin/logs'),
            icon: const Icon(Icons.history),
            tooltip: 'Log aktivitas',
          ),
        ),
        Segmented(
          labels: [
            'Blacklist ${app.activeBlocks.length}',
            'Pembekuan $pending',
          ],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 78,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              stat('Total Member', '${app.members.length}', AppColors.ink),
              stat(
                'Member Aktif',
                '${app.activeMemberCount}',
                AppColors.tealDark,
              ),
              stat('Diblokir', '${app.blockedCount}', AppColors.danger),
              stat('Dibekukan', '$frozenCount', const Color(0xFF2B6CB0)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_tab == 0)
          ..._blacklist(context, app)
        else ...[
          FreezeRequestsView(embedded: true),
        ],
      ],
    );
  }

  List<Widget> _blacklist(BuildContext context, AppState app) {
    final k = _q.trim().toLowerCase();
    bool match(BlockRecord b) {
      final u = app.userById(b.userId);
      if (u == null) return false;
      return k.isEmpty ||
          u.name.toLowerCase().contains(k) ||
          u.email.toLowerCase().contains(k) ||
          u.memberId.toLowerCase().contains(k);
    }

    final active = _filter == 2
        ? <BlockRecord>[]
        : app.activeBlocks.where(match).toList();
    final reopened = _filter == 1
        ? <BlockRecord>[]
        : app.reopenedBlocks.where(match).toList();

    return [
      SearchBox(
        hint: 'Cari nama, email, atau ID member',
        onChanged: (v) => setState(() => _q = v),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          for (final e in const [
            (0, 'Semua'),
            (1, 'Diblokir'),
            (2, 'Dibuka kembali'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PillChip(
                e.$2,
                selected: _filter == e.$1,
                onTap: () => setState(() => _filter = e.$1),
              ),
            ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Daftar blacklist', style: AppText.heading(16)),
          ElevatedButton(
            onPressed: () async {
              final u = await pickMemberSheet(context);
              if (u != null && context.mounted) showBlockSheet(context, u);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('+ Blokir member'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (active.isEmpty && reopened.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Tidak ada data',
              style: AppText.body(13, color: AppColors.muted),
            ),
          ),
        ),
      for (final b in active) _blockCard(context, app, b),
      for (final b in reopened) _blockCard(context, app, b),
    ];
  }

  Widget _blockCard(BuildContext context, AppState app, BlockRecord b) {
    final u = app.userById(b.userId);
    if (u == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MemberAvatar(
                  u,
                  size: 42,
                  status: b.active ? MemberStatus.blocked : MemberStatus.active,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        style: AppText.body(14, weight: FontWeight.w800),
                      ),
                      Text(
                        '${u.memberId} · ${u.email}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                b.active
                    ? const StatusChip(
                        'DIBLOKIR',
                        bg: Color(0xFFFBE3E3),
                        fg: AppColors.danger,
                      )
                    : const StatusChip(
                        'DIBUKA',
                        bg: Color(0xFFD6F0EC),
                        fg: AppColors.tealDark,
                      ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alasan: ${b.reason}',
                    style: AppText.body(12.5, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Diblokir ${fmtDate(b.at)} · oleh ${b.by}',
                    style: AppText.body(11, color: AppColors.muted),
                  ),
                  if (!b.active)
                    Text(
                      'Dibuka ${b.unblockAt == null ? '' : fmtDate(b.unblockAt!)}${b.unblockNote == null ? '' : ' · ${b.unblockNote}'}',
                      style: AppText.body(11, color: AppColors.tealDark),
                    ),
                ],
              ),
            ),
            if (b.active) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => showUnblockSheet(context, u),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.tealSoft,
                    foregroundColor: AppColors.tealDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Buka blokir'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ======================================================= Permintaan beku
/// Daftar permintaan pembekuan/pengaktifan; dipakai di tab dan layar penuh.
class FreezeRequestsView extends StatefulWidget {
  const FreezeRequestsView({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<FreezeRequestsView> createState() => _FreezeRequestsViewState();
}

class _FreezeRequestsViewState extends State<FreezeRequestsView> {
  String _status = 'Menunggu';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.freezeRequestsBy(_status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final s in const ['Menunggu', 'Disetujui', 'Ditolak'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PillChip(
                  '$s ${app.freezeRequestsBy(s).length}',
                  selected: _status == s,
                  onTap: () => setState(() => _status = s),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Tidak ada permintaan $_status'.toLowerCase().replaceFirst(
                  't',
                  'T',
                ),
                style: AppText.body(13, color: AppColors.muted),
              ),
            ),
          ),
        for (final r in list)
          Builder(
            builder: (context) {
              final u = app.userById(r.userId);
              if (u == null) return const SizedBox.shrink();
              final isFreezeRequest = r.type == FreezeRequestType.freeze;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MemberAvatar(u, size: 42, status: app.statusOf(u)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name,
                                  style: AppText.body(
                                    14.5,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  u.memberId,
                                  style: AppText.body(
                                    11.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            r.status,
                            bg: r.status == 'Menunggu'
                                ? const Color(0xFFFFEBC8)
                                : r.status == 'Disetujui'
                                ? const Color(0xFFD6F0EC)
                                : const Color(0xFFFBE3E3),
                            fg: r.status == 'Menunggu'
                                ? const Color(0xFFB26A00)
                                : r.status == 'Disetujui'
                                ? AppColors.tealDark
                                : AppColors.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFreezeRequest
                                  ? 'Permintaan bekukan member'
                                  : 'Permintaan aktifkan kembali',
                              style: AppText.body(
                                12.5,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Alasan: ${r.reason}',
                              style: AppText.body(11.5, color: AppColors.muted),
                            ),
                            Text(
                              isFreezeRequest
                                  ? 'Mulai ${fmtDate(r.since)} · ${r.days} hari'
                                  : 'Beku sejak ${fmtDate(r.since)}',
                              style: AppText.body(11.5, color: AppColors.muted),
                            ),
                            Text(
                              'Diajukan ${relDay(r.requestedAt)}',
                              style: AppText.body(11.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      if (r.status == 'Menunggu') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                'Tolak',
                                outlined: true,
                                color: AppColors.danger,
                                onPressed: () async {
                                  final ok = await confirmSheet(
                                    context,
                                    title: 'Tolak permintaan?',
                                    message: isFreezeRequest
                                        ? 'Membership ${u.name} tetap aktif.'
                                        : 'Pembekuan ${u.name} tetap berjalan.',
                                    confirmLabel: 'Ya, tolak',
                                    danger: true,
                                  );
                                  if (ok && context.mounted) {
                                    final err = context
                                        .read<AppState>()
                                        .decideFreezeRequest(r.id, false);
                                    toast(
                                      context,
                                      err ?? 'Permintaan ${u.name} ditolak',
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                isFreezeRequest
                                    ? 'Setuju bekukan'
                                    : 'Setuju aktifkan',
                                color: AppColors.tealDark,
                                onPressed: () {
                                  final err = context
                                      .read<AppState>()
                                      .decideFreezeRequest(r.id, true);
                                  toast(
                                    context,
                                    err ??
                                        (isFreezeRequest
                                            ? 'Pembekuan ${u.name} disetujui'
                                            : 'Pengaktifan ${u.name} disetujui'),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Status membership hanya berubah setelah admin menyetujui atau menolak permintaan member.',
            style: AppText.body(12, color: const Color(0xFF8A5A00)),
          ),
        ),
      ],
    );
  }
}

class AdminUnfreezeScreen extends StatelessWidget {
  const AdminUnfreezeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AdminHeader(
              'Persetujuan Pembekuan',
              subtitle: 'Tinjau permintaan bekukan atau aktifkan member',
              showBack: true,
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: FreezeRequestsView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
