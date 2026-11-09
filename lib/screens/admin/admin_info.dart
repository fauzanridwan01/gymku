import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';

const _kCategories = ['Pengumuman', 'Kelas', 'Promo'];

(String, Color, Color) _statusStyle(Announcement a) {
  if (a.status == InfoStatus.archived) {
    return ('Diarsipkan', const Color(0xFFE5E5E5), AppColors.muted);
  }
  if (a.status == InfoStatus.draft) {
    return ('Draft', const Color(0xFFE5E5E5), AppColors.muted);
  }
  if (a.isScheduled) {
    return ('Terjadwal', const Color(0xFFDCEBFF), const Color(0xFF2B6CB0));
  }
  if (a.isExpired) {
    return ('Kedaluwarsa', const Color(0xFFFFEBC8), const Color(0xFFB26A00));
  }
  return ('Terbit', AppColors.tealSoft, AppColors.tealDark);
}

// ================================================ Daftar informasi (tab Paket)
/// Isi tab "Informasi" di layar Paket & Promo: tombol + Buat Informasi dan
/// daftar informasi yang sudah dibuat admin.
class AdminInfoSection extends StatefulWidget {
  const AdminInfoSection({super.key});
  @override
  State<AdminInfoSection> createState() => _AdminInfoSectionState();
}

class _AdminInfoSectionState extends State<AdminInfoSection> {
  static const _filters = ['Semua', 'Terbit', 'Terjadwal', 'Draft', 'Arsip'];
  String _filter = 'Semua';

  bool _match(Announcement a) => switch (_filter) {
        'Terbit' => a.status == InfoStatus.published && !a.isScheduled,
        'Terjadwal' => a.isScheduled,
        'Draft' => a.status == InfoStatus.draft,
        'Arsip' => a.status == InfoStatus.archived,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.allAnnouncements.where(_match).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(
              'Informasi yang dibuat di sini tampil di Pusat Informasi member.',
              style: AppText.body(12, color: AppColors.muted)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => context.push('/admin/info'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
          child: const Text('+ Buat Informasi'),
        ),
      ]),
      const SizedBox(height: 14),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final f in _filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PillChip(f,
                  selected: _filter == f,
                  onTap: () => setState(() => _filter = f)),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
              child: Text('Belum ada informasi.',
                  style: AppText.body(13, color: AppColors.muted))),
        ),
      for (final a in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InfoAdminCard(a),
        ),
    ]);
  }
}

class _InfoAdminCard extends StatelessWidget {
  const _InfoAdminCard(this.a);
  final Announcement a;

  String _when() {
    if (a.status == InfoStatus.draft) return 'Belum diterbitkan';
    if (a.isScheduled) {
      return 'Terbit ${fmtDate(a.at)}, ${fmtTime(a.at)}';
    }
    return 'Terbit ${fmtDate(a.at)}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final st = _statusStyle(a);
    final target = a.isForAll
        ? 'Semua member'
        : 'Khusus ${app.userById(a.targetUserId!)?.name ?? 'member'}';
    final archived = a.status == InfoStatus.archived;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip(st.$1, bg: st.$2, fg: st.$3),
            StatusChip(a.category),
            if (a.isBanner)
              const StatusChip('Banner', bg: AppColors.lime, fg: AppColors.ink),
          ],
        ),
        const SizedBox(height: 10),
        Text(a.title, style: AppText.body(14.5, weight: FontWeight.w800)),
        if (a.body.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(a.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(12, color: AppColors.muted)),
          ),
        const SizedBox(height: 6),
        Text('$target · ${_when()}',
            style: AppText.body(11.5, color: AppColors.muted)),
        if (a.validUntil != null)
          Text('Berlaku sampai ${fmtDate(a.validUntil!)}',
              style: AppText.body(11.5, color: AppColors.muted)),
        Text('${a.views}x dilihat',
            style: AppText.body(11.5, color: AppColors.muted)),
        const SizedBox(height: 8),
        Row(children: [
          TextButton(
            onPressed: () => context.push('/admin/info', extra: a),
            style: TextButton.styleFrom(
                backgroundColor: AppColors.tealSoft,
                foregroundColor: AppColors.tealDark),
            child: const Text('Ubah'),
          ),
          if (a.status != InfoStatus.draft) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                context
                    .read<AppState>()
                    .setAnnouncementArchived(a.id, !archived);
                toast(context,
                    archived ? 'Informasi ditampilkan lagi' : 'Informasi diarsipkan');
              },
              child: Text(archived ? 'Tampilkan lagi' : 'Arsipkan'),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: () async {
              final ok = await confirmSheet(context,
                  title: 'Hapus informasi ini?',
                  message:
                      '"${a.title}" dihapus permanen dan tidak tampil lagi di layar member.',
                  confirmLabel: 'Ya, hapus',
                  danger: true);
              if (ok && context.mounted) {
                context.read<AppState>().deleteAnnouncement(a.id);
                toast(context, 'Informasi dihapus');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ]),
      ]),
    );
  }
}

