import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

// ----------------------------------------------------------------- helpers
String shortRupiah(int v) {
  if (v >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1).replaceAll('.', ',')} M';
  if (v >= 1000000) {
    final x = v / 1000000;
    final t = x >= 100 ? x.round().toString() : x.toStringAsFixed(1).replaceAll('.', ',');
    return 'Rp $t jt';
  }
  return rupiah(v);
}

String relDay(DateTime? d) {
  if (d == null) return 'Belum pernah';
  final diff = today().difference(dateOnly(d)).inDays;
  final t = DateFormat('HH.mm').format(d);
  if (diff == 0) return 'Hari ini, $t';
  if (diff == 1) return 'Kemarin, $t';
  return '${fmtDate(d, 'd MMM')}, $t';
}

int ageOf(DateTime? b) {
  if (b == null) return 0;
  final n = today();
  var a = n.year - b.year;
  if (n.month < b.month || (n.month == b.month && n.day < b.day)) a--;
  return a;
}

String pctChange(num now, num before) {
  if (before == 0) return now == 0 ? '0%' : '+100%';
  final p = ((now - before) / before * 100).round();
  return '${p >= 0 ? '+' : ''}$p%';
}

(Color, Color) statusColors(MemberStatus s) => switch (s) {
      MemberStatus.active => (const Color(0xFFD6F0EC), AppColors.tealDark),
      MemberStatus.expiring => (const Color(0xFFFFEBC8), const Color(0xFFB26A00)),
      MemberStatus.expired => (const Color(0xFFFBE3E3), AppColors.danger),
      MemberStatus.frozen => (const Color(0xFFDCEBFF), const Color(0xFF2B6CB0)),
      MemberStatus.blocked => (const Color(0xFFFBE3E3), AppColors.danger),
      MemberStatus.none => (const Color(0xFFE5E5E5), AppColors.muted),
    };

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final MemberStatus status;
  @override
  Widget build(BuildContext context) {
    final c = statusColors(status);
    return StatusChip(statusLabel(status), bg: c.$1, fg: c.$2);
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar(this.user, {super.key, this.size = 40, this.status});
  final AppUser user;
  final double size;
  final MemberStatus? status;

  @override
  Widget build(BuildContext context) {
    final bytes = user.faceBytes;
    final c = status == null ? (AppColors.tealSoft, AppColors.tealDark) : statusColors(status!);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: c.$1,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes != null
          ? null
          : Text(user.initials,
              style: AppText.body(size * 0.34, weight: FontWeight.w800, color: c.$2)),
    );
  }
}

class Segmented extends StatelessWidget {
  const Segmented(
      {super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFDDE8E6), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: i == index ? AppColors.navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(labels[i],
                    style: AppText.body(13,
                        weight: FontWeight.w700,
                        color: i == index ? Colors.white : AppColors.ink)),
              ),
            ),
          ),
      ]),
    );
  }
}

class AdminHeader extends StatelessWidget {
  const AdminHeader(this.title, {super.key, this.subtitle, this.showBack = false, this.trailing});
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title, showBack: showBack, trailing: trailing),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(subtitle!, style: AppText.body(12, color: AppColors.tealDark)),
        ),
    ]);
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.hint, required this.onChanged, this.controller, this.autofocus = false});
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool autofocus;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        style: AppText.body(14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body(13.5, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search, size: 22),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );
}

// ------------------------------------------------------------------- shell
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  int _index(String loc) {
    if (loc.startsWith('/admin/reports')) return 1;
    if (loc.startsWith('/admin/scan') || loc.startsWith('/admin/search')) return 2;
    if (loc.startsWith('/admin/packages') || loc.startsWith('/admin/promo')) return 3;
    if (loc.startsWith('/admin/security') || loc.startsWith('/admin/unfreeze')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AppState>().currentUser == null) return const Scaffold();
    final loc = GoRouterState.of(context).uri.toString();
    final idx = _index(loc);
    const items = [
      (Icons.home_outlined, Icons.home, 'Dashboard', '/admin'),
      (Icons.bar_chart_outlined, Icons.bar_chart, 'Laporan', '/admin/reports'),
      (Icons.center_focus_strong_outlined, Icons.center_focus_strong, 'Scan', '/admin/scan'),
      (Icons.sell_outlined, Icons.sell, 'Paket', '/admin/packages'),
      (Icons.shield_outlined, Icons.shield, 'Keamanan', '/admin/security'),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 10)],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => context.go(items[i].$4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(idx == i ? items[i].$2 : items[i].$1,
                            size: 25, color: idx == i ? AppColors.ink : AppColors.muted),
                        const SizedBox(height: 2),
                        Text(items[i].$3,
                            style: AppText.body(10.5,
                                weight: idx == i ? FontWeight.w700 : FontWeight.w400,
                                color: idx == i ? AppColors.ink : AppColors.muted)),
                      ],
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ sheets
Widget _sheetShell(BuildContext context, List<Widget> children) => Padding(
      padding: EdgeInsets.fromLTRB(
          22, 12, 22, 22 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );

Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: builder,
    );

