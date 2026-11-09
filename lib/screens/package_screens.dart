import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'receipt_screen.dart';
// ====================================================== Paket membership
class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});
  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  String _selectedId = '3m';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final m = app.membership;
    final active = app.hasActiveMembership;
    final plans = app.activePlans;
    final selectedPlan = plans.firstWhere((p) => p.id == _selectedId,
        orElse: () => plans.first);

    return Column(
      children: [
        const PageHeader('Paket Membership', showBack: false),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _statusCard(m, active),
              const SizedBox(height: 16),
              if (active) _detailCard(m!, app.currentUser!) else _benefitCard(),
              const SizedBox(height: 20),
              Text(active ? 'Perpanjang Paket' : 'Pilih Paket',
                  style: AppText.heading(18)),
              const SizedBox(height: 10),
              for (final p in plans)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanTile(
                    plan: p,
                    selected: selectedPlan.id == p.id,
                    onTap: () => setState(() => _selectedId = p.id),
                  ),
                ),
              const SizedBox(height: 10),
              PrimaryButton(
                '${active ? 'Perpanjang' : 'Beli'} ${selectedPlan.name}',
                onPressed: () {
                  context.read<AppState>().startCheckout(selectedPlan);
                  context.push('/payment');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusCard(Membership? m, bool active) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            colors: [Color(0xFF16A394), Color(0xFF0E7F74)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Premium', style: AppText.heading(26, color: Colors.white)),
              if (active && m != null)
                StatusChip(m.isFrozen ? 'DIBEKUKAN' : 'AKTIF',
                    bg: AppColors.lime, fg: AppColors.ink)
              else
                const StatusChip('Tidak Aktif', bg: Colors.white24, fg: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          if (active && m != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: m.progress,
                  minHeight: 10,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white)),
            ),
            const SizedBox(height: 10),
            Text('${m.remainingDays} dari ${m.totalDays} hari tersisa',
                style: AppText.body(13, color: Colors.white)),
          ] else
            Text('Pilih paket di bawah untuk mulai latihan',
                style: AppText.body(13, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _detailCard(Membership m, AppUser u) {
    Widget row(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(a, style: AppText.body(14, color: AppColors.muted)),
              Text(b, style: AppText.body(14, weight: FontWeight.w700)),
            ],
          ),
        );
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(children: [
        row('Mulai', fmtDate(m.start, 'd MMMM yyyy')),
        const Divider(height: 1),
        row('Berakhir', fmtDate(m.end)),
        const Divider(height: 1),
        row('Akses', 'Semua Kelas'),
        const Divider(height: 1),
        row('ID Member', u.memberId),
      ]),
    );
  }

  Widget _benefitCard() {
    Widget b(String t) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            const Icon(Icons.check_circle, color: AppColors.teal, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: AppText.body(13.5))),
          ]),
        );
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yang kamu dapat', style: AppText.heading(17)),
          b('Akses semua kelas'),
          b('Check-in cukup dengan wajah, tanpa kartu'),
          b('Target latihan dan streak'),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, required this.onTap});
  final PlanOption plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.teal : null,
      color: selected ? const Color(0xFFF0FBF9) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(plan.name, style: AppText.heading(17)),
                  if (plan.originalPrice != null) ...[
                    const SizedBox(width: 8),
                    const StatusChip('HEMAT', bg: AppColors.lime, fg: AppColors.ink),
                  ],
                ]),
                const SizedBox(height: 2),
                Text('${plan.days} hari',
                    style: AppText.body(12, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (plan.originalPrice != null)
                Text(rupiah(plan.originalPrice!),
                    style: AppText.body(11.5, color: AppColors.muted).copyWith(
                        decoration: TextDecoration.lineThrough)),
              Text(rupiah(plan.price), style: AppText.heading(16)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================ Pembayaran
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.pending;
    if (p == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go('/packages'));
      return const Scaffold();
    }

    const methods = [
      ('QRIS', 'Scan dari e-wallet atau m-bank', Icons.qr_code_2),
      ('Transfer Bank', 'Bayar lewat virtual account', Icons.account_balance),
      ('E-Wallet', 'Bayar lewat aplikasi e-wallet', Icons.account_balance_wallet_outlined),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader('Pembayaran'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF16A394), Color(0xFF0E7F74)]),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const StatusChip('Menunggu pembayaran',
                            bg: AppColors.lime, fg: AppColors.ink),
                        const SizedBox(height: 12),
                        Text('Premium ${p.plan.name}',
                            style: AppText.heading(22, color: Colors.white)),
                        Text('${p.plan.days} hari · Akses semua kelas',
                            style: AppText.body(13, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(children: [
                      _kv('Harga paket', rupiah(p.plan.price)),
                      if (p.discount > 0) ...[
                        const SizedBox(height: 10),
                        _kv('Diskon (${p.promoCode})', '- ${rupiah(p.discount)}',
                            color: AppColors.tealDark),
                      ],
                      const SizedBox(height: 10),
                      _kv('Masa aktif', '${p.plan.days} hari'),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1)),
                      _kv('Total bayar', rupiah(p.total), bold: true),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Text('Pilih metode pembayaran', style: AppText.heading(17)),
                  const SizedBox(height: 10),
                  for (final m in methods)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        onTap: () => context.read<AppState>().setPaymentMethod(m.$1),
                        borderColor: p.method == m.$1 ? AppColors.teal : null,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.tealSoft,
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(m.$3, color: AppColors.tealDark),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.$1,
                                    style: AppText.body(14.5, weight: FontWeight.w800)),
                                Text(m.$2,
                                    style: AppText.body(11.5, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Icon(
                              p.method == m.$1
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: p.method == m.$1
                                  ? AppColors.teal
                                  : Colors.black26),
                        ]),
                      ),
                    ),
                  AppCard(
                    onTap: () => _promoDialog(context),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.promoCode == null ? 'Punya kode promo?' : 'Promo ${p.promoCode} dipakai',
                            style: AppText.body(14, weight: FontWeight.w600)),
                        Text(p.promoCode == null ? 'Masukkan' : 'Ganti',
                            style: AppText.body(13,
                                weight: FontWeight.w700, color: AppColors.teal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                      'Setelah pembayaran berhasil, keanggotaan langsung aktif. Pembayaran yang sudah berhasil tidak dapat dibatalkan.',
                      style: AppText.body(11.5, color: AppColors.muted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: PrimaryButton('Bayar ${rupiah(p.total)}',
                  onPressed: () => context.push('/payment/pay')),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _kv(String a, String b, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(a, style: AppText.body(14, color: bold ? AppColors.ink : AppColors.muted,
            weight: bold ? FontWeight.w700 : FontWeight.w400)),
        Text(b,
            style: bold
                ? AppText.heading(18)
                : AppText.body(14, weight: FontWeight.w700, color: color ?? AppColors.ink)),
      ],
    );
  }

  Future<void> _promoDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Kode promo', style: AppText.heading(18)),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'Contoh: GYMKU20'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Pakai')),
        ],
      ),
    );
    if (code == null || !context.mounted) return;
    final err = context.read<AppState>().applyPromo(code);
    toast(context, err ?? 'Kode promo diterapkan');
  }
}

