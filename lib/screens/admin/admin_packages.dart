import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';
import 'admin_info.dart';

String promoDescription(Promo p, AppState app) {
  final names = app.plans.where((e) => p.planIds.contains(e.id)).map((e) => e.name).join(', ');
  return 'Untuk $names${p.renewalOnly ? ' · hanya perpanjangan' : ' · semua pembelian'}';
}

class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});
  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const AdminHeader('Paket & Promo', subtitle: 'Kelola harga dan penawaran'),
        Segmented(labels: const ['Paket', 'Promo', 'Informasi'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: 14),
        if (_tab == 0)
          ..._plans(context, app)
        else if (_tab == 1)
          ..._promos(context, app)
        else
          const AdminInfoSection(),
      ],
    );
  }

  List<Widget> _plans(BuildContext context, AppState app) => [
        Text('Harga di sini langsung dipakai di halaman paket membership member.',
            style: AppText.body(12, color: AppColors.tealDark)),
        const SizedBox(height: 12),
        for (final p in app.plans)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Builder(builder: (context) {
              final promo = app.promoFor(p, true);
              return AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(p.name, style: AppText.heading(17)),
                    if (p.id == '3m') ...[
                      const SizedBox(width: 8),
                      const StatusChip('TERPOPULER', bg: AppColors.lime, fg: AppColors.ink),
                    ],
                    const Spacer(),
                    Switch(
                      value: p.enabled,
                      activeColor: AppColors.tealDark,
                      onChanged: (v) {
                        final err = context.read<AppState>().setPlanEnabled(p.id, v);
                        if (err != null) toast(context, err);
                      },
                    ),
                  ]),
                  Text('${p.days} Hari', style: AppText.body(12, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(rupiah(p.price),
                            style: AppText.heading(20,
                                color: p.enabled ? AppColors.tealDark : AppColors.muted)),
                        if (promo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: StatusChip(
                                'Promo -${promo.valueLabel}  ${rupiah(p.price - promo.discountFor(p.price))}'),
                          ),
                      ]),
                    ),
                    TextButton(
                      onPressed: () => _priceSheet(context, p),
                      style: TextButton.styleFrom(
                          backgroundColor: AppColors.tealSoft,
                          foregroundColor: AppColors.tealDark,
                          padding: const EdgeInsets.symmetric(horizontal: 16)),
                      child: const Text('Ubah harga'),
                    ),
                  ]),
                ]),
              );
            }),
          ),
      ];

  List<Widget> _promos(BuildContext context, AppState app) {
    final running = app.promos.where((p) => p.isRunning).toList();
    final others = app.promos.where((p) => !p.isRunning).toList();
    return [
      Row(children: [
        Expanded(
          child: Text('Diskon terpotong otomatis saat member membayar, tanpa kode.',
              style: AppText.body(12, color: AppColors.muted)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => context.push('/admin/promo'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('+ Buat Promo'),
        ),
      ]),
      const SizedBox(height: 16),
      Text('Sedang berjalan', style: AppText.heading(16)),
      const SizedBox(height: 8),
      if (running.isEmpty)
        Text('Tidak ada promo yang berjalan.', style: AppText.body(13, color: AppColors.muted)),
      for (final p in running)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(22)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const StatusChip('AKTIF', bg: AppColors.lime, fg: AppColors.ink),
                const Spacer(),
                Text('${fmtDate(p.start, 'd')}-${fmtDate(p.end, 'd MMM yyyy')}',
                    style: AppText.body(11.5, color: Colors.white70)),
              ]),
              const SizedBox(height: 10),
              Text(p.name, style: AppText.heading(17, color: Colors.white)),
              const SizedBox(height: 4),
              Text(promoDescription(p, app), style: AppText.body(11.5, color: Colors.white70)),
              Text('Dipakai ${p.used} dari ${p.quota} kuota',
                  style: AppText.body(11.5, color: Colors.white70)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: (p.used / p.quota).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    color: AppColors.lime),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final ok = await confirmSheet(context,
                          title: 'Akhiri promo ini?',
                          message: 'Promo "${p.name}" berhenti berlaku sekarang. Diskon tidak lagi dipotong saat pembayaran.',
                          confirmLabel: 'Ya, akhiri',
                          danger: true);
                      if (ok && context.mounted) {
                        context.read<AppState>().endPromo(p.id);
                        toast(context, 'Promo diakhiri');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)),
                    child: const Text('Akhiri promo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/admin/promo', extra: p),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: AppColors.ink),
                    child: const Text('Ubah'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      const SizedBox(height: 6),
      Text('Terjadwal dan selesai', style: AppText.heading(16)),
      const SizedBox(height: 8),
      if (others.isEmpty)
        Text('Belum ada.', style: AppText.body(13, color: AppColors.muted)),
      for (final p in others)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                p.isScheduled
                    ? const StatusChip('Terjadwal', bg: Color(0xFFDCEBFF), fg: Color(0xFF2B6CB0))
                    : const StatusChip('Selesai', bg: Color(0xFFE5E5E5), fg: AppColors.muted),
                const Spacer(),
                Text('${fmtDate(p.start, 'd MMM')} – ${fmtDate(p.end, 'd MMM yyyy')}',
                    style: AppText.body(11.5, color: AppColors.muted)),
              ]),
              const SizedBox(height: 8),
              Text(p.name, style: AppText.body(14.5, weight: FontWeight.w800)),
              Text(promoDescription(p, app), style: AppText.body(11.5, color: AppColors.muted)),
              Text('Kuota ${p.quota} · terpakai ${p.used}',
                  style: AppText.body(11.5, color: AppColors.muted)),
              const SizedBox(height: 8),
              Row(children: [
                if (p.isScheduled)
                  Switch(
                    value: p.enabled,
                    activeColor: AppColors.tealDark,
                    onChanged: (v) => context.read<AppState>().setPromoEnabled(p.id, v),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/admin/promo', extra: p),
                  style: TextButton.styleFrom(
                      backgroundColor: AppColors.tealSoft, foregroundColor: AppColors.tealDark),
                  child: const Text('Ubah'),
                ),
              ]),
            ]),
          ),
        ),
    ];
  }

  void _priceSheet(BuildContext context, PlanOption p) {
    final ctrl = TextEditingController(text: '${p.price}');
    String? error;
    showAppSheet<void>(context, (ctx) {
      return StatefulBuilder(builder: (ctx, setS) {
        final app = ctx.read<AppState>();
        final v = int.tryParse(ctrl.text.trim()) ?? 0;
        final months = (p.days / 30).round();
        final promo = app.promoFor(p, true);
        return Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22, 22 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ubah harga paket', style: AppText.heading(20)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${p.name}  ·  ${p.days} Hari', style: AppText.body(14, weight: FontWeight.w700)),
                Text('Harga sekarang ${rupiah(p.price)}',
                    style: AppText.body(12, color: AppColors.muted)),
              ]),
              const SizedBox(height: 14),
              Text('Harga baru (Rp)', style: AppText.body(12.5, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setS(() => error = null),
                style: AppText.body(15),
                decoration: InputDecoration(
                  errorText: error,
                  filled: true,
                  fillColor: const Color(0xFFF1F4F4),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 6),
              if (v > 0 && months > 0)
                Text('≈ ${rupiah((v / months).round())} per bulan',
                    style: AppText.body(11.5, color: AppColors.muted)),
              if (promo != null && v > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)),
                  child: Text(
                      'Dengan promo aktif (-${promo.valueLabel}), member membayar ${rupiah(v - promo.discountFor(v))}. Potongan dihitung otomatis dari harga baru.',
                      style: AppText.body(12, color: AppColors.tealDark)),
                ),
              ],
              const SizedBox(height: 10),
              Text('Berlaku untuk pembelian berikutnya. Paket member yang sedang aktif tidak berubah. Perubahan dicatat di Log Aktivitas.',
                  style: AppText.body(11.5, color: AppColors.muted)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: PrimaryButton('Batal', outlined: true, onPressed: () => Navigator.pop(ctx))),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton('Simpan', onPressed: () {
                    final err = ctx.read<AppState>().updatePlanPrice(p.id, v);
                    if (err != null) {
                      setS(() => error = err);
                      return;
                    }
                    Navigator.pop(ctx);
                    toast(context, 'Harga ${p.name} diubah menjadi ${rupiah(v)}');
                  }),
                ),
              ]),
            ]),
          ),
        );
      });
    });
  }
}

