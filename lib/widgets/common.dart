import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/theme.dart';

String rupiah(int v) => 'Rp ${NumberFormat.decimalPattern('id_ID').format(v)}';
String fmtDate(DateTime d, [String p = 'd MMM yyyy']) =>
    DateFormat(p, 'id_ID').format(d);
String fmtTime(DateTime d) => DateFormat('HH:mm').format(d);

void toast(BuildContext c, String msg) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.color = AppColors.ink,
    this.textColor = Colors.white,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: outlined ? color : textColor),
          const SizedBox(width: 8),
        ],
        Text(label,
            style: AppText.heading(16, color: outlined ? color : textColor)),
      ],
    );
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                shape: const StadiumBorder(),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: color.withValues(alpha: 0.35),
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: child,
            ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.onTap,
    this.borderColor,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 3))
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Header dengan tombol kembali bulat + judul di tengah.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.showBack = true, this.trailing});
  final String title;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(title, style: AppText.heading(20)),
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x1F000000), blurRadius: 8)
                      ],
                    ),
                    child: const Icon(Icons.chevron_left, size: 28),
                  ),
                ),
              ),
            ),
          if (trailing != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                  padding: const EdgeInsets.only(right: 20), child: trailing),
            ),
        ],
      ),
    );
  }
}

class PillField extends StatefulWidget {
  const PillField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboard,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;

  @override
  State<PillField> createState() => _PillFieldState();
}

class _PillFieldState extends State<PillField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboard,
      onChanged: widget.onChanged,
      textAlign: TextAlign.center,
      style: AppText.label(18),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppText.label(18, color: Colors.black38),
        filled: true,
        fillColor: AppColors.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide.none,
        ),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                    _hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.black45),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
        prefixIcon: widget.obscure ? const SizedBox(width: 48) : null,
      ),
    );
  }
}

/// Field berlabel (dipakai di Data Diri, Ganti Password, dsb).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboard,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.suffix,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: AppText.body(12, color: AppColors.muted)),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          style: AppText.body(14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F4F4),
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class PillChip extends StatelessWidget {
  const PillChip(this.label,
      {super.key, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: selected ? AppColors.teal : const Color(0xFFDDE5E4)),
        ),
        child: Text(label,
            style: AppText.body(13,
                weight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink)),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.text,
      {super.key,
      this.bg = AppColors.tealSoft,
      this.fg = AppColors.tealDark});
  final String text;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Text(text,
            style: AppText.body(12, weight: FontWeight.w700, color: fg)),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: AppText.heading(18)),
          trailing ?? const SizedBox.shrink(),
        ],
      );
}

/// Kotak besar di atas Pusat Informasi (informasi yang ditandai "banner").
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.category,
    required this.title,
    this.body = '',
    this.validUntil,
  });
  final String category;
  final String title;
  final String body;
  final DateTime? validUntil;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            colors: [Color(0xFF16A394), Color(0xFF0E7F74)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(category.toUpperCase(),
              bg: AppColors.lime, fg: AppColors.ink),
          const SizedBox(height: 12),
          Text(title, style: AppText.heading(22, color: Colors.white)),
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(12, color: Colors.white70)),
          ],
          if (validUntil != null) ...[
            const SizedBox(height: 6),
            Text('Berlaku sampai ${fmtDate(validUntil!)}',
                style: AppText.body(11.5, color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}

/// Satu baris informasi di daftar Pusat Informasi (juga dipakai untuk
/// pratinjau di form admin).
class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.category,
    required this.title,
    required this.meta,
    this.onTap,
  });
  final String category;
  final String title;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(16)),
            child: Icon(
                category == 'Promo'
                    ? Icons.local_offer_outlined
                    : category == 'Kelas'
                        ? Icons.fitness_center
                        : Icons.access_time,
                color: AppColors.tealDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: AppText.body(11,
                        weight: FontWeight.w700, color: AppColors.tealDark)),
                const SizedBox(height: 2),
                Text(title,
                    style: AppText.body(13.5, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(meta,
                    style: AppText.body(10.5, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool danger = false,
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 20),
          Text(title, style: AppText.heading(20), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message,
              style: AppText.body(13, color: AppColors.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: 22),
          PrimaryButton(confirmLabel,
              color: danger ? AppColors.danger : AppColors.ink,
              onPressed: () => Navigator.pop(context, true)),
          const SizedBox(height: 10),
          PrimaryButton(cancelLabel,
              outlined: true,
              color: AppColors.muted,
              onPressed: () => Navigator.pop(context, false)),
        ],
      ),
    ),
  );
  return r ?? false;
}

/// Kerangka halaman member dengan bottom navigation (Beranda/kelas/Paket/Profil).
class MemberShell extends StatelessWidget {
  const MemberShell({super.key, required this.child});
  final Widget child;

  int _index(String loc) {
    if (loc.startsWith('/classes')) return 1;
    if (loc.startsWith('/packages')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Saat logout, jangan bangun halaman anak (mencegah akses user null).
    if (context.watch<AppState>().currentUser == null) return const Scaffold();
    final loc = GoRouterState.of(context).uri.toString();
    final idx = _index(loc);
    const items = [
      (Icons.home_outlined, Icons.home, 'Beranda', '/home'),
      (Icons.calendar_today_outlined, Icons.calendar_today, 'kelas', '/classes'),
      (Icons.receipt_long_outlined, Icons.receipt_long, 'Paket', '/packages'),
      (Icons.person_outline, Icons.person, 'Profil', '/profile'),
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
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go(items[i].$4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(idx == i ? items[i].$2 : items[i].$1,
                              size: 26,
                              color: idx == i ? AppColors.ink : AppColors.muted),
                          const SizedBox(height: 2),
                          Text(items[i].$3,
                              style: AppText.body(11,
                                  weight: idx == i
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: idx == i
                                      ? AppColors.ink
                                      : AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
