import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String _targetTitle(Target t) =>
    t.period == TargetPeriod.weekly ? 'Target mingguan' : 'Target bulanan';

class TargetScreen extends StatelessWidget {
  const TargetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final active = app.hasActiveMembership;
    final targets = app.targets;
    final streak = active ? app.currentStreakWeeks : 0;
    final dots = app.weekDots;

    return Column(
      children: [
        const PageHeader('Target & Streak'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // ---- kartu streak
              Container(
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
                    Text('Streak saat ini',
                        style: AppText.body(13, weight: FontWeight.w600, color: Colors.white70)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$streak', style: AppText.heading(52, color: Colors.white)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('minggu berturut-turut',
                              style: AppText.body(13, color: Colors.white)),
                        ),
                      ],
                    ),
                    Text(
                        !active
                            ? 'Streak dimulai setelah kunjungan pertamamu'
                            : targets.isEmpty
                                ? 'Buat target untuk mulai menghitung streak'
                                : 'Rekor terbaikmu: ${app.bestStreakWeeks} minggu',
                        style: AppText.body(12.5, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Column(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dots[i] && active ? AppColors.teal : AppColors.tealSoft),
                          child: dots[i] && active
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(_dayLabels[i], style: AppText.body(11)),
                      ]),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ---- belum member
              if (!active) ...[
                _placeholderTarget('Target mingguan'),
                const SizedBox(height: 10),
                _placeholderTarget('Target bulanan'),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.priority_high, color: AppColors.tealDark),
                    ),
                    const SizedBox(height: 12),
                    Text('Target tersedia untuk member aktif', style: AppText.heading(16), textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text('Beli membership untuk membuat target dan menjaga streak latihanmu',
                        textAlign: TextAlign.center,
                        style: AppText.body(12.5, color: AppColors.muted)),
                  ]),
                ),
                const SizedBox(height: 16),
                PrimaryButton('Lihat paket membership', onPressed: () => context.go('/packages')),
              ]

              // ---- member, belum ada target
              else if (targets.isEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: AppColors.tealDark, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text('Kamu belum punya target', style: AppText.heading(17)),
                    const SizedBox(height: 6),
                    Text('Tentukan target kunjungan mingguan atau bulanan agar latihanmu lebih konsisten.',
                        textAlign: TextAlign.center,
                        style: AppText.body(12.5, color: AppColors.muted)),
                    const SizedBox(height: 16),
                    PrimaryButton('Buat target pertama', onPressed: () => context.push('/target/new')),
                  ]),
                ),
                const SizedBox(height: 18),
                Text('Contoh target', style: AppText.heading(17)),
                const SizedBox(height: 10),
                for (final e in const [
                  (3, 'Cocok untuk pemula'),
                  (4, 'Latihan rutin'),
                  (5, 'Untuk yang sudah terbiasa'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.$1}x seminggu', style: AppText.heading(16)),
                              Text(e.$2, style: AppText.body(12, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final err = context.read<AppState>().addTarget(Target(
                                id: 't${DateTime.now().microsecondsSinceEpoch}',
                                name: '${e.$1}x seminggu',
                                period: TargetPeriod.weekly,
                                count: e.$1));
                            toast(context, err ?? 'Target ditambahkan');
                          },
                          child: Text('Pakai',
                              style: AppText.body(14, weight: FontWeight.w800, color: AppColors.teal)),
                        ),
                      ]),
                    ),
                  ),
              ]

              // ---- member dengan target
              else ...[
                for (final t in targets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TargetCard(t: t, done: app.targetProgress(t)),
                  ),
                const SizedBox(height: 6),
                PrimaryButton('Buat target baru', onPressed: () {
                  if (targets.length >= 2) {
                    toast(context, 'Maksimal 1 target mingguan dan 1 target bulanan');
                  } else {
                    context.push('/target/new');
                  }
                }),
                const SizedBox(height: 12),
                PrimaryButton('Hapus target',
                    outlined: true,
                    color: AppColors.danger,
                    icon: Icons.delete_outline,
                    onPressed: () => _deleteSheet(context)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholderTarget(String title) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppText.heading(16)),
              Text('0 dari 0 kunjungan', style: AppText.body(12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
                value: 0, minHeight: 10, backgroundColor: AppColors.tealSoft),
          ),
        ]),
      );

  Future<void> _deleteSheet(BuildContext context) async {
    final app = context.read<AppState>();
    String? selected;
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 42, height: 4,
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 18),
              Text('Pilih target yang mau dihapus', style: AppText.heading(19)),
              const SizedBox(height: 4),
              Text('Pilih salah satu target di bawah.', style: AppText.body(13, color: AppColors.muted)),
              const SizedBox(height: 14),
              for (final t in app.targets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => setS(() => selected = t.id),
                    borderColor: selected == t.id ? AppColors.danger : null,
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Icon(selected == t.id ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected == t.id ? AppColors.danger : Colors.black26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_targetTitle(t), style: AppText.body(14, weight: FontWeight.w800)),
                            Text('${app.targetProgress(t)} dari ${t.count} kunjungan',
                                style: AppText.body(12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              PrimaryButton('Ya, hapus target',
                  color: AppColors.danger,
                  onPressed: selected == null ? null : () => Navigator.pop(ctx, selected)),
              const SizedBox(height: 10),
              PrimaryButton('Batal', outlined: true, color: AppColors.muted, onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
    if (id != null && context.mounted) {
      context.read<AppState>().deleteTarget(id);
      toast(context, 'Target dihapus');
    }
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.t, required this.done});
  final Target t;
  final int done;
  @override
  Widget build(BuildContext context) {
    final v = t.count == 0 ? 0.0 : (done / t.count).clamp(0.0, 1.0);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_targetTitle(t), style: AppText.heading(16)),
            Text('$done dari ${t.count} kunjungan',
                style: AppText.body(12.5, color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
              value: v,
              minHeight: 12,
              backgroundColor: AppColors.tealSoft,
              valueColor: AlwaysStoppedAnimation(v >= 1 ? AppColors.tealDark : AppColors.teal)),
        ),
        if (v >= 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Target tercapai 🎉',
                  style: AppText.body(12, weight: FontWeight.w700, color: AppColors.tealDark)),
            ),
          ),
      ]),
    );
  }
}

