import 'dart:typed_data';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Pengendali untuk mengambil foto dari [CameraPanel].
class CameraPanelController {
  _CameraPanelState? _state;

  bool get isReady => _state?._ready ?? false;
  bool get hasMultipleCameras => (_state?._cams.length ?? 0) > 1;

  /// Mengambil satu frame. Mengembalikan null jika kamera belum siap / gagal.
  Future<Uint8List?> capture() async => _state?._capture();

  Future<void> switchCamera() async => _state?._switch();
}

/// Pratinjau kamera dengan bingkai sudut, penanganan izin, dan lifecycle.
class CameraPanel extends StatefulWidget {
  const CameraPanel({
    super.key,
    required this.controller,
    this.frameColor = AppColors.teal,
    this.label = 'Pratinjau Kamera',
    this.preferFront = true,
    this.onReadyChanged,
  });

  final CameraPanelController controller;
  final Color frameColor;
  final String label;
  final bool preferFront;
  final ValueChanged<bool>? onReadyChanged;

  @override
  State<CameraPanel> createState() => _CameraPanelState();
}

class _CameraPanelState extends State<CameraPanel> with WidgetsBindingObserver {
  CameraController? _cam;
  List<CameraDescription> _cams = [];
  int _index = 0;
  bool _ready = false;
  bool _loading = true;
  bool _firstInit = true;
  bool _initializing = false;
  bool _resumeAfterInit = false;
  String? _error;
  int _gen = 0; // mencegah balapan antar-inisialisasi

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    WidgetsBinding.instance.addObserver(this);
    _init(initial: true);
  }

  void _setReady(bool v) {
    if (_ready == v) return;
    _ready = v;
    widget.onReadyChanged?.call(v);
  }

  Future<void> _init({bool initial = false}) async {
    if (_initializing) {
      _resumeAfterInit = true;
      return;
    }
    _initializing = true;
    final gen = ++_gen;
    // Jangan setState di dalam initState (state awal sudah "loading").
    if (!initial && mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _setReady(false);
      });
    }
    try {
      if (_cams.isEmpty) _cams = await availableCameras();
      if (gen != _gen || !mounted) return;
      if (_cams.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Tidak ada kamera yang ditemukan di perangkat ini.';
        });
        return;
      }
      if (_firstInit) {
        _firstInit = false;
        final want =
            widget.preferFront ? CameraLensDirection.front : CameraLensDirection.back;
        final i = _cams.indexWhere((c) => c.lensDirection == want);
        _index = i >= 0 ? i : 0;
      }
      final old = _cam;
      _cam = null;
      await old?.dispose();
      final c = CameraController(_cams[_index], ResolutionPreset.medium,
          enableAudio: false);
      await c.initialize();
      if (gen != _gen || !mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _cam = c;
        _loading = false;
        _setReady(true);
      });
    } on CameraException catch (e) {
      if (gen != _gen || !mounted) return;
      setState(() {
        _loading = false;
        _setReady(false);
        _error = _friendly(e);
      });
    } catch (e, stackTrace) {
      if (gen != _gen || !mounted) return;
      debugPrint('Camera initialization failed: $e\n$stackTrace');
      setState(() {
        _loading = false;
        _setReady(false);
        _error = 'Kamera tidak bisa dibuka. Pastikan izin kamera aktif dan '
            'kamera tidak sedang dipakai aplikasi lain.\nDetail: $e';
      });
    } finally {
      _initializing = false;
      if (_resumeAfterInit && mounted) {
        _resumeAfterInit = false;
        await _init();
      }
    }
  }

  String _friendly(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Izin kamera ditolak. Aktifkan izin kamera di pengaturan '
            'perangkat/browser, lalu coba lagi.';
      case 'cameraPermission':
        return 'Izin kamera ditolak. Aktifkan izin kamera lalu coba lagi.';
      default:
        final description = e.description;
        return 'Kamera tidak bisa dibuka (${e.code}).'
            '${description == null ? '' : '\n$description'}';
    }
  }

  Future<Uint8List?> _capture() async {
    final c = _cam;
    if (!_ready || c == null || c.value.isTakingPicture) return null;
    final f = await c.takePicture();
    return f.readAsBytes();
  }

  Future<void> _switch() async {
    if (_cams.length < 2) return;
    _index = (_index + 1) % _cams.length;
    await _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _gen++;
      final c = _cam;
      _cam = null;
      c?.dispose();
      if (mounted) setState(() => _setReady(false));
    } else if (state == AppLifecycleState.resumed && _cam == null) {
      _init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gen++;
    if (widget.controller._state == this) widget.controller._state = null;
    _cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _cam;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.navy,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_ready && cam != null)
              LayoutBuilder(builder: (context, box) {
                var scale =
                    1 / (cam.value.aspectRatio * box.maxWidth / box.maxHeight);
                if (scale < 1) scale = 1 / scale;
                return ClipRect(
                  child: Transform.scale(
                    scale: scale,
                    child: Center(child: CameraPreview(cam)),
                  ),
                );
              }),
            CustomPaint(painter: _BracketPainter(widget.frameColor)),
            if (_loading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.white70)),
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined,
                          color: Colors.white70, size: 40),
                      const SizedBox(height: 10),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: AppText.body(12.5, color: Colors.white70)),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: _init,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54)),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: Text(widget.label,
                    textAlign: TextAlign.center,
                    style: AppText.body(12, color: Colors.white70)),
              ),
            if (_ready && _cams.length > 1)
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: _switch,
                  style: IconButton.styleFrom(backgroundColor: Colors.black38),
                  icon: const Icon(Icons.cameraswitch_outlined,
                      color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  _BracketPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const m = 18.0, l = 34.0;
    final w = size.width, h = size.height;
    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * l, y), p);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * l), p);
    }

    corner(m, m, 1, 1);
    corner(w - m, m, -1, 1);
    corner(m, h - m, 1, -1);
    corner(w - m, h - m, -1, -1);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}