// ================================================================ Form buat
class InfoFormScreen extends StatefulWidget {
  const InfoFormScreen({super.key, this.editing});
  final Announcement? editing;
  @override
  State<InfoFormScreen> createState() => _InfoFormScreenState();
}

class _InfoFormScreenState extends State<InfoFormScreen> {
  late final _title = TextEditingController(text: widget.editing?.title ?? '');
  late final _body = TextEditingController(text: widget.editing?.body ?? '');
  final _search = TextEditingController();

  late String _category = widget.editing?.category ?? 'Pengumuman';
  late bool _toAll = widget.editing?.isForAll ?? true;
  late String? _memberId = widget.editing?.targetUserId;
  late bool _banner = widget.editing?.isBanner ?? false;
  late DateTime? _validUntil = widget.editing?.validUntil;
  late bool _scheduled =
      widget.editing != null && widget.editing!.at.isAfter(DateTime.now());
  late DateTime _publishAt =
      (widget.editing != null && widget.editing!.at.isAfter(DateTime.now()))
          ? widget.editing!.at
          : DateTime.now().add(const Duration(hours: 1));
  String _q = '';
  String? _error;

  /// Sudah berstatus terbit (tampil atau terjadwal): tombol berubah menjadi
  /// "Simpan perubahan".
  bool get _wasPublished => widget.editing?.status == InfoStatus.published;