// ============================================================== Buat target
class CreateTargetScreen extends StatefulWidget {
  const CreateTargetScreen({super.key});
  @override
  State<CreateTargetScreen> createState() => _CreateTargetScreenState();
}

class _CreateTargetScreenState extends State<CreateTargetScreen> {
  final _name = TextEditingController(text: 'Latihan rutin pagi');
  TargetPeriod _period = TargetPeriod.weekly;
  int _count = 4;
  final Set<int> _days = {1, 3, 5, 6};
  bool _reminder = true;
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _max => _period == TargetPeriod.weekly ? 7 : 31;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final preview = Target(id: 'p', name: _name.text, period: _period, count: _count);
    final done = app.targetProgress(preview);

    Widget box(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(13.5, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                child,
              ],
            ),
          ),
        );

    return Column(
      children: [
        const PageHeader('Target & Streak'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              box(
                'Nama target',
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F4F4),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              box(
                'Periode',
                Row(children: [
                  for (final p in TargetPeriod.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: p == TargetPeriod.weekly ? 10 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _period = p;
                            _count = p == TargetPeriod.weekly ? 4 : 16;
                          }),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _period == p ? AppColors.teal : const Color(0xFFF1F4F4),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(p == TargetPeriod.weekly ? 'Mingguan' : 'Bulanan',
                                style: AppText.body(14,
                                    weight: FontWeight.w700,
                                    color: _period == p ? Colors.white : AppColors.ink)),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
              box(
                'Jumlah kunjungan',
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stepBtn(Icons.remove, () => setState(() => _count = (_count - 1).clamp(1, _max))),
                    Column(children: [
                      Text('$_count', style: AppText.heading(34)),
                      Text(_period == TargetPeriod.weekly ? 'kunjungan per minggu' : 'kunjungan per bulan',
                          style: AppText.body(12, color: AppColors.muted)),
                    ]),
                    _stepBtn(Icons.add, () => setState(() => _count = (_count + 1).clamp(1, _max))),
                  ],
                ),
              ),
              if (_period == TargetPeriod.weekly)
                box(
                  'Hari latihan',
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 1; i <= 7; i++)
                        GestureDetector(
                          onTap: () => setState(() => _days.contains(i) ? _days.remove(i) : _days.add(i)),
                          child: Column(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _days.contains(i) ? AppColors.teal : AppColors.tealSoft),
                              child: _days.contains(i)
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(_dayLabels[i - 1], style: AppText.body(11)),
                          ]),
                        ),
                    ],
                  ),
                ),
              box(
                'Pengingat latihan',
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _time);
                        if (t != null) setState(() => _time = t);
                      },
                      child: Text(
                          _reminder
                              ? 'Setiap hari latihan, pukul ${_time.hour.toString().padLeft(2, '0')}.${_time.minute.toString().padLeft(2, '0')}'
                              : 'Pengingat mati',
                          style: AppText.body(13, color: AppColors.muted)),
                    ),
                  ),
                  Switch(
                    value: _reminder,
                    activeThumbColor: AppColors.teal,
                    onChanged: (v) => setState(() => _reminder = v),
                  ),
                ]),
              ),
              AppCard(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF0FBF9),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_period == TargetPeriod.weekly ? 'Target mingguan' : 'Target bulanan',
                          style: AppText.heading(15)),
                      Text('$done dari $_count kunjungan',
                          style: AppText.body(12, color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                        value: (done / _count).clamp(0.0, 1.0),
                        minHeight: 9,
                        backgroundColor: AppColors.tealSoft,
                        valueColor: const AlwaysStoppedAnimation(AppColors.teal)),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              PrimaryButton('Simpan target', onPressed: _save),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Batal', style: AppText.body(14, weight: FontWeight.w700, color: AppColors.muted)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepBtn(IconData i, VoidCallback t) => InkWell(
        customBorder: const CircleBorder(),
        onTap: t,
        child: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
          child: Icon(i, color: Colors.white),
        ),
      );

  void _save() {
    final err = context.read<AppState>().addTarget(Target(
          id: 't${DateTime.now().microsecondsSinceEpoch}',
          name: _name.text.trim(),
          period: _period,
          count: _count,
          days: _period == TargetPeriod.weekly ? {..._days} : {},
          reminder: _reminder,
          reminderHour: _time.hour,
          reminderMinute: _time.minute,
        ));
    if (err != null) {
      toast(context, err);
    } else {
      toast(context, 'Target disimpan');
      context.pop();
    }
  }
}
