import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Teks struk polos (dipakai untuk "Salin struk").
String receiptText(Txn t) {
  final b = StringBuffer()
    ..writeln('GYMKU - STRUK PEMBAYARAN')
    ..writeln('No. Struk : ${t.receiptNo}')
    ..writeln('Tanggal   : ${fmtDate(t.at, 'd MMM yyyy')} ${fmtTime(t.at)}')
    ..writeln('Member    : ${t.memberName} (${t.memberId})')
    ..writeln('Metode    : ${t.method}')
    ..writeln('--------------------------------')
    ..writeln('${t.planName}  x1');
  if (t.periodStart != null && t.periodEnd != null) {
    b.writeln(
        'Masa aktif: ${fmtDate(t.periodStart!)} - ${fmtDate(t.periodEnd!)}');
  }
  b
    ..writeln('--------------------------------')
    ..writeln('Subtotal  : ${rupiah(t.basePrice)}');
  if (t.discount > 0) {
    b.writeln('Diskon    : -${rupiah(t.discount)}'
        '${t.promoLabel == null ? '' : ' (${t.promoLabel})'}');
  }
  b
    ..writeln('TOTAL     : ${rupiah(t.amount)}')
    ..writeln('Status    : ${t.status}');
  return b.toString();
}

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.txn});
  final Txn txn;

  static Future<void> open(BuildContext context, Txn t) =>
      Navigator.of(context, rootNavigator: true)
          .push(MaterialPageRoute(builder: (_) => ReceiptScreen(txn: t)));

  @override
  Widget build(BuildContext context) {
    final t = txn;
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5);

    Widget row(String a, String b,
            {bool bold = false, Color? color, bool big = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(a,
                    style: mono.copyWith(
                        color: AppColors.muted,
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
              ),
              Expanded(
                flex: 6,
                child: Text(b,
                    textAlign: TextAlign.right,
                    style: mono.copyWith(
                        color: color ?? AppColors.ink,
                        fontSize: big ? 17 : 13,
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: const Color(0xFFDDE8E6),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text('Struk Pembayaran', style: AppText.heading(19)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
                child: Column(
                  children: [
                    ClipPath(
                      clipper: _ZigZagClipper(),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(22, 30, 22, 34),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: Text('GYMKU', style: AppText.logo(26))),
                            const SizedBox(height: 2),
                            Center(
                              child: Text('Struk Pembayaran Membership',
                                  style: AppText.body(12, color: AppColors.muted)),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: t.status == 'Berhasil'
                                      ? AppColors.tealSoft
                                      : const Color(0xFFFBE3E3),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                    t.status == 'Berhasil' ? 'LUNAS' : t.status.toUpperCase(),
                                    style: AppText.body(12,
                                        weight: FontWeight.w800,
                                        color: t.status == 'Berhasil'
                                            ? AppColors.tealDark
                                            : AppColors.danger)),
                              ),
                            ),
                            const _Dashed(),
                            row('No. Struk', t.receiptNo),
                            row('ID Transaksi', t.id),
                            row('Tanggal', fmtDate(t.at, 'd MMM yyyy')),
                            row('Jam', fmtTime(t.at)),
                            const _Dashed(),
                            row('Member', t.memberName.isEmpty ? '-' : t.memberName),
                            row('ID Member', t.memberId.isEmpty ? '-' : t.memberId),
                            row('Metode', t.method),
                            const _Dashed(),
                            Text('ITEM', style: mono.copyWith(color: AppColors.muted)),
                            const SizedBox(height: 4),
                            row(t.planName, 'x1  ${rupiah(t.basePrice)}', bold: true),
                            if (t.periodStart != null && t.periodEnd != null) ...[
                              row('Mulai', fmtDate(t.periodStart!)),
                              row('Berakhir', fmtDate(t.periodEnd!)),
                            ],
                            if (t.planDays > 0) row('Durasi', '${t.planDays} hari'),
                            const _Dashed(),
                            row('Subtotal', rupiah(t.basePrice)),
                            if (t.discount > 0)
                              row(
                                  t.promoLabel == null
                                      ? 'Diskon'
                                      : 'Diskon',
                                  '-${rupiah(t.discount)}',
                                  color: AppColors.tealDark),
                            if (t.promoLabel != null && t.discount > 0)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text('(${t.promoLabel})',
                                    textAlign: TextAlign.right,
                                    style: mono.copyWith(
                                        fontSize: 11, color: AppColors.muted)),
                              ),
                            const SizedBox(height: 4),
                            row('TOTAL', rupiah(t.amount), bold: true, big: true),
                            const _Dashed(),
                            Center(
                              child: QrImageView(
                                data: t.receiptNo,
                                size: 110,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text('Tunjukkan QR ini jika perlu verifikasi',
                                  style: AppText.body(11, color: AppColors.muted)),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: Text('Terima kasih sudah berlatih\nbersama GYMKU!',
                                  textAlign: TextAlign.center,
                                  style: AppText.body(12.5, weight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton('Salin struk',
                        icon: Icons.copy,
                        outlined: true,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: receiptText(t)));
                          toast(context, 'Struk disalin');
                        }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton('Selesai',
                        onPressed: () => Navigator.of(context).pop()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(builder: (_, c) {
          final n = (c.maxWidth / 8).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                n,
                (_) => Container(
                    width: 4, height: 1.4, color: const Color(0xFFB8C4C2))),
          );
        }),
      );
}

/// Tepi atas & bawah bergerigi seperti kertas struk.
class _ZigZagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const h = 8.0, w = 14.0;
    final path = Path()..moveTo(0, h);
    var x = 0.0;
    var up = false;
    while (x < size.width) {
      x = (x + w / 2).clamp(0.0, size.width).toDouble();
      path.lineTo(x, up ? h : 0);
      up = !up;
    }
    path.lineTo(size.width, size.height - h);
    x = size.width;
    up = false;
    while (x > 0) {
      x = (x - w / 2).clamp(0.0, size.width).toDouble();
      path.lineTo(x, size.height - (up ? h : 0));
      up = !up;
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