  /// Sudah tampil di member: waktu terbit tidak bisa diubah lagi.
  bool get _timeLocked => _wasPublished && !widget.editing!.isScheduled;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickValid() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? today().add(const Duration(days: 30)),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      _validUntil = d;
      _error = null;
    });
  }

  Future<void> _pickPublishAt() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _publishAt.isBefore(now) ? now : _publishAt,
      firstDate: dateOnly(now),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_publishAt),
    );
    if (t == null || !mounted) return;
    setState(() {
      _publishAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      _error = null;
    });
  }

  Announcement _draft(AppState app, InfoStatus status) {
    final e = widget.editing;
    final DateTime at;
    if (_timeLocked) {
      at = e!.at;
    } else if (_scheduled) {
      at = _publishAt;
    } else {
      at = DateTime.now();
    }
    return Announcement(
      _category,
      _title.text.trim(),
      e?.views ?? 0,
      at,
      id: e?.id ?? app.newAnnouncementId(),
      body: _body.text.trim(),
      targetUserId: _toAll ? null : _memberId,
      isBanner: _banner,
      validUntil: _validUntil,
      status: status,
    );
  }

  Future<void> _submit(InfoStatus status) async {
    final app = context.read<AppState>();
    if (!_toAll && _memberId == null) {
      setState(() => _error = 'Pilih member tujuan');
      return;
    }
    final publishing = status == InfoStatus.published;
    final scheduling = publishing && !_timeLocked && _scheduled;
    if (scheduling && !_publishAt.isAfter(DateTime.now())) {
      setState(() => _error = 'Waktu terbit harus di masa depan');
      return;
    }
    final draft = _draft(app, status);
    final err = app.validateAnnouncement(draft);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (publishing) {
      final who = _toAll
          ? 'semua member'
          : (app.userById(_memberId!)?.name ?? 'member terpilih');
      final ok = await confirmSheet(
        context,
        title: _wasPublished
            ? 'Simpan perubahan?'
            : (scheduling ? 'Jadwalkan informasi?' : 'Terbitkan informasi?'),
        message: scheduling
            ? 'Informasi akan tampil untuk $who pada ${fmtDate(_publishAt)}, ${fmtTime(_publishAt)}.'
            : 'Informasi langsung tampil di Pusat Informasi untuk $who.',
        confirmLabel: _wasPublished
            ? 'Ya, simpan'
            : (scheduling ? 'Ya, jadwalkan' : 'Ya, terbitkan'),
      );
      if (!ok || !mounted) return;
    }
    app.saveAnnouncement(draft);
    toast(
      context,
      !publishing
          ? 'Draft disimpan'
          : (_wasPublished
              ? 'Informasi diperbarui'
              : (scheduling ? 'Informasi dijadwalkan' : 'Informasi diterbitkan')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final selected = _memberId == null ? null : app.userById(_memberId!);
    final results = app.searchMembers(_q).take(5).toList();
    final totalMembers = app.members.length;

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 14),
          child: Text(t, style: AppText.body(12.5, weight: FontWeight.w700)),
        );

    InputDecoration deco([String? hint]) => InputDecoration(
          hintText: hint,
          hintStyle: AppText.body(13.5, color: AppColors.muted),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        );

    Widget dateBox(String text, VoidCallback onTap,
            {VoidCallback? onClear, bool placeholder = false}) =>
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(
                child: Text(text,
                    style: AppText.body(14,
                        color: placeholder ? AppColors.muted : AppColors.ink)),
              ),
              if (onClear != null)
                InkWell(
                  onTap: onClear,
                  child: const Icon(Icons.close, size: 20, color: AppColors.muted),
                )
              else
                const Icon(Icons.calendar_today_outlined,
                    size: 20, color: AppColors.tealDark),
            ]),
          ),
        );

    final previewTitle =
        _title.text.trim().isEmpty ? 'Judul informasi akan tampil di sini' : _title.text.trim();
    final previewMeta = [
      if (!_toAll) 'Khusus untuk ${selected?.name ?? 'member terpilih'}',
      '0x dilihat',
      (!_timeLocked && _scheduled)
          ? 'Terbit ${fmtDate(_publishAt, 'd MMM')}, ${fmtTime(_publishAt)}'
          : 'Baru saja',
    ].join(' • ');

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          AdminHeader(widget.editing == null ? 'Buat Informasi' : 'Ubah Informasi',
              subtitle: 'Tampil di Pusat Informasi member', showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                Text('Kirim ke siapa?', style: AppText.body(13.5, weight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _TargetCard(
                      icon: Icons.groups_outlined,
                      title: 'Semua member',
                      subtitle: 'Seluruh member terdaftar',
                      selected: _toAll,
                      onTap: () => setState(() {
                        _toAll = true;
                        _error = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TargetCard(
                      icon: Icons.person_outline,
                      title: 'Member tertentu',
                      subtitle: 'Pilih satu member tujuan',
                      selected: !_toAll,
                      onTap: () => setState(() {
                        _toAll = false;
                        _error = null;
                      }),
                    ),
                  ),
                ]),
                if (!_toAll) ...[
                  label('Cari member'),
                  SearchBox(
                    hint: 'Nama atau ID member (GYM-...)',
                    controller: _search,
                    onChanged: (v) => setState(() => _q = v),
                  ),
                  if (selected != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                        decoration: BoxDecoration(
                            color: AppColors.tealSoft,
                            borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(selected.name,
                                      style: AppText.body(13, weight: FontWeight.w800)),
                                  Text(
                                      '${selected.memberId} • ${statusLabel(app.statusOf(selected))}',
                                      style: AppText.body(11, color: AppColors.tealDark)),
                                ]),
                          ),
                          IconButton(
                            tooltip: 'Hapus pilihan',
                            onPressed: () => setState(() => _memberId = null),
                            icon: const Icon(Icons.close, size: 20, color: AppColors.tealDark),
                          ),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: results.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(18),
                            child: Center(
                                child: Text('Member tidak ditemukan',
                                    style: AppText.body(13, color: AppColors.muted))),
                          )
                        : Column(children: [
                            for (var i = 0; i < results.length; i++) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: MemberAvatar(results[i],
                                    size: 38, status: app.statusOf(results[i])),
                                title: Text(results[i].name,
                                    style: AppText.body(14, weight: FontWeight.w700)),
                                subtitle: Text(
                                    '${results[i].memberId} • ${statusLabel(app.statusOf(results[i]))}',
                                    style: AppText.body(12, color: AppColors.muted)),
                                trailing: Icon(
                                  _memberId == results[i].id
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: _memberId == results[i].id
                                      ? AppColors.tealDark
                                      : AppColors.muted,
                                ),
                                onTap: () => setState(() {
                                  _memberId = results[i].id;
                                  _error = null;
                                }),
                              ),
                              if (i < results.length - 1) const Divider(height: 1),
                            ],
                          ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                        'Menampilkan ${results.length} dari $totalMembers member. Ketik untuk mempersempit.',
                        style: AppText.body(11, color: AppColors.muted)),
                  ),
                ],
                label('Kategori'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in _kCategories)
                    PillChip(c,
                        selected: _category == c,
                        onTap: () => setState(() => _category = c)),
                ]),
                label('Judul'),
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: deco('Contoh: Jadwal operasional saat libur nasional'),
                ),
                label('Isi informasi'),
                TextField(
                  controller: _body,
                  minLines: 4,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: deco('Tulis detail informasi untuk member...'),
                ),
                label('Berlaku sampai (opsional, untuk promo)'),
                dateBox(
                  _validUntil == null ? 'Tanpa batas waktu' : fmtDate(_validUntil!),
                  _pickValid,
                  placeholder: _validUntil == null,
                  onClear: _validUntil == null
                      ? null
                      : () => setState(() => _validUntil = null),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Tampilkan sebagai banner',
                            style: AppText.body(13, weight: FontWeight.w700)),
                        Text('Muncul di bagian atas Pusat Informasi',
                            style: AppText.body(11.5, color: AppColors.muted)),
                      ]),
                    ),
                    Switch(
                      value: _banner,
                      activeThumbColor: AppColors.tealDark,
                      onChanged: (v) => setState(() => _banner = v),
                    ),
                  ]),
                ),
                if (!_timeLocked) ...[
                  label('Waktu terbit'),
                  Segmented(
                    labels: const ['Terbit sekarang', 'Jadwalkan'],
                    index: _scheduled ? 1 : 0,
                    onChanged: (i) => setState(() {
                      _scheduled = i == 1;
                      _error = null;
                    }),
                  ),
                  if (_scheduled) ...[
                    const SizedBox(height: 10),
                    dateBox(
                        '${fmtDate(_publishAt, 'EEE, d MMM yyyy')} • ${fmtTime(_publishAt)}',
                        _pickPublishAt),
                  ],
                ],
                const SizedBox(height: 18),
                Text('Pratinjau di layar member',
                    style: AppText.body(13.5, weight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (_banner) ...[
                  InfoBanner(
                    category: _category,
                    title: previewTitle,
                    body: _body.text.trim(),
                    validUntil: _validUntil,
                  ),
                  const SizedBox(height: 10),
                ],
                InfoTile(category: _category, title: previewTitle, meta: previewMeta),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!,
                        style: AppText.body(12.5, color: AppColors.danger)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: _wasPublished
                ? PrimaryButton('Simpan perubahan',
                    color: AppColors.tealDark,
                    onPressed: () => _submit(InfoStatus.published))
                : Row(children: [
                    Expanded(
                      child: PrimaryButton('Simpan draft',
                          outlined: true,
                          onPressed: () => _submit(InfoStatus.draft)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(_scheduled ? 'Jadwalkan' : 'Terbitkan',
                          color: AppColors.tealDark,
                          onPressed: () => _submit(InfoStatus.published)),
                    ),
                  ]),
          ),
        ]),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.ink;
    final sub = selected ? Colors.white70 : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 124),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected ? AppColors.navy : const Color(0xFFDDE5E4), width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: selected ? AppColors.teal : AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon,
                    size: 22, color: selected ? AppColors.navy : AppColors.tealDark),
              ),
              const Spacer(),
              if (selected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                      color: AppColors.teal, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 14, color: AppColors.navy),
                ),
            ]),
            const SizedBox(height: 12),
            Text(title, style: AppText.body(14, weight: FontWeight.w800, color: fg)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppText.body(11.5, color: sub)),
          ]),
        ),
      ),
    );
  }
}