// ======================================================= Instruksi bayar
class PaymentInstructionScreen extends StatefulWidget {
  const PaymentInstructionScreen({super.key});
  @override
  State<PaymentInstructionScreen> createState() => _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState extends State<PaymentInstructionScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.pending;
    if (p == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go('/packages'));
      return const Scaffold();
    }
    final left = p.expiresAt.difference(DateTime.now());
    final expired = left.isNegative;
    final mm = left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    final user = app.currentUser!;
    final va = '8808${user.memberId.replaceAll(RegExp(r'\D'), '')}${p.trxId.replaceAll(RegExp(r'\D'), '')}';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader('Pembayaran ${p.method}'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        StatusChip(expired ? 'Kedaluwarsa' : 'Menunggu pembayaran',
                            bg: expired ? const Color(0xFFFBE3E3) : AppColors.tealSoft,
                            fg: expired ? AppColors.danger : AppColors.tealDark),
                        const SizedBox(height: 12),
                        Text('Total bayar', style: AppText.body(13, color: AppColors.muted)),
                        Text(rupiah(p.total), style: AppText.heading(30)),
                        const SizedBox(height: 16),
                        if (p.method == 'QRIS')
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.field, width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Opacity(
                              opacity: expired ? 0.25 : 1,
                              // Di produksi: data QRIS dinamis dari payment gateway.
                              child: QrImageView(
                                  data: 'GYMKU|${p.trxId}|${p.total}',
                                  size: 190),
                            ),
                          )
                        else if (p.method == 'Transfer Bank') ...[
                          Text('Nomor virtual account', style: AppText.body(12, color: AppColors.muted)),
                          const SizedBox(height: 6),
                          SelectableText(va, style: AppText.heading(22)),
                        ] else ...[
                          const Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.tealDark),
                          const SizedBox(height: 8),
                          Text('Buka aplikasi e-wallet kamu dan masukkan kode',
                              textAlign: TextAlign.center,
                              style: AppText.body(13, color: AppColors.muted)),
                          SelectableText(p.trxId, style: AppText.heading(22)),
                        ],
                        const SizedBox(height: 14),
                        Text('GYMKU · Premium ${p.plan.name}',
                            style: AppText.body(12.5, color: AppColors.muted)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                              color: expired ? const Color(0xFFFBE3E3) : const Color(0xFFFFF4D6),
                              borderRadius: BorderRadius.circular(100)),
                          child: Text(
                              expired ? 'Waktu pembayaran habis' : 'Selesaikan dalam $mm:$ss',
                              style: AppText.body(12.5, weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Cara bayar', style: AppText.heading(17)),
                  const SizedBox(height: 10),
                  for (final (i, s) in [
                    'Buka e-wallet atau m-banking',
                    p.method == 'QRIS' ? 'Scan QR di atas' : 'Masukkan nomor / kode di atas',
                    'Konfirmasi pembayaran',
                  ].indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.tealSoft,
                            child: Text('${i + 1}',
                                style: AppText.body(12, weight: FontWeight.w800, color: AppColors.tealDark))),
                        const SizedBox(width: 12),
                        Text(s, style: AppText.body(14)),
                      ]),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: Column(
                children: [
                  if (expired)
                    PrimaryButton('Buat ulang pembayaran',
                        onPressed: () => context.read<AppState>().refreshExpiry())
                  else
                    // SIMULASI. Di produksi tombol ini dihapus; status berubah
                    // otomatis setelah webhook payment gateway diterima.
                    PrimaryButton('Saya sudah bayar (simulasi)', onPressed: () {
                      final err = context.read<AppState>().confirmPayment();
                      if (err != null) {
                        toast(context, err);
                      } else {
                        context.go('/payment/success');
                      }
                    }),
                  const SizedBox(height: 10),
                  PrimaryButton('Ganti metode pembayaran',
                      outlined: true,
                      color: AppColors.ink,
                      onPressed: () => context.pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================= Pembayaran sukses
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = app.lastTxn;
    Widget row(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(a, style: AppText.body(13, color: AppColors.muted)),
              Text(b, style: AppText.body(13.5, weight: FontWeight.w700)),
            ],
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          children: [
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                    color: AppColors.tealSoft, shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 94,
                    height: 94,
                    decoration: const BoxDecoration(
                        color: AppColors.teal, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 54),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('Pembayaran berhasil',
                textAlign: TextAlign.center, style: AppText.heading(25)),
            const SizedBox(height: 8),
            Text('Membership Premium kamu sudah aktif. Selamat latihan!',
                textAlign: TextAlign.center,
                style: AppText.body(13.5, color: AppColors.muted)),
            const SizedBox(height: 24),
            if (t != null)
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  row('Paket', t.planName),
                  row('Metode', t.method),
                  row('Tanggal', fmtDate(t.at)),
                  row('ID Transaksi', t.id),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total bayar', style: AppText.body(14, weight: FontWeight.w700)),
                      Text(rupiah(t.amount), style: AppText.heading(18)),
                    ],
                  ),
                ]),
              ),
            const SizedBox(height: 14),
            AppCard(
              color: const Color(0xFFF0FBF9),
              child: Text(
                  'Foto wajah cukup sekali. Setelah terdaftar, check-in tinggal scan wajah tanpa kartu.',
                  style: AppText.body(12.5, color: AppColors.tealDark)),
            ),
            const SizedBox(height: 24),
            if (t != null) ...[
              PrimaryButton('Lihat struk',
                  icon: Icons.receipt_long_outlined,
                  outlined: true,
                  color: AppColors.teal,
                  onPressed: () => ReceiptScreen.open(context, t)),
              const SizedBox(height: 10),
            ],
            PrimaryButton('Daftarkan wajah',
                color: AppColors.teal,
                onPressed: () => context.push('/face/enroll')),
            const SizedBox(height: 10),
            PrimaryButton('Beranda',
                outlined: true,
                color: AppColors.ink,
                onPressed: () => context.go('/home')),
          ],
        ),
      ),
    );
  }
}