/// Sheet "Blokir member ini?" — alasan wajib.
Future<void> showBlockSheet(BuildContext context, AppUser u) {
  final ctrl = TextEditingController();
  String? error; // state sheet disimpan di luar builder agar tidak reset
  return showAppSheet<void>(context, (ctx) {
    return StatefulBuilder(builder: (ctx, setS) {
      final app = ctx.read<AppState>();
      return _sheetShell(ctx, [
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Blokir member ini?', style: AppText.heading(20))),
        const SizedBox(height: 14),
        Row(children: [
          MemberAvatar(u, size: 44, status: app.statusOf(u)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.name, style: AppText.body(15, weight: FontWeight.w800)),
            Text('${u.memberId} · ${statusLabel(app.statusOf(u))}',
                style: AppText.body(12, color: AppColors.muted)),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Text('Status akun', style: AppText.body(12, color: AppColors.muted)),
          const SizedBox(width: 10),
          const StatusChip('Aktif', bg: Color(0xFFD6F0EC), fg: AppColors.tealDark),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 16)),
          const StatusChip('Diblokir', bg: Color(0xFFFBE3E3), fg: AppColors.danger),
        ]),
        const SizedBox(height: 14),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Alasan pemblokiran (wajib)',
                style: AppText.body(12.5, weight: FontWeight.w700))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: 3,
          onChanged: (_) => setS(() => error = null),
          style: AppText.body(14),
          decoration: InputDecoration(
            hintText: 'Contoh: meminjamkan akun ke orang lain',
            errorText: error,
            filled: true,
            fillColor: const Color(0xFFF1F4F4),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Alasan dicatat di Log Aktivitas beserta waktu.',
              style: AppText.body(11.5, color: AppColors.muted)),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFBE3E3), borderRadius: BorderRadius.circular(14)),
          child: Text(
              'Member tidak bisa check-in atau booking kelas sampai blokir dibuka.',
              style: AppText.body(12.5, color: AppColors.danger)),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child: PrimaryButton('Batal',
                  outlined: true, onPressed: () => Navigator.pop(ctx))),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton('Ya, blokir', color: AppColors.danger, onPressed: () {
              final err = ctx.read<AppState>().blockMember(u.id, ctrl.text);
              if (err != null) {
                setS(() => error = err);
                return;
              }
              Navigator.pop(ctx);
              toast(context, '${u.name} diblokir');
            }),
          ),
        ]),
      ]);
    });
  });
}

/// Sheet "Buka blokir member ini?" — catatan opsional.
Future<void> showUnblockSheet(BuildContext context, AppUser u) {
  final rec = context.read<AppState>().activeBlockOf(u.id);
  final ctrl = TextEditingController();
  return showAppSheet<void>(context, (ctx) {
    return _sheetShell(ctx, [
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Buka blokir member ini?', style: AppText.heading(20))),
      const SizedBox(height: 14),
      Row(children: [
        MemberAvatar(u, size: 44, status: MemberStatus.blocked),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.name, style: AppText.body(15, weight: FontWeight.w800)),
          Text(u.memberId, style: AppText.body(12, color: AppColors.muted)),
        ])),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Text('Status akun', style: AppText.body(12, color: AppColors.muted)),
        const SizedBox(width: 10),
        const StatusChip('Diblokir', bg: Color(0xFFFBE3E3), fg: AppColors.danger),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 16)),
        const StatusChip('Aktif', bg: Color(0xFFD6F0EC), fg: AppColors.tealDark),
      ]),
      if (rec != null) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFF1F4F4), borderRadius: BorderRadius.circular(14)),
          child: Text(
              'Alasan blokir: ${rec.reason}\nDiblokir ${fmtDate(rec.at)} oleh ${rec.by}',
              style: AppText.body(12.5)),
        ),
      ],
      const SizedBox(height: 14),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Catatan pembukaan (opsional)',
              style: AppText.body(12.5, weight: FontWeight.w700))),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: 2,
        style: AppText.body(14),
        decoration: InputDecoration(
          hintText: 'Contoh: sudah diberi peringatan',
          filled: true,
          fillColor: const Color(0xFFF1F4F4),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFD6F0EC), borderRadius: BorderRadius.circular(14)),
        child: Text(
            'Member bisa check-in dan booking kelas lagi. Pembekuan yang masih berlaku tidak ikut dibuka.',
            style: AppText.body(12.5, color: AppColors.tealDark)),
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
            child: PrimaryButton('Batal',
                outlined: true, onPressed: () => Navigator.pop(ctx))),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton('Ya, buka blokir', color: AppColors.teal, onPressed: () {
            final err = ctx.read<AppState>().unblockMember(u.id, ctrl.text);
            Navigator.pop(ctx);
            toast(context, err ?? 'Blokir ${u.name} dibuka');
          }),
        ),
      ]),
    ]);
  });
}

/// Memilih member yang belum diblokir (untuk tombol "+ Blokir member").
Future<AppUser?> pickMemberSheet(BuildContext context) {
  var q = '';
  return showAppSheet<AppUser>(context, (ctx) {
    return StatefulBuilder(builder: (ctx, setS) {
      final app = ctx.read<AppState>();
      final list = app.searchMembers(q).where((u) => !u.blocked).toList();
      return _sheetShell(ctx, [
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Pilih member', style: AppText.heading(20))),
        const SizedBox(height: 12),
        SearchBox(
            hint: 'Cari nama, email, atau ID member', onChanged: (v) => setS(() => q = v)),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
          child: list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Member tidak ditemukan',
                      style: AppText.body(13, color: AppColors.muted)))
              : ListView(shrinkWrap: true, children: [
                  for (final u in list)
                    ListTile(
                      leading: MemberAvatar(u, size: 38, status: app.statusOf(u)),
                      title: Text(u.name, style: AppText.body(14, weight: FontWeight.w700)),
                      subtitle: Text(u.memberId, style: AppText.body(12, color: AppColors.muted)),
                      onTap: () => Navigator.pop(ctx, u),
                    ),
                ]),
        ),
      ]);
    });
  });
}
