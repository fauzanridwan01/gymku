import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/camera_panel.dart';
import '../widgets/common.dart';

/// Member mendaftarkan / memperbarui foto wajah untuk check-in.
class FaceEnrollScreen extends StatefulWidget {
  const FaceEnrollScreen({super.key});
  @override
  State<FaceEnrollScreen> createState() => _FaceEnrollScreenState();
}

class _FaceEnrollScreenState extends State<FaceEnrollScreen> {
  final _cam = CameraPanelController();
  Uint8List? _shot;
  bool _ready = false;
  bool _busy = false;

  Future<void> _take() async {
    setState(() => _busy = true);
    Uint8List? b;
    try {
      b = await _cam.capture();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, 'Gagal mengambil foto. Detail: $e');
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _shot = b;
    });
    if (b == null) toast(context, 'Gagal mengambil foto. Coba lagi.');
  }

  void _save() {
    context.read<AppState>().enrollFace(_shot!);
    toast(context, 'Foto wajah tersimpan. Check-in tinggal scan wajah.');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final has = context.watch<AppState>().currentUser?.hasFace ?? false;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          PageHeader(has ? 'Perbarui Foto Wajah' : 'Daftarkan Wajah'),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
                'Hadapkan wajah ke kamera, pastikan cahaya cukup dan wajah tidak tertutup masker atau kacamata hitam.',
                textAlign: TextAlign.center,
                style: AppText.body(12.5, color: AppColors.muted)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _shot == null
                  ? CameraPanel(
                      controller: _cam,
                      label: 'Posisikan wajah di dalam bingkai',
                      onReadyChanged: (v) {
                        if (mounted) setState(() => _ready = v);
                      },
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(_shot!, fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _shot == null
                ? PrimaryButton(_busy ? 'Mengambil...' : 'Ambil foto',
                    icon: Icons.camera_alt_outlined,
                    color: AppColors.teal,
                    onPressed: (_ready && !_busy) ? _take : null)
                : Row(children: [
                    Expanded(
                        child: PrimaryButton('Ulangi',
                            outlined: true, onPressed: () => setState(() => _shot = null))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: PrimaryButton('Pakai foto ini',
                            color: AppColors.teal, onPressed: _save)),
                  ]),
          ),
        ]),
      ),
    );
  }
}
