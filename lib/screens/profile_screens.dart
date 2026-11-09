import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'receipt_screen.dart';
// ===================================================================== Profil
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.currentUser!;
    final m = app.membership;
    final active = app.hasActiveMembership;

    Widget stat(String label, String value, String unit) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body(11.5, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: AppText.heading(24)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(unit, style: AppText.body(12, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

    Widget menu(IconData icon, String label, VoidCallback onTap,
            {bool danger = false}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                    color: danger ? const Color(0xFFFBE3E3) : AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: danger ? AppColors.danger : AppColors.tealDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(label,
                      style: AppText.body(15,
                          weight: FontWeight.w700,
                          color: danger ? AppColors.danger : AppColors.ink))),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ]),
          ),
        );

    return Column(
      children: [
        const PageHeader('Profil', showBack: false),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFFBFEAE5)),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.navy,
                    child: Text(u.initials, style: AppText.heading(30, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(child: Text(u.name, style: AppText.heading(24))),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (active) ...[
                    const StatusChip('PREMIUM', bg: AppColors.lime, fg: AppColors.ink),
                    const SizedBox(width: 10),
                  ],
                  Text(u.memberId, style: AppText.body(13, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 20),
              Row(children: [
                stat('Kunjungan', '${app.visitsThisMonth}', 'x'),
                const SizedBox(width: 10),
                stat('Streak', '${app.currentStreakWeeks}', 'Minggu'),
                const SizedBox(width: 10),
                stat('Sisa Paket', '${active ? m!.remainingDays : 0}', 'Hari'),
              ]),
              const SizedBox(height: 20),
              menu(Icons.person_outline, 'Data Diri', () => context.go('/profile/data')),
              menu(Icons.credit_card, 'Riwayat Pembayaran', () => context.go('/profile/payments')),
              menu(Icons.history, 'Riwayat Check-in', () => context.go('/profile/checkins')),
              menu(Icons.face_retouching_natural,
                  u.hasFace ? 'Perbarui Foto Wajah' : 'Daftarkan Wajah',
                  () => context.push('/face/enroll')),
              menu(Icons.lock_open_outlined, 'Ganti Password', () => context.go('/profile/password')),
              menu(Icons.logout, 'Keluar Akun', () async {
                final ok = await confirmSheet(context,
                    title: 'Keluar dari akun?',
                    message: 'Kamu perlu login lagi untuk memakai aplikasi.',
                    confirmLabel: 'Ya, keluar',
                    danger: true);
                if (ok && context.mounted) context.read<AppState>().logout();
              }, danger: true),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================== Data diri
class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});
  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  late final AppUser _u = context.read<AppState>().currentUser!;
  late final _name = TextEditingController(text: _u.name);
  late final _email = TextEditingController(text: _u.email);
  late final _phone = TextEditingController(text: _u.phone);
  late DateTime? _birth = _u.birthDate;
  late String _gender = _u.gender;
  late final _birthCtrl = TextEditingController(
      text: _u.birthDate == null ? '' : fmtDate(_u.birthDate!, 'd MMMM yyyy'));

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (d != null) {
      setState(() => _birth = d);
      _birthCtrl.text = fmtDate(d, 'd MMMM yyyy');
    }
  }

  void _save() {
    if (_name.text.trim().isEmpty) return toast(context, 'Nama wajib diisi');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      return toast(context, 'Format email tidak valid');
    }
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_phone.text.isNotEmpty && digits.length < 9) {
      return toast(context, 'Nomor HP tidak valid');
    }
    context.read<AppState>().updateProfile(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        birthDate: _birth,
        gender: _gender);
    toast(context, 'Perubahan disimpan');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader('Data Diri'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.navy,
                  child: Text(_u.initials, style: AppText.heading(28, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  LabeledField(label: 'Nama lengkap', controller: _name),
                  const SizedBox(height: 14),
                  LabeledField(label: 'Email', controller: _email, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  LabeledField(label: 'No HP', controller: _phone, keyboard: TextInputType.phone),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Tanggal lahir',
                    controller: _birthCtrl,
                    readOnly: true,
                    onTap: _pickDate,
                    suffix: const Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text('Jenis kelamin',
                            style: AppText.body(12, color: AppColors.muted)),
                      ),
                      Row(children: [
                        for (final g in ['Laki-laki', 'Perempuan'])
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: PillChip(g,
                                selected: _gender == g,
                                onTap: () => setState(() => _gender = g)),
                          ),
                      ]),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              PrimaryButton('Scan wajah',
                  icon: Icons.face_retouching_natural,
                  outlined: true,
                  color: AppColors.teal,
                  onPressed: () => toast(context, 'Pendaftaran wajah dikerjakan di tahap berikutnya')),
              const SizedBox(height: 12),
              PrimaryButton('Simpan Perubahan', onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================== Ganti password
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _hideOld = true, _hideNew = true, _hideConfirm = true;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Widget _eye(bool hidden, VoidCallback t) => IconButton(
      icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
      onPressed: t);

  @override
  Widget build(BuildContext context) {
    final pw = _new.text;
    final strength = AppState.passwordStrength(pw);
    const labels = ['', 'Lemah', 'Cukup', 'Baik', 'Kuat'];
    final colors = [Colors.black12, AppColors.danger, Colors.orange, AppColors.teal, AppColors.tealDark];
    final rules = <(String, bool)>[
      ('Minimal 8 karakter', pw.length >= 8),
      ('Mengandung huruf dan angka',
          RegExp(r'[A-Za-z]').hasMatch(pw) && RegExp(r'\d').hasMatch(pw)),
      ('Berbeda dari password lama', pw.isNotEmpty && pw != _old.text),
      ('Tambah simbol agar lebih kuat', RegExp(r'[^A-Za-z0-9]').hasMatch(pw)),
    ];

    return Column(
      children: [
        const PageHeader('Ganti Password'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            children: [
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  LabeledField(
                      label: 'Password Saat ini',
                      controller: _old,
                      obscure: _hideOld,
                      onChanged: (_) => setState(() {}),
                      suffix: _eye(_hideOld, () => setState(() => _hideOld = !_hideOld))),
                  const SizedBox(height: 14),
                  LabeledField(
                      label: 'Password baru',
                      controller: _new,
                      obscure: _hideNew,
                      onChanged: (_) => setState(() {}),
                      suffix: _eye(_hideNew, () => setState(() => _hideNew = !_hideNew))),
                  const SizedBox(height: 12),
                  Row(children: [
                    for (var i = 1; i <= 4; i++)
                      Expanded(
                        child: Container(
                          height: 6,
                          margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
                          decoration: BoxDecoration(
                              color: i <= strength ? colors[strength] : Colors.black12,
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(labels[strength],
                        style: AppText.body(12, weight: FontWeight.w700, color: colors[strength])),
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                      label: 'Ulangi password baru',
                      controller: _confirm,
                      obscure: _hideConfirm,
                      suffix: _eye(_hideConfirm, () => setState(() => _hideConfirm = !_hideConfirm))),
                ]),
              ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Syarat password', style: AppText.heading(15)),
                    const SizedBox(height: 8),
                    for (final r in rules)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: r.$2 ? AppColors.teal : Colors.black12),
                            child: Icon(Icons.check, size: 14, color: r.$2 ? Colors.white : Colors.black26),
                          ),
                          const SizedBox(width: 10),
                          Text(r.$1, style: AppText.body(13)),
                        ]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton('Simpan password', onPressed: () {
                final err = context
                    .read<AppState>()
                    .changePassword(_old.text, _new.text, _confirm.text);
                if (err != null) return toast(context, err);
                _old.clear();
                _new.clear();
                _confirm.clear();
                setState(() {});
                toast(context, 'Password berhasil diganti');
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================ Riwayat check-in
class CheckInHistoryScreen extends StatefulWidget {
  const CheckInHistoryScreen({super.key});
  @override
  State<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  String _f = 'Semua';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final n = today();
    final thisMonth = DateTime(n.year, n.month, 1);
    final lastMonth = DateTime(n.year, n.month - 1, 1);
    final nextMonth = DateTime(n.year, n.month + 1, 1);
    final list = app.checkIns.where((c) {
      if (_f == 'Bulan ini') return !c.at.isBefore(thisMonth) && c.at.isBefore(nextMonth);
      if (_f == 'Bulan lalu') return !c.at.isBefore(lastMonth) && c.at.isBefore(thisMonth);
      return true;
    }).toList();

    Widget stat(String label, String value, String unit) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body(11.5, color: AppColors.muted)),
                const SizedBox(height: 4),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(value, style: AppText.heading(30)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(unit, style: AppText.body(13, weight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        );

    return Column(
      children: [
        const PageHeader('Riwayat Check-in'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(children: [
                for (final f in ['Semua', 'Bulan ini', 'Bulan lalu'])
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: PillChip(f, selected: _f == f, onTap: () => setState(() => _f = f)),
                  ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                stat('Bulan ini', '${app.visitsThisMonth}', 'Kunjungan'),
                const SizedBox(width: 12),
                stat('Bulan ini', '${app.activeDaysThisMonth}', 'hari'),
              ]),
              const SizedBox(height: 14),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                      child: Text('Belum ada riwayat check-in',
                          style: AppText.body(13, color: AppColors.muted))),
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: AppColors.tealSoft,
                                  borderRadius: BorderRadius.circular(14)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${list[i].at.day}',
                                      style: AppText.heading(16)),
                                  Text(fmtDate(list[i].at, 'MMM'),
                                      style: AppText.body(11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(list[i].area,
                                      style: AppText.body(14, weight: FontWeight.w800)),
                                  Text(list[i].method,
                                      style: AppText.body(11.5, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            Text(fmtTime(list[i].at),
                                style: AppText.body(13, weight: FontWeight.w700)),
                          ]),
                        ),
                        if (i != list.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// =========================================================== Riwayat pembayaran
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});
  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppState>().transactions;
    final total = list.fold<int>(0, (a, t) => a + t.amount);
    return Column(
      children: [
        const PageHeader('Riwayat Pembayaran'),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text('Belum ada transaksi',
                      style: AppText.body(13, color: AppColors.muted)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    AppCard(
                      color: AppColors.navy,
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total pembayaran',
                                  style: AppText.body(12, color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text(rupiah(total),
                                  style: AppText.heading(22, color: Colors.white)),
                            ],
                          ),
                        ),
                        StatusChip('${list.length} transaksi',
                            bg: AppColors.lime, fg: AppColors.ink),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                      child: Text(
                          'Ketuk sekali untuk detail, ketuk lagi untuk melihat struk.',
                          style: AppText.body(11.5, color: AppColors.muted)),
                    ),
                    for (final t in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TxnTile(
                          txn: t,
                          expanded: _expandedId == t.id,
                          onToggle: () => setState(
                              () => _expandedId = _expandedId == t.id ? null : t.id),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile(
      {required this.txn, required this.expanded, required this.onToggle});
  final Txn txn;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = txn;
    Widget kv(String a, String b, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(a, style: AppText.body(12.5, color: AppColors.muted)),
              Flexible(
                child: Text(b,
                    textAlign: TextAlign.right,
                    style: AppText.body(13,
                        weight: bold ? FontWeight.w800 : FontWeight.w600,
                        color: color ?? AppColors.ink)),
              ),
            ],
          ),
        );

    return AppCard(
      // Ketuk pertama: buka detail. Ketuk kedua: buka struk.
      onTap: () => expanded ? ReceiptScreen.open(context, t) : onToggle(),
      borderColor: expanded ? AppColors.teal : null,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.receipt_long, color: AppColors.tealDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.planName,
                        style: AppText.body(14.5, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${t.id} · ${fmtDate(t.at)}',
                        style: AppText.body(11.5, color: AppColors.muted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rupiah(t.amount), style: AppText.heading(15)),
                  const SizedBox(height: 4),
                  StatusChip(t.status),
                ],
              ),
            ]),
            if (expanded) ...[
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1)),
              kv('Metode bayar', t.method),
              kv('Waktu', '${fmtDate(t.at)}, ${fmtTime(t.at)}'),
              if (t.periodStart != null && t.periodEnd != null)
                kv('Masa aktif',
                    '${fmtDate(t.periodStart!)} – ${fmtDate(t.periodEnd!)}'),
              if (t.planDays > 0) kv('Durasi', '${t.planDays} hari'),
              const SizedBox(height: 6),
              kv('Harga paket', rupiah(t.basePrice)),
              if (t.discount > 0)
                kv(t.promoLabel == null ? 'Diskon' : 'Diskon (${t.promoLabel})',
                    '- ${rupiah(t.discount)}',
                    color: AppColors.tealDark),
              const Divider(height: 18),
              kv('Total bayar', rupiah(t.amount), bold: true),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Row(children: [
                    const Icon(Icons.touch_app_outlined,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('Ketuk lagi untuk melihat struk',
                          style: AppText.body(11.5, color: AppColors.muted)),
                    ),
                  ]),
                ),
                TextButton.icon(
                  onPressed: () => ReceiptScreen.open(context, t),
                  icon: const Icon(Icons.receipt_outlined, size: 18),
                  label: const Text('Lihat struk'),
                ),
                IconButton(
                  tooltip: 'Tutup detail',
                  onPressed: onToggle,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
