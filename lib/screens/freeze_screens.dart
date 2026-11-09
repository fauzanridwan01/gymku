import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
const _reasons = ['Sakit atau cedera', 'Bepergian', 'Urusan pribadi', 'Lainnya'];

class _FreezeHeader extends StatelessWidget {
  const _FreezeHeader(this.title, this.subtitle);
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x1F000000), blurRadius: 8)]),
            child: const Icon(Icons.chevron_left, size: 28),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.heading(22)),
              if (subtitle != null)
                Text(subtitle!, style: AppText.body(12, color: AppColors.muted)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ============================================================ Bekukan member
class FreezeScreen extends StatefulWidget {
  const FreezeScreen({super.key});
  @override
  State<FreezeScreen> createState() => _FreezeScreenState();
}

class _FreezeScreenState extends State<FreezeScreen> {
  int _days = 14;
  DateTime _start = today();
  String _reason = _reasons.first;

  DateTime get _end => _start.add(Duration(days: _days - 1));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final m = app.membership;
    final pending = app.pendingFreezeRequest;

    if (m == null || !m.isActive) {
      return Scaffold(
        body: SafeArea(
          child: Column(children: [
            const _FreezeHeader('Bekukan Member', null),
            Expanded(
              child: Center(
                child: Text('Fitur ini hanya untuk member aktif',
                    style: AppText.body(14, color: AppColors.muted)),
              ),
            ),
          ]),
        ),
      );
    }

    if (pending != null) {
      return Scaffold(
        body: SafeArea(
          child: Column(children: [
            const _FreezeHeader('Permintaan Pembekuan', null),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hourglass_top,
                            color: Color(0xFFB26A00), size: 44),
                        const SizedBox(height: 12),
                        Text('Menunggu persetujuan admin',
                            style: AppText.heading(18),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(
                          'Permintaan pembekuan ${pending.days} hari mulai '
                          '${fmtDate(pending.since)} sedang ditinjau. '
                          'Membership tetap aktif sampai admin menyetujui.',
                          style: AppText.body(13, color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text('Alasan: ${pending.reason}',
                            style: AppText.body(12.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: PrimaryButton('Kembali', onPressed: () => context.pop()),
            ),
          ]),
        ),
      );
    }

    final available = m.freezeDaysAvailable;
    final newEnd = m.end.add(Duration(days: _days));

    Widget kv(String a, String b, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(a, style: AppText.body(13, color: AppColors.muted)),
              Text(b, style: AppText.body(13.5, weight: FontWeight.w800, color: color ?? AppColors.ink)),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _FreezeHeader('Bekukan Member', 'Jeda paketmu tanpa kehilangan sisa hari'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            color: const Color(0xFFD7EEF8),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.ac_unit, color: Color(0xFF1E5870)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Premium', style: AppText.heading(17)),
                            Text('Sisa paket ${m.remainingDays} hari · berlaku s.d. ${fmtDate(m.end)}',
                                style: AppText.body(12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text('Lama pembekuan', style: AppText.body(13, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (final d in [7, 14, 21, 30])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: d == 30 ? 0 : 8),
                          child: GestureDetector(
                            onTap: d > available
                                ? () => toast(context, 'Sisa jatah beku hanya $available hari')
                                : () => setState(() => _days = d),
                            child: Container(
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _days == d
                                    ? AppColors.teal
                                    : d > available
                                        ? Colors.black12
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: _days == d ? AppColors.teal : const Color(0xFFDDE5E4)),
                              ),
                              child: Text('$d hari',
                                  style: AppText.body(13,
                                      weight: FontWeight.w700,
                                      color: _days == d
                                          ? Colors.white
                                          : d > available
                                              ? Colors.black38
                                              : AppColors.ink)),
                            ),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 18),
                  Text('Mulai dibekukan', style: AppText.body(13, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  AppCard(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate: today(),
                        lastDate: today().add(const Duration(days: 14)),
                        locale: const Locale('id', 'ID'),
                      );
                      if (d != null) setState(() => _start = dateOnly(d));
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fmtDate(_start, 'EEEE, d MMM yyyy'), style: AppText.body(14)),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Alasan', style: AppText.body(13, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _reason,
                        isExpanded: true,
                        style: AppText.body(14),
                        items: [
                          for (final r in _reasons) DropdownMenuItem(value: r, child: Text(r)),
                        ],
                        onChanged: (v) => setState(() => _reason = v ?? _reason),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      kv('Masa beku yang diminta', '${fmtDate(_start, 'd MMM')} – ${fmtDate(_end)}'),
                      kv('Paket aktif lagi jika disetujui', fmtDate(_end.add(const Duration(days: 1)))),
                      kv('Berlaku s.d. jika disetujui', fmtDate(newEnd)),
                      kv('Biaya', 'Gratis', color: AppColors.tealDark),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => _terms(context, available),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: 'Maksimal ${Membership.maxFreezeDays} hari per paket · ',
                            style: AppText.body(12, color: AppColors.muted)),
                        TextSpan(
                            text: 'Lihat ketentuan',
                            style: AppText.body(12, weight: FontWeight.w700, color: AppColors.teal)),
                      ])),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PrimaryButton('Ajukan ke Admin',
                  onPressed: available == 0 ? null : () => _confirm(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _terms(BuildContext context, int available) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ketentuan pembekuan', style: AppText.heading(18)),
        content: Text(
            '• Maksimal ${Membership.maxFreezeDays} hari per paket (sisa jatahmu: $available hari)\n'
            '• Pembekuan berlaku setelah disetujui admin\n'
            '• Selama beku: check-in & booking kelas dinonaktifkan\n'
            '• Booking kelas dalam masa beku dibatalkan otomatis setelah disetujui\n'
            '• Masa aktif otomatis mundur sebanyak hari beku\n'
            '• Pengaktifan lebih awal juga memerlukan persetujuan admin\n'
            '• Gratis',
            style: AppText.body(13)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final app = context.read<AppState>();
    final affected = app.bookingsAffectedByFreeze(_start, _days);
    bool agreed = false;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 42, height: 4,
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 18),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Color(0xFFD7EEF8), shape: BoxShape.circle),
                    child: const Icon(Icons.ac_unit, color: Color(0xFF1E5870), size: 30),
                  ),
                  const SizedBox(height: 14),
                  Text('Ajukan pembekuan $_days hari?', style: AppText.heading(20), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                      'Mulai ${fmtDate(_start, 'd MMM')} sampai ${fmtDate(_end)}. '
                      'Membership hanya dibekukan setelah admin menyetujui permintaan ini.',
                      textAlign: TextAlign.center,
                      style: AppText.body(13, color: AppColors.muted)),
                  const SizedBox(height: 14),
                  AppCard(
                    color: const Color(0xFFFFF7E0),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _warn('Jika disetujui, check-in dan booking kelas dinonaktifkan selama beku'),
                        for (final c in affected)
                          _warn('Jika disetujui, booking kelas (${c.title}, ${fmtTime(c.start)}) dibatalkan otomatis'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => setS(() => agreed = !agreed),
                    child: Row(children: [
                      Checkbox(
                        value: agreed,
                        activeColor: AppColors.teal,
                        onChanged: (v) => setS(() => agreed = v ?? false),
                      ),
                      Expanded(
                          child: Text('Saya paham dan setuju dengan ketentuan pembekuan',
                              style: AppText.body(12.5))),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton('Kirim permintaan',
                      onPressed: agreed ? () => Navigator.pop(ctx, true) : null),
                  const SizedBox(height: 10),
                  PrimaryButton('Batal',
                      outlined: true, color: AppColors.muted, onPressed: () => Navigator.pop(ctx, false)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (ok != true || !context.mounted) return;
    final err = context
        .read<AppState>()
        .requestFreezeMembership(_start, _days, _reason);
    if (err != null) return toast(context, err);
    toast(context, 'Permintaan pembekuan dikirim. Menunggu persetujuan admin.');
    context.go('/home');
  }

  Widget _warn(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB7791F)),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: AppText.body(12.5))),
        ]),
      );
}

// ============================================================ Status beku
class FreezeStatusScreen extends StatelessWidget {
  const FreezeStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final m = app.membership;
    final f = m?.currentFreeze;
    final pending = app.pendingFreezeRequest;
    if (m == null || f == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold();
    }
    final scheduled = m.isFreezeScheduled;
    final pendingUnfreeze = pending?.type == FreezeRequestType.unfreeze;
    final unused = scheduled ? f.length : m.freezeDaysLeft;
    final endAfter = m.end.subtract(Duration(days: unused));

    Widget kv(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(a, style: AppText.body(13.5, color: AppColors.muted)),
              Text(b, style: AppText.body(13.5, weight: FontWeight.w800)),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _FreezeHeader(scheduled ? 'Pembekuan Dijadwalkan' : 'Status Pembekuan', null),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF5E7A8A), Color(0xFF3F5663)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusChip(scheduled ? 'DIJADWALKAN' : 'DIBEKUKAN',
                                bg: const Color(0xFFBFE3F5), fg: const Color(0xFF1E5870)),
                            Text('Premium', style: AppText.body(13, weight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(scheduled ? 'Lama pembekuan' : 'Sisa masa beku',
                            style: AppText.body(13, color: Colors.white70)),
                        Text(scheduled ? '${f.length} hari' : '${m.freezeDaysLeft} hari',
                            style: AppText.heading(34, color: Colors.white)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: scheduled ? 1 : (m.freezeDaysLeft / (f.length == 0 ? 1 : f.length)),
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFBFE3F5)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Mulai', style: AppText.body(12, color: Colors.white70)),
                              Text(fmtDate(f.start), style: AppText.body(14, weight: FontWeight.w700, color: Colors.white)),
                            ]),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('Selesai', style: AppText.body(12, color: Colors.white70)),
                              Text(fmtDate(f.end), style: AppText.body(14, weight: FontWeight.w700, color: Colors.white)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Column(children: [
                      kv('Alasan', f.reason),
                      const Divider(height: 1),
                      kv('Sisa paket (tetap)', '${m.remainingDays} hari'),
                      const Divider(height: 1),
                      kv('Aktif kembali otomatis', fmtDate(f.end.add(const Duration(days: 1)))),
                      const Divider(height: 1),
                      kv('Berlaku s.d. jadi', fmtDate(m.end)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    color: const Color(0xFFFFF7E0),
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFB7791F)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text('Selama dibekukan kamu belum bisa check-in atau booking kelas.',
                              style: AppText.body(12.5))),
                    ]),
                  ),
                  if (pendingUnfreeze) ...[
                    const SizedBox(height: 14),
                    AppCard(
                      color: const Color(0xFFFFF3D6),
                      child: Row(children: [
                        const Icon(Icons.hourglass_top,
                            color: Color(0xFFB26A00)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Permintaan untuk ${scheduled ? 'membatalkan pembekuan' : 'mengaktifkan membership'} sedang menunggu persetujuan admin.',
                            style: AppText.body(12.5),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(children: [
                PrimaryButton(
                  pendingUnfreeze
                      ? 'Menunggu persetujuan admin'
                      : scheduled
                          ? 'Ajukan pembatalan'
                          : 'Ajukan aktifkan kembali',
                  icon: scheduled ? Icons.close : Icons.play_arrow_rounded,
                  onPressed: pendingUnfreeze
                      ? null
                      : () => _activate(
                          context, scheduled, unused, endAfter),
                ),
                const SizedBox(height: 10),
                PrimaryButton('Kembali', outlined: true, color: AppColors.ink, onPressed: () => context.pop()),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activate(
      BuildContext context, bool scheduled, int unused, DateTime endAfter) async {
    final ok = await confirmSheet(
      context,
      title: scheduled ? 'Batalkan pembekuan?' : 'Aktifkan paket sekarang?',
      message: scheduled
          ? 'Permintaan pembatalan pembekuan akan dikirim ke admin. Jadwal hanya dibatalkan setelah disetujui.'
          : 'Permintaan pengaktifan akan dikirim ke admin. Jika disetujui, sisa $unused hari masa beku dikembalikan dan masa aktif berakhir ${fmtDate(endAfter)}.',
      confirmLabel: 'Kirim permintaan',
      cancelLabel: scheduled ? 'Tidak' : 'Tetap dibekukan',
    );
    if (!ok || !context.mounted) return;
    final err = context.read<AppState>().requestUnfreezeMembership();
    if (err != null) return toast(context, err);
    toast(context, 'Permintaan dikirim. Menunggu persetujuan admin.');
    context.go('/home');
  }
}
