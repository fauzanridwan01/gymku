import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/camera_panel.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';

enum _ScanStage { idle, scanning, success, failed }

class AdminScanScreen extends StatefulWidget {
  const AdminScanScreen({super.key});
  @override
  State<AdminScanScreen> createState() => _AdminScanScreenState();
}

class _AdminScanScreenState extends State<AdminScanScreen> {
  final _cam = CameraPanelController();
  _ScanStage _stage = _ScanStage.idle;
  bool _camReady = false;
  AppUser? _found;
  String _failMsg = '';

  Future<void> _scan() async {
    setState(() => _stage = _ScanStage.scanning);
    final frame = await _cam.capture();
    if (!mounted) return;
    if (frame == null) {
      setState(() {
        _stage = _ScanStage.failed;
        _failMsg = 'Kamera belum siap atau gagal mengambil gambar. Coba lagi.';
      });
      return;
    }
    // Beri jeda singkat agar terlihat sedang memproses.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final u = context.read<AppState>().recognizeFace();
    setState(() {
      if (u == null) {
        _stage = _ScanStage.failed;
        _failMsg =
            'Wajah tidak cocok dengan data member mana pun. Pastikan wajah terlihat jelas dan cahaya cukup.';
      } else {
        _found = u;
        _stage = _ScanStage.success;
      }
    });
  }

  void _reset() => setState(() {
        _stage = _ScanStage.idle;
        _found = null;
      });

  void _allow() {
    final u = _found!;
    final err = context.read<AppState>().adminCheckIn(u);
    toast(context, err ?? 'Silakan masuk, ${u.name}. Check-in tercatat.');
    if (err == null) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = _found;
    final ok = _stage == _ScanStage.success;
    final failed = _stage == _ScanStage.failed;
    final denied = (ok && u != null) ? app.entryDeniedReason(u) : null;
    final m = u == null ? null : app.membershipOf(u.id);
    final st = u == null ? null : app.statusOf(u);

    Widget info(String label, String value, {Color? color}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppText.body(11, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(value, style: AppText.body(13, weight: FontWeight.w800, color: color ?? AppColors.ink)),
          ]),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        const AdminHeader('Scan Wajah', subtitle: 'Check-in pengunjung membership'),
        SizedBox(
          height: 300,
          child: CameraPanel(
            controller: _cam,
            frameColor: failed ? const Color(0xFFF5A623) : AppColors.teal,
            onReadyChanged: (v) {
              if (mounted) setState(() => _camReady = v);
            },
          ),
        ),
        const SizedBox(height: 14),
        if (failed)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF5C16C))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: const Color(0xFFF5A623), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.priority_high, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Scan Gagal',
                      style: AppText.body(14, weight: FontWeight.w800, color: const Color(0xFFB26A00))),
                  const SizedBox(height: 2),
                  Text(_failMsg, style: AppText.body(12, color: const Color(0xFF8A5A00))),
                ]),
              ),
            ]),
          )
        else
          AppCard(
            child: Column(children: [
              Row(children: [
                if (u != null)
                  MemberAvatar(u, size: 44, status: st)
                else
                  const CircleAvatar(radius: 22, backgroundColor: Color(0xFFE5E5E5)),
                const SizedBox(width: 12),
                Expanded(
                  child: u == null
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(width: 120, height: 12, color: const Color(0xFFE5E5E5)),
                          const SizedBox(height: 6),
                          Container(width: 80, height: 10, color: const Color(0xFFEFEFEF)),
                        ])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u.name, style: AppText.body(15, weight: FontWeight.w800)),
                          Text(u.memberId, style: AppText.body(12, color: AppColors.muted)),
                        ]),
                ),
                if (_stage == _ScanStage.scanning)
                  const SizedBox(
                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
              ]),
              const Divider(height: 22),
              Row(children: [
                info('Status', st == null ? '-' : statusLabel(st),
                    color: st == null ? null : statusColors(st).$2),
                info('Berakhir', m == null ? '-' : fmtDate(m.end)),
                info('Check-in bulan ini',
                    u == null ? '-' : 'Ke-${app.visitsInMonthOf(u.id, DateTime.now()) + 1}'),
              ]),
            ]),
          ),
        if (denied != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFFBE3E3), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.block, color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Tidak bisa masuk: $denied',
                      style: AppText.body(12.5, color: AppColors.danger))),
            ]),
          ),
        ],
        if (failed) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final c in ['Wajah tertutup', 'Cahaya kurang', 'Belum terdaftar'])
              Chip(
                  label: Text(c, style: AppText.body(11.5)),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFDDE5E4))),
          ]),
        ],
        const SizedBox(height: 16),
        if (_stage == _ScanStage.idle || _stage == _ScanStage.scanning)
          PrimaryButton(_stage == _ScanStage.scanning ? 'Memindai...' : 'Pindai wajah',
              icon: Icons.center_focus_strong,
              onPressed: (_camReady && _stage == _ScanStage.idle) ? _scan : null)
        else if (ok)
          Row(children: [
            Expanded(child: PrimaryButton('Tolak', outlined: true, onPressed: _reset)),
            const SizedBox(width: 12),
            Expanded(
                child: PrimaryButton('Izinkan masuk',
                    onPressed: denied == null ? _allow : null)),
          ])
        else
          Row(children: [
            Expanded(
                child: PrimaryButton('Cari manual',
                    outlined: true, onPressed: () => context.push('/admin/search'))),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton('Scan ulang', onPressed: _scan)),
          ]),
        const SizedBox(height: 14),
        Center(
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(ok ? 'Data tidak sesuai? ' : 'Mengalami kesulitan? ',
                style: AppText.body(12, color: AppColors.muted)),
            GestureDetector(
              onTap: () => context.push('/admin/search'),
              child: Text('Cari manual',
                  style: AppText.body(12, weight: FontWeight.w800, color: AppColors.tealDark)),
            ),
          ]),
        ),
      ],
    );
  }
}