// ============================================================== Form promo
class PromoFormScreen extends StatefulWidget {
  const PromoFormScreen({super.key, this.editing});
  final Promo? editing;
  @override
  State<PromoFormScreen> createState() => _PromoFormScreenState();
}

class _PromoFormScreenState extends State<PromoFormScreen> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _value = TextEditingController(
      text: widget.editing == null ? '' : '${widget.editing!.value}');
  late final _quota = TextEditingController(
      text: widget.editing == null ? '' : '${widget.editing!.quota}');
  late PromoType _type = widget.editing?.type ?? PromoType.percent;
  late Set<String> _plans = {...?widget.editing?.planIds};
  late bool _renewalOnly = widget.editing?.renewalOnly ?? false;
  late DateTime _start = widget.editing?.start ?? today();
  late DateTime _end = widget.editing?.end ?? today().add(const Duration(days: 30));
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _quota.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final d = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => start ? _start = d : _end = d);
  }

  void _save() {
    final app = context.read<AppState>();
    final e = widget.editing;
    // Validasi pada salinan dulu supaya data asli tidak berubah bila gagal.
    final draft = Promo(
      id: e?.id ?? app.newPromoId(),
      name: _name.text.trim(),
      type: _type,
      value: int.tryParse(_value.text.trim()) ?? 0,
      quota: int.tryParse(_quota.text.trim()) ?? 0,
      planIds: {..._plans},
      renewalOnly: _renewalOnly,
      start: _start,
      end: _end,
    );
    final err = app.validatePromo(draft);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (e == null) {
      app.addPromo(draft);
    } else {
      e
        ..name = draft.name
        ..type = draft.type
        ..value = draft.value
        ..quota = draft.quota
        ..planIds = draft.planIds
        ..renewalOnly = draft.renewalOnly
        ..start = draft.start
        ..end = draft.end;
      app.updatePromo(e);
    }
    toast(context, e == null ? 'Promo disimpan dan diaktifkan' : 'Promo diperbarui');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final value = int.tryParse(_value.text.trim()) ?? 0;
    final prevPlan = app.plans.where((p) => _plans.contains(p.id)).firstOrNull;
    final prevDisc = prevPlan == null
        ? 0
        : (_type == PromoType.percent
            ? (prevPlan.price * value.clamp(0, 100) / 100).round()
            : value.clamp(0, prevPlan.price));

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 12),
          child: Text(t, style: AppText.body(12.5, weight: FontWeight.w700)),
        );

    InputDecoration deco([String? hint]) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        );

    Widget dateBox(String t, DateTime d, bool start) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            label(t),
            InkWell(
              onTap: () => _pick(start),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Text(fmtDate(d), style: AppText.body(14)),
              ),
            ),
          ]),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          AdminHeader(widget.editing == null ? 'Buat Promo' : 'Ubah Promo',
              subtitle: 'Kelola harga dan penawaran', showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                label('Nama Promo'),
                TextField(controller: _name, decoration: deco('Perpanjang member, diskon 20%')),
                label('Jenis diskon'),
                Segmented(
                    labels: const ['Persen (%)', 'Nominal (Rp)'],
                    index: _type == PromoType.percent ? 0 : 1,
                    onChanged: (i) => setState(
                        () => _type = i == 0 ? PromoType.percent : PromoType.nominal)),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      label('Nilai diskon'),
                      TextField(
                        controller: _value,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() => _error = null),
                        decoration: deco(_type == PromoType.percent ? '20' : '100000'),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      label('Kuota promo'),
                      TextField(
                        controller: _quota,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: deco('100'),
                      ),
                    ]),
                  ),
                ]),
                label('Berlaku untuk paket'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in app.plans)
                    PillChip(p.name,
                        selected: _plans.contains(p.id),
                        onTap: () => setState(() {
                              _plans.contains(p.id) ? _plans.remove(p.id) : _plans.add(p.id);
                              _error = null;
                            })),
                ]),
                label('Syarat pembelian'),
                Segmented(
                    labels: const ['Semua Pembelian', 'Hanya perpanjangan'],
                    index: _renewalOnly ? 1 : 0,
                    onChanged: (i) => setState(() => _renewalOnly = i == 1)),
                Row(children: [
                  dateBox('Mulai', _start, true),
                  const SizedBox(width: 12),
                  dateBox('Selesai', _end, false),
                ]),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pratinjau di pembayaran member', style: AppText.body(12, weight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (prevPlan == null)
                      Text('Pilih minimal satu paket untuk melihat pratinjau.',
                          style: AppText.body(12, color: AppColors.muted))
                    else ...[
                      _pv('Paket ${prevPlan.name}', rupiah(prevPlan.price)),
                      _pv('Promo', '- ${rupiah(prevDisc)}', color: AppColors.tealDark),
                      const Divider(height: 18),
                      _pv('Total bayar', rupiah(prevPlan.price - prevDisc), bold: true),
                    ],
                    const SizedBox(height: 6),
                    Text('Terpotong otomatis, member tidak perlu memasukkan kode.',
                        style: AppText.body(11, color: AppColors.muted)),
                  ]),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: AppText.body(12.5, color: AppColors.danger)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(children: [
              Expanded(child: PrimaryButton('Batal', outlined: true, onPressed: () => context.pop())),
              const SizedBox(width: 12),
              Expanded(
                  child: PrimaryButton('Simpan dan aktifkan',
                      color: AppColors.tealDark, onPressed: _save)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _pv(String a, String b, {Color? color, bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: AppText.body(12.5, color: AppColors.muted)),
          Text(b,
              style: AppText.body(bold ? 15 : 13,
                  weight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? AppColors.ink)),
        ]),
      );
}
