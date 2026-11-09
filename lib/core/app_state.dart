import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Semua logika bisnis + data sementara (in-memory).
///
/// Untuk produksi, ganti setiap bagian bertanda `// API:` dengan panggilan
/// ke backend (REST/Firebase/Supabase). UI tidak perlu diubah.
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  // ---------------------------------------------------------------- data
  final List<AppUser> _users = [];
  final Map<String, Membership> _memberships = {};
  final Map<String, Set<String>> _bookings = {};
  final Map<String, List<Target>> _targets = {};
  final Map<String, List<CheckIn>> _checkIns = {};
  final Map<String, List<Txn>> _txns = {};
  final List<GymClass> classes = [];
  final List<Announcement> announcements = [];
  final Map<String, int> bestStreak = {};
  final _rng = Random();

  // data admin
  final List<PlanOption> plans = List.of(kPlans);
  final List<BlockRecord> blocks = [];
  final List<FreezeRequest> freezeRequests = [];
  final List<Promo> promos = [];
  final List<LogEntry> logs = [];
  int _trxSeq = 2000;
  int _freezeRequestSeq = 0;
  int _scanCursor = 0;

  AppUser? currentUser;
  PendingPayment? pending;
  Txn? lastTxn;

  bool get isAdmin => currentUser?.role == Role.admin;
  String get uid => currentUser?.id ?? '';
  Membership? get membership => _memberships[uid];
  FreezeRequest? get pendingFreezeRequest => freezeRequests
      .where((r) => r.userId == uid && r.status == 'Menunggu')
      .firstOrNull;
  bool get hasActiveMembership => membership?.isActive ?? false;
  bool get isFrozen => membership?.isFrozen ?? false;

  /// Boleh check-in / booking hanya jika aktif dan tidak sedang dibekukan.
  bool get canUseGym =>
      hasActiveMembership && !isFrozen && !(currentUser?.blocked ?? false);

  List<Target> get targets => _targets[uid] ?? [];
  List<CheckIn> get checkIns =>
      List.of(_checkIns[uid] ?? [])..sort((a, b) => b.at.compareTo(a.at));
  List<Txn> get transactions =>
      List.of(_txns[uid] ?? [])..sort((a, b) => b.at.compareTo(a.at));

  // ---------------------------------------------------------------- seed
  void _seed() {
    final naufal = AppUser(
      id: 'u1',
      name: 'Naufal Badu',
      email: 'naufal@gmail.com',
      password: 'Gymku123',
      phone: '+62 831-7079-6020',
      gender: 'Laki-laki',
      birthDate: DateTime(2001, 5, 14),
      memberId: 'GYM-002145',
    );
    final baru = AppUser(
      id: 'u2',
      name: 'Tamu Baru',
      email: 'baru@gymku.id',
      password: 'Gymku123',
      memberId: 'GYM-002200',
    );
    final admin = AppUser(
      id: 'a1',
      name: 'admin',
      email: 'admin@gymku.id',
      password: 'admin123',
      memberId: 'ADMIN-001',
      role: Role.admin,
    );
    _users.addAll([naufal, baru, admin]);

    final end = today().add(const Duration(days: 142));
    _memberships['u1'] = Membership(
      planName: 'Premium',
      start: end.subtract(const Duration(days: 180)),
      end: end,
      totalDays: 180,
    );

    // check-in: 5 minggu lalu 4x/minggu, minggu ini 3x (maksimal sampai hari ini)
    final list = <CheckIn>[];
    final ws = startOfWeek(today());
    for (var w = 1; w <= 5; w++) {
      for (final wd in [1, 3, 5, 6]) {
        list.add(
          CheckIn(
            DateTime(
              ws.year,
              ws.month,
              ws.day - 7 * w + wd - 1,
              7 + _rng.nextInt(10),
              _rng.nextInt(60),
            ),
          ),
        );
      }
    }
    for (final wd in [1, 4, 6]) {
      final d = DateTime(ws.year, ws.month, ws.day + wd - 1, 8, 15);
      if (!d.isAfter(DateTime.now())) list.add(CheckIn(d));
    }
    _checkIns['u1'] = list;

    _targets['u1'] = [
      Target(
        id: 't1',
        name: 'Latihan rutin pagi',
        period: TargetPeriod.weekly,
        count: 4,
        days: {1, 3, 5, 6},
      ),
      Target(
        id: 't2',
        name: 'Target bulanan',
        period: TargetPeriod.monthly,
        count: 16,
      ),
    ];
    bestStreak['u1'] = 8;

    naufal.joinedAt = _memberships['u1']!.start;
    naufal.faceEnrolled = true;
    admin.joinedAt = DateTime.now();
    _txns['u1'] = [
      Txn(
        id: 'TRX-0098',
        planName: 'Premium 6 Bulan',
        method: 'QRIS',
        amount: 1700000,
        at: _memberships['u1']!.start,
        userId: 'u1',
        memberName: naufal.name,
        memberId: naufal.memberId,
        periodStart: _memberships['u1']!.start,
        periodEnd: _memberships['u1']!.end,
        planDays: 180,
      ),
    ];

    // kelas 7 hari ke depan
    final defs = [
      ('Morning Yoga', 'Studio A', 'Rina', 'Yoga', 7),
      ('Core & Abs', 'Studio B', 'Dimas', 'Core', 12),
      ('Yoga Flow', 'Studio A', 'Rina', 'Yoga', 17),
      ('HIIT Burn', 'Studio B', 'Dimas', 'HIIT', 19),
      ('Zumba Night', 'Studio A', 'Sari', 'Zumba', 20),
    ];
    for (var d = 0; d < 7; d++) {
      final day = today().add(Duration(days: d));
      for (var i = 0; i < defs.length; i++) {
        final c = defs[i];
        classes.add(
          GymClass(
            id: '${day.year}${day.month}${day.day}-$i',
            title: c.$1,
            studio: c.$2,
            coach: 'Coach ${c.$3}',
            category: c.$4,
            start: DateTime(day.year, day.month, day.day, c.$5),
            capacity: 10,
            bookedByOthers: (c.$1 == 'HIIT Burn' && d == 0)
                ? 10
                : 2 + (i * 2) % 6,
          ),
        );
      }
    }
    final yogaFlowToday = classes.firstWhere(
      (c) => c.title == 'Yoga Flow' && dateOnly(c.start) == today(),
    );
    _bookings['u1'] = {yogaFlowToday.id};

    _seedAdminData();

    announcements.addAll([
      Announcement(
        'Pengumuman',
        'Jadwal Operasional Gym saat Libur Nasional',
        1000,
        DateTime.now().subtract(const Duration(days: 7)),
      ),
      Announcement(
        'Kelas',
        'Kelas baru: Zumba Night setiap malam',
        640,
        DateTime.now().subtract(const Duration(days: 3)),
      ),
      Announcement(
        'Promo',
        'Perpanjang Member, Diskon 20%',
        2300,
        DateTime.now().subtract(const Duration(days: 1)),
        body: 'Gunakan kode GYMKU20 saat pembayaran',
        isBanner: true,
      ),
    ]);
  }

  // ---------------------------------------------------------------- auth
  // API: POST /auth/login
  String? login(String nameOrEmail, String password) {
    final key = nameOrEmail.trim().toLowerCase();
    if (key.isEmpty || password.isEmpty) return 'Nama dan password wajib diisi';
    final u = _users.where(
      (e) => e.name.toLowerCase() == key || e.email.toLowerCase() == key,
    );
    if (u.isEmpty) return 'Akun tidak ditemukan';
    if (u.first.password != password) return 'Password salah';
    currentUser = u.first;
    pending = null;
    notifyListeners();
    return null;
  }

  // API: POST /auth/register
  String? register(String name, String email, String password, String confirm) {
    if (name.trim().isEmpty) return 'Nama wajib diisi';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'Format email tidak valid';
    }
    final pwErr = validatePassword(password);
    if (pwErr != null) return pwErr;
    if (password != confirm) return 'Konfirmasi password tidak sama';
    final exists = _users.any(
      (u) =>
          u.email.toLowerCase() == email.trim().toLowerCase() ||
          u.name.toLowerCase() == name.trim().toLowerCase(),
    );
    if (exists) return 'Nama atau email sudah terdaftar';
    final n = 2300 + _users.length;
    final user = AppUser(
      id: 'u${_users.length + 1}',
      name: name.trim(),
      email: email.trim(),
      password: password,
      memberId: 'GYM-00$n',
    );
    _users.add(user);
    currentUser = user;
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    pending = null;
    notifyListeners();
  }

  /// Aturan password sesuai layar "Ganti Password".
  static String? validatePassword(String p) {
    if (p.length < 8) return 'Password minimal 8 karakter';
    if (!RegExp(r'[A-Za-z]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) {
      return 'Password harus mengandung huruf dan angka';
    }
    return null;
  }

  /// 0..4 untuk bar kekuatan password.
  static int passwordStrength(String p) {
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    if (p.length >= 12) s++;
    return s;
  }

  // API: PUT /me/password
  String? changePassword(String oldPw, String newPw, String confirm) {
    final u = currentUser!;
    if (oldPw != u.password) return 'Password saat ini salah';
    final err = validatePassword(newPw);
    if (err != null) return err;
    if (newPw == oldPw) return 'Password baru harus berbeda dari password lama';
    if (newPw != confirm) return 'Konfirmasi password tidak sama';
    u.password = newPw;
    notifyListeners();
    return null;
  }

  // API: PUT /me
  void updateProfile({
    String? name,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? gender,
  }) {
    final u = currentUser!;
    if (name != null) u.name = name.trim();
    if (email != null) u.email = email.trim();
    if (phone != null) u.phone = phone.trim();
    if (birthDate != null) u.birthDate = birthDate;
    if (gender != null) u.gender = gender;
    notifyListeners();
  }

  // ------------------------------------------------------------- classes
  List<GymClass> classesOn(DateTime day) {
    final l = classes.where((c) => dateOnly(c.start) == dateOnly(day)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return l;
  }

  bool isBooked(GymClass c) => (_bookings[uid] ?? {}).contains(c.id);
  int slotsLeft(GymClass c) =>
      c.capacity - c.bookedByOthers - (isBooked(c) ? 1 : 0);
  List<GymClass> get myBookings => classes.where((c) => isBooked(c)).toList();

  // API: POST /bookings
  String? book(GymClass c) {
    if (currentUser?.blocked ?? false) {
      return 'Akun kamu diblokir. Hubungi admin gym.';
    }
    if (!hasActiveMembership) return 'Membership kamu tidak aktif';
    if (isFrozen) return 'Booking dijeda selama membership dibekukan';
    if (c.start.isBefore(DateTime.now())) return 'Kelas sudah dimulai';
    if (slotsLeft(c) <= 0) return 'Kelas sudah penuh';
    final f = membership!.currentFreeze;
    if (f != null &&
        !dateOnly(c.start).isBefore(f.start) &&
        !dateOnly(c.start).isAfter(f.end)) {
      return 'Tanggal kelas berada dalam masa pembekuan';
    }
    (_bookings[uid] ??= {}).add(c.id);
    notifyListeners();
    return null;
  }

  // API: DELETE /bookings/:id
  String? cancelBooking(GymClass c) {
    if (c.start.difference(DateTime.now()).inMinutes < 60) {
      return 'Pembatalan maksimal 1 jam sebelum kelas dimulai';
    }
    _bookings[uid]?.remove(c.id);
    notifyListeners();
    return null;
  }

  // ------------------------------------------------------------ check-in
  int visitsBetween(DateTime from, DateTime to) => (_checkIns[uid] ?? [])
      .where((c) => !c.at.isBefore(from) && c.at.isBefore(to))
      .length;

  int get visitsThisMonth {
    final n = today();
    return visitsBetween(
      DateTime(n.year, n.month, 1),
      DateTime(n.year, n.month + 1, 1),
    );
  }

  int get activeDaysThisMonth {
    final n = today();
    final from = DateTime(n.year, n.month, 1);
    final to = DateTime(n.year, n.month + 1, 1);
    return (_checkIns[uid] ?? [])
        .where((c) => !c.at.isBefore(from) && c.at.isBefore(to))
        .map((c) => dateOnly(c.at))
        .toSet()
        .length;
  }

  /// Dipanggil dari layar scan wajah (tahap berikutnya).
  // API: POST /checkins
  String? checkInNow({String method = 'Check-in wajah'}) {
    if (currentUser?.blocked ?? false) {
      return 'Akun kamu diblokir. Hubungi admin gym.';
    }
    if (!hasActiveMembership) return 'Membership tidak aktif';
    if (isFrozen) return 'Check-in dijeda selama membership dibekukan';
    (_checkIns[uid] ??= []).add(CheckIn(DateTime.now(), method: method));
    notifyListeners();
    return null;
  }

  // ------------------------------------------------------- target/streak
  bool visitedOn(DateTime d) =>
      (_checkIns[uid] ?? []).any((c) => dateOnly(c.at) == dateOnly(d));

  List<bool> get weekDots {
    final ws = startOfWeek(today());
    return List.generate(
      7,
      (i) => visitedOn(DateTime(ws.year, ws.month, ws.day + i)),
    );
  }

  int targetProgress(Target t) {
    final n = today();
    if (t.period == TargetPeriod.weekly) {
      final ws = startOfWeek(n);
      return visitsBetween(ws, DateTime(ws.year, ws.month, ws.day + 7));
    }
    return visitsBetween(
      DateTime(n.year, n.month, 1),
      DateTime(n.year, n.month + 1, 1),
    );
  }

  Target? get weeklyTarget {
    for (final t in targets) {
      if (t.period == TargetPeriod.weekly) return t;
    }
    return null;
  }

  int get currentStreakWeeks {
    final goal = weeklyTarget?.count ?? 0;
    if (goal == 0) return 0;
    final ws = startOfWeek(today());
    var streak = 0;
    if (visitsBetween(ws, DateTime(ws.year, ws.month, ws.day + 7)) >= goal)
      streak++;
    for (var i = 1; i < 260; i++) {
      final a = DateTime(ws.year, ws.month, ws.day - 7 * i);
      final b = DateTime(a.year, a.month, a.day + 7);
      if (visitsBetween(a, b) >= goal) {
        streak++;
      } else {
        break;
      }
    }
    final best = bestStreak[uid] ?? 0;
    if (streak > best) bestStreak[uid] = streak;
    return streak;
  }

  int get bestStreakWeeks => max(bestStreak[uid] ?? 0, currentStreakWeeks);

  // API: POST /targets
  String? addTarget(Target t) {
    if (!hasActiveMembership) return 'Target hanya untuk member aktif';
    if (t.name.trim().isEmpty) return 'Nama target wajib diisi';
    final dup = targets.any((e) => e.period == t.period);
    if (dup) {
      return t.period == TargetPeriod.weekly
          ? 'Kamu sudah punya target mingguan. Hapus dulu untuk membuat yang baru.'
          : 'Kamu sudah punya target bulanan. Hapus dulu untuk membuat yang baru.';
    }
    (_targets[uid] ??= []).add(t);
    notifyListeners();
    return null;
  }

  // API: DELETE /targets/:id
  void deleteTarget(String id) {
    _targets[uid]?.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ------------------------------------------------------------- payment
  // API: POST /orders
  void startCheckout(PlanOption plan) {
    final promo = promoFor(plan, hasActiveMembership);
    pending = PendingPayment(
      plan: plan,
      trxId: 'TRX-${++_trxSeq}',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      discountPercent: promo?.type == PromoType.percent ? promo!.value : 0,
      nominalOff: promo?.type == PromoType.nominal ? promo!.value : 0,
      promoCode: promo?.name,
      autoPromoId: promo?.id,
    );
    notifyListeners();
  }

  void setPaymentMethod(String m) {
    pending?.method = m;
    notifyListeners();
  }

  /// Mengembalikan pesan error atau null jika kode valid.
  String? applyPromo(String code) {
    final p = pending;
    if (p == null) return 'Tidak ada transaksi';
    final pct = kPromoCodes[code.trim().toUpperCase()];
    if (pct == null) return 'Kode promo tidak valid';
    p.discountPercent = pct;
    p.nominalOff = 0;
    p.autoPromoId = null;
    p.promoCode = code.trim().toUpperCase();
    notifyListeners();
    return null;
  }

  void refreshExpiry() {
    final p = pending;
    if (p != null) {
      p.expiresAt = DateTime.now().add(const Duration(minutes: 15));
      notifyListeners();
    }
  }

  void cancelCheckout() {
    pending = null;
    notifyListeners();
  }

  /// Di produksi dipanggil oleh webhook payment gateway (Midtrans/Xendit),
  /// bukan oleh tombol di aplikasi.
  // API: GET /orders/:id (polling) atau push notification
  String? confirmPayment() {
    final p = pending;
    if (p == null) return 'Tidak ada transaksi';
    if (p.paid) return 'Pembayaran sudah dikonfirmasi';
    if (DateTime.now().isAfter(p.expiresAt)) return 'Waktu pembayaran habis';
    final m = membership;
    final periodStart = (m == null || !m.isActive) ? today() : m.end;
    final periodEnd = periodStart.add(Duration(days: p.plan.days));
    if (m == null || !m.isActive) {
      _memberships[uid] = Membership(
        planName: 'Premium',
        start: today(),
        end: today().add(Duration(days: p.plan.days)),
        totalDays: p.plan.days,
      );
    } else {
      m.end = m.end.add(Duration(days: p.plan.days));
      m.totalDays += p.plan.days;
    }
    final t = Txn(
      id: p.trxId,
      planName: 'Premium ${p.plan.name}',
      method: p.method,
      amount: p.total,
      at: DateTime.now(),
      userId: uid,
      memberName: currentUser!.name,
      memberId: currentUser!.memberId,
      basePrice: p.plan.price,
      discount: p.discount,
      promoLabel: p.discount > 0 ? p.promoCode : null,
      periodStart: periodStart,
      periodEnd: periodEnd,
      planDays: p.plan.days,
    );
    (_txns[uid] ??= []).add(t);
    lastTxn = t;
    for (final pr in promos) {
      if (pr.id == p.autoPromoId) pr.used++;
    }
    currentUser!.joinedAt ??= DateTime.now();
    _log(
      'payment',
      'Sistem mencatat pembayaran ${p.method}',
      '${currentUser!.name} · ${t.planName}',
    );
    p.paid = true; // pending dibiarkan agar layar tidak redirect saat transisi
    notifyListeners();
    return null;
  }

  // -------------------------------------------------------------- freeze
  /// Booking yang akan dibatalkan jika pembekuan [start]..[start+days-1].
  List<GymClass> bookingsAffectedByFreeze(DateTime start, int days) {
    return _bookingsAffectedByFreezeFor(uid, start, days);
  }

  List<GymClass> _bookingsAffectedByFreezeFor(
      String userId, DateTime start, int days) {
    final end = start.add(Duration(days: days - 1));
    return classes.where((c) => (_bookings[userId] ?? {}).contains(c.id)).where((c) {
      final d = dateOnly(c.start);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  // API: POST /membership/freeze-requests
  String? requestFreezeMembership(DateTime start, int days, String reason) {
    final m = membership;
    if (m == null || !m.isActive) return 'Membership tidak aktif';
    if (m.currentFreeze != null)
      return 'Membership sudah dibekukan / dijadwalkan beku';
    if (pendingFreezeRequest != null) {
      return 'Masih ada permintaan yang menunggu persetujuan admin';
    }
    if (days <= 0) return 'Lama pembekuan tidak valid';
    if (days > m.freezeDaysAvailable) {
      return 'Sisa jatah beku hanya ${m.freezeDaysAvailable} hari';
    }
    if (dateOnly(start).isBefore(today()))
      return 'Tanggal mulai tidak boleh di masa lalu';
    if (reason.trim().isEmpty) return 'Alasan pembekuan wajib diisi';
    freezeRequests.add(
      FreezeRequest(
        id: 'fr-${DateTime.now().microsecondsSinceEpoch}-${_freezeRequestSeq++}',
        userId: uid,
        type: FreezeRequestType.freeze,
        reason: reason.trim(),
        since: dateOnly(start),
        requestedAt: DateTime.now(),
        days: days,
      ),
    );
    notifyListeners();
    return null;
  }

  String? _applyFreezeFor(
      String userId, DateTime start, int days, String reason) {
    final m = _memberships[userId];
    if (m == null || !m.isActive) return 'Membership tidak aktif';
    if (m.currentFreeze != null) {
      return 'Membership sudah dibekukan / dijadwalkan beku';
    }
    if (days <= 0) return 'Lama pembekuan tidak valid';
    if (days > m.freezeDaysAvailable) {
      return 'Sisa jatah beku hanya ${m.freezeDaysAvailable} hari';
    }
    final s = dateOnly(start);
    if (s.isBefore(today())) return 'Tanggal mulai permintaan sudah lewat';
    for (final c in _bookingsAffectedByFreezeFor(userId, s, days)) {
      _bookings[userId]?.remove(c.id);
    }
    final remainingAtStart = max(0, m.end.difference(s).inDays);
    m.freeze = FreezeRecord(
      start: s,
      end: s.add(Duration(days: days - 1)),
      reason: reason,
      remainingAtStart: remainingAtStart,
    );
    m.freezeDaysUsed += days;
    m.end = m.end.add(Duration(days: days));
    notifyListeners();
    return null;
  }

  // API: POST /membership/unfreeze-requests
  String? requestUnfreezeMembership() {
    final m = membership;
    final f = m?.currentFreeze;
    if (m == null || f == null) return 'Tidak ada pembekuan aktif';
    if (pendingFreezeRequest != null) {
      return 'Masih ada permintaan yang menunggu persetujuan admin';
    }
    freezeRequests.add(
      FreezeRequest(
        id: 'fr-${DateTime.now().microsecondsSinceEpoch}-${_freezeRequestSeq++}',
        userId: uid,
        type: FreezeRequestType.unfreeze,
        reason: f.reason,
        since: f.start,
        requestedAt: DateTime.now(),
        days: m.isFreezeScheduled ? f.length : m.freezeDaysLeft,
      ),
    );
    notifyListeners();
    return null;
  }

  String? _unfreezeFor(String userId) {
    final m = _memberships[userId];
    final f = m?.currentFreeze;
    if (m == null || f == null) return 'Tidak ada pembekuan aktif';
    final scheduled = today().isBefore(f.start);
    final unused = scheduled
        ? f.length
        : max(0, f.end.difference(today()).inDays + 1);
    m.end = m.end.subtract(Duration(days: unused));
    m.freezeDaysUsed = max(0, m.freezeDaysUsed - unused);
    // pembekuan dibatalkan / diakhiri lebih awal
    m.freeze = null;
    notifyListeners();
    return null;
  }

  // ======================================================================
  // ADMIN
  // ======================================================================
  void _log(String kind, String text, [String detail = '']) {
    logs.insert(0, LogEntry(kind, text, DateTime.now(), detail));
    if (logs.length > 200) logs.removeLast();
  }

  String get _adminName => currentUser?.name ?? 'admin';

  void _seedAdminData() {
    final r = Random(7);
    final now = DateTime.now();
    final t0 = today();

    // nama, id, gender, umur, total hari, sisa hari, hari sejak kunjungan
    // terakhir, frekuensi kunjungan harian, status khusus
    final seeds = <_MemberSeed>[
      _MemberSeed('Naufal Hakim', 'GYM-000359', 'Laki-laki', 21, 90, 5, 1, .55),
      _MemberSeed(
        'Naufalia Putri',
        'GYM-000211',
        'Perempuan',
        19,
        30,
        -4,
        6,
        .4,
      ),
      _MemberSeed('Andi Rahman', 'GYM-000511', 'Laki-laki', 23, 90, 72, 1, .6),
      _MemberSeed(
        'Agus Setiawan',
        'GYM-001204',
        'Laki-laki',
        30,
        90,
        40,
        12,
        .3,
        blockReason: 'Meminjamkan akun ke orang lain',
      ),
      _MemberSeed(
        'Lukman Maulana',
        'GYM-000932',
        'Laki-laki',
        27,
        30,
        12,
        20,
        .3,
        blockReason: 'Membuat keributan di area gym',
      ),
      _MemberSeed(
        'Dewi Sartika',
        'GYM-000774',
        'Perempuan',
        26,
        90,
        50,
        5,
        .5,
        freezeReason: 'Perjalanan dinas',
      ),
      _MemberSeed(
        'Fajar Hidayat',
        'GYM-001102',
        'Laki-laki',
        29,
        90,
        60,
        6,
        .5,
        freezeReason: 'Sakit atau cedera',
      ),
      _MemberSeed(
        'Naufal Yaw',
        'GYM-111111',
        'Laki-laki',
        25,
        180,
        120,
        7,
        .5,
        freezeReason: 'Pindah kota sementara',
      ),
      _MemberSeed(
        'Rizky Pratama',
        'GYM-000388',
        'Laki-laki',
        24,
        180,
        100,
        40,
        .15,
        face: false,
      ),
      _MemberSeed(
        'Siti Aisyah',
        'GYM-000215',
        'Perempuan',
        22,
        360,
        200,
        35,
        .15,
      ),
      _MemberSeed(
        'Dimas Prakoso',
        'GYM-000640',
        'Laki-laki',
        31,
        30,
        30,
        0,
        1,
        joinedToday: true,
      ),
    ];

    var n = 0;
    for (final s in seeds) {
      n++;
      final u = AppUser(
        id: 'm$n',
        name: s.name,
        email: '${s.name.toLowerCase().replaceAll(' ', '.')}@email.com',
        password: 'Gymku123',
        memberId: s.gid,
        phone: '0812 ${3000 + r.nextInt(6999)} ${1000 + r.nextInt(8999)}',
        gender: s.gender,
        birthDate: DateTime(
          t0.year - s.age,
          1 + r.nextInt(12),
          1 + r.nextInt(27),
        ),
      )..faceEnrolled = s.face;
      _users.add(u);

      // membership
      late Membership m;
      if (s.freezeReason != null) {
        final fs = t0.subtract(const Duration(days: 3));
        final oldEnd = fs.add(Duration(days: s.remaining));
        const freezeLen = 20;
        m =
            Membership(
                planName: 'Premium',
                start: oldEnd
                    .add(const Duration(days: freezeLen))
                    .subtract(Duration(days: s.total)),
                end: oldEnd.add(const Duration(days: freezeLen)),
                totalDays: s.total,
              )
              ..freeze = FreezeRecord(
                start: fs,
                end: fs.add(const Duration(days: freezeLen - 1)),
                reason: s.freezeReason!,
                remainingAtStart: s.remaining,
              )
              ..freezeDaysUsed = freezeLen;
        freezeRequests.add(
          FreezeRequest(
            id: 'fr$n',
            userId: u.id,
            type: FreezeRequestType.unfreeze,
            reason: s.freezeReason!,
            since: fs,
            requestedAt: now.subtract(Duration(hours: 1 + n)),
          ),
        );
      } else {
        final end = t0.add(Duration(days: s.remaining));
        m = Membership(
          planName: 'Premium',
          start: end.subtract(Duration(days: s.total)),
          end: end,
          totalDays: s.total,
        );
      }
      _memberships[u.id] = m;

      // transaksi: pembelian terakhir + beberapa pembelian lama
      PlanOption planByDays(int d) =>
          kPlans.firstWhere((p) => p.days == d, orElse: () => kPlans[0]);
      final txns = <Txn>[];
      Txn mk(DateTime at, PlanOption pl, int idx) => Txn(
        id: 'TRX-${1000 + n * 10 + idx}',
        planName: 'Premium ${pl.name}',
        method: ['QRIS', 'Transfer Bank', 'E-Wallet'][r.nextInt(3)],
        amount: pl.price,
        at: at,
        userId: u.id,
        memberName: u.name,
        memberId: u.memberId,
        periodStart: dateOnly(at),
        periodEnd: dateOnly(at).add(Duration(days: pl.days)),
        planDays: pl.days,
      );
      final lastAt = s.joinedToday
          ? now
          : m.start.add(const Duration(hours: 10));
      txns.add(mk(lastAt, planByDays(s.total), 0));
      if (!s.joinedToday) {
        for (var i = 1; i <= 2 + r.nextInt(2); i++) {
          final at = lastAt.subtract(Duration(days: 20 * i + r.nextInt(25)));
          if (now.difference(at).inDays > 170) continue;
          txns.add(mk(at, kPlans[r.nextInt(4)], i));
        }
      }
      _txns[u.id] = txns;
      u.joinedAt = txns
          .map((e) => e.at)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      // check-in 150 hari ke belakang
      final list = <CheckIn>[];
      final f = m.freeze;
      for (var d = s.lastVisitAgo; d < 150; d++) {
        final day = t0.subtract(Duration(days: d));
        if (s.joinedToday) break;
        if (r.nextDouble() > s.freq) continue;
        if (f != null && !day.isBefore(f.start) && !day.isAfter(f.end))
          continue;
        var hour = r.nextBool() ? 17 + r.nextInt(3) : 6 + r.nextInt(15);
        var minute = r.nextInt(60);
        if (d == 0) {
          if (now.hour < 7) continue;
          hour = 6 + r.nextInt(now.hour - 5);
          if (hour == now.hour) minute = r.nextInt(now.minute + 1);
        }
        list.add(CheckIn(DateTime(day.year, day.month, day.day, hour, minute)));
      }
      _checkIns[u.id] = list;

      if (s.blockReason != null) {
        u.blocked = true;
        blocks.add(
          BlockRecord(
            userId: u.id,
            reason: s.blockReason!,
            by: 'Rina',
            at: now.subtract(Duration(days: 3 + n)),
          ),
        );
      }
    }

    // riwayat blokir yang sudah dibuka
    final reopened =
        BlockRecord(
            userId: 'm1',
            reason: 'Terlambat membayar denda',
            by: 'Rina',
            at: now.subtract(const Duration(days: 40)),
          )
          ..active = false
          ..unblockNote = 'Denda sudah dilunasi'
          ..unblockAt = now.subtract(const Duration(days: 35));
    blocks.add(reopened);

    // promo
    promos.addAll([
      Promo(
        id: 'p1',
        name: 'Perpanjang member, diskon 20%',
        type: PromoType.percent,
        value: 20,
        quota: 100,
        planIds: {'3m', '6m', '12m'},
        renewalOnly: true,
        start: t0.subtract(const Duration(days: 5)),
        end: t0.add(const Duration(days: 25)),
      )..used = 38,
      Promo(
        id: 'p2',
        name: 'Promo Tahun Baru, potongan Rp 100.000',
        type: PromoType.nominal,
        value: 100000,
        quota: 50,
        planIds: {'1m', '3m', '6m', '12m'},
        renewalOnly: false,
        start: t0.add(const Duration(days: 60)),
        end: t0.add(const Duration(days: 67)),
      ),
    ]);

    // log aktivitas awal
    logs.addAll([
      LogEntry(
        'price',
        'Admin mengubah harga paket',
        now.subtract(const Duration(hours: 5)),
        'Rp 330.000 → Rp 350.000',
      ),
      LogEntry(
        'payment',
        'Sistem mencatat pembayaran QRIS',
        now.subtract(const Duration(hours: 4)),
        'Naufal Badu · Premium 3 Bulan',
      ),
      LogEntry(
        'checkin',
        'Admin check-in manual member',
        now.subtract(const Duration(hours: 3)),
        'GYM-001873 · wajah tidak terbaca',
      ),
      LogEntry(
        'block',
        'Admin memblokir member',
        now.subtract(const Duration(days: 1)),
        'GYM-001204 · Kemarin',
      ),
    ]);
  }

  // ------------------------------------------------------------- lookup
  List<AppUser> get members =>
      _users.where((u) => u.role == Role.member).toList();

  AppUser? userById(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  Membership? membershipOf(String id) => _memberships[id];

  List<CheckIn> checkInsOf(String id) =>
      List.of(_checkIns[id] ?? [])..sort((a, b) => b.at.compareTo(a.at));

  List<Txn> txnsOf(String id) =>
      List.of(_txns[id] ?? [])..sort((a, b) => b.at.compareTo(a.at));

  List<Txn> get allTxns =>
      (_txns.values.expand((e) => e).toList())
        ..sort((a, b) => b.at.compareTo(a.at));

  Iterable<CheckIn> get _allCheckIns => _checkIns.values.expand((e) => e);

  DateTime? lastVisitOf(String id) {
    final l = checkInsOf(id);
    return l.isEmpty ? null : l.first.at;
  }

  int visitsInMonthOf(String id, DateTime month) => (_checkIns[id] ?? [])
      .where((c) => c.at.year == month.year && c.at.month == month.month)
      .length;

  MemberStatus statusOf(AppUser u) {
    if (u.blocked) return MemberStatus.blocked;
    final m = _memberships[u.id];
    if (m == null) return MemberStatus.none;
    if (m.isFrozen) return MemberStatus.frozen;
    if (!m.isActive) return MemberStatus.expired;
    if (m.remainingDays <= 7) return MemberStatus.expiring;
    return MemberStatus.active;
  }

  BlockRecord? activeBlockOf(String id) {
    for (final b in blocks.reversed) {
      if (b.userId == id && b.active) return b;
    }
    return null;
  }

  List<BlockRecord> get activeBlocks =>
      blocks.where((b) => b.active).toList().reversed.toList();

  List<BlockRecord> get reopenedBlocks =>
      blocks.where((b) => !b.active).toList().reversed.toList();

  /// Pencarian + filter untuk daftar / cari member.
  List<AppUser> searchMembers(
    String q, {
    MemberStatus? status,
    String? gender,
  }) {
    final k = q.trim().toLowerCase();
    return members.where((u) {
      if (k.isNotEmpty &&
          !(u.name.toLowerCase().contains(k) ||
              u.email.toLowerCase().contains(k) ||
              u.memberId.toLowerCase().contains(k))) {
        return false;
      }
      if (status != null && statusOf(u) != status) return false;
      if (gender != null && u.gender != gender) return false;
      return true;
    }).toList();
  }

  // ---------------------------------------------------- dashboard/laporan
  int get activeMemberCount => members.where((u) {
    final s = statusOf(u);
    return s == MemberStatus.active || s == MemberStatus.expiring;
  }).length;

  int get blockedCount => members.where((u) => u.blocked).length;

  int get newMembersToday => members
      .where((u) => u.joinedAt != null && dateOnly(u.joinedAt!) == today())
      .length;

  List<AppUser> get expiringMembers =>
      members.where((u) => statusOf(u) == MemberStatus.expiring).toList();

  int get visitsToday =>
      _allCheckIns.where((c) => dateOnly(c.at) == today()).length;

  int get visitsYesterday {
    final y = today().subtract(const Duration(days: 1));
    return _allCheckIns.where((c) => dateOnly(c.at) == y).length;
  }

  int revenueBetween(DateTime from, DateTime to) => allTxns
      .where(
        (t) =>
            t.status == 'Berhasil' && !t.at.isBefore(from) && t.at.isBefore(to),
      )
      .fold(0, (a, t) => a + t.amount);

  int get revenue30 => revenueBetween(
    today().subtract(const Duration(days: 29)),
    today().add(const Duration(days: 1)),
  );

  int get revenuePrev30 => revenueBetween(
    today().subtract(const Duration(days: 59)),
    today().subtract(const Duration(days: 29)),
  );

  /// Rata-rata kunjungan per jam (14 hari terakhir), bucket 2 jam: 6..20.
  List<int> get hourlyBuckets {
    final from = today().subtract(const Duration(days: 13));
    final out = List.filled(8, 0);
    for (final c in _allCheckIns) {
      if (c.at.isBefore(from)) continue;
      final i = ((c.at.hour - 6) ~/ 2).clamp(0, 7);
      out[i]++;
    }
    return out;
  }

  List<DateTime> get reportMonths {
    final n = today();
    return List.generate(6, (i) => DateTime(n.year, n.month - i, 1));
  }

  int visitsInMonth(DateTime m) => _allCheckIns
      .where((c) => c.at.year == m.year && c.at.month == m.month)
      .length;

  int revenueInMonth(DateTime m) => revenueBetween(
    DateTime(m.year, m.month, 1),
    DateTime(m.year, m.month + 1, 1),
  );

  /// 4 kolom: tgl 1-7, 8-14, 15-21, 22-akhir.
  List<int> weeklyVisits(DateTime m) {
    final out = List.filled(4, 0);
    for (final c in _allCheckIns) {
      if (c.at.year != m.year || c.at.month != m.month) continue;
      out[((c.at.day - 1) ~/ 7).clamp(0, 3)]++;
    }
    return out;
  }

  /// Member aktif yang sudah [days] hari atau lebih tidak datang.
  List<({AppUser user, int days})> inactiveMembers({int days = 30}) {
    final out = <({AppUser user, int days})>[];
    for (final u in members) {
      final s = statusOf(u);
      if (s != MemberStatus.active && s != MemberStatus.expiring) continue;
      final last = lastVisitOf(u.id);
      final d = last == null ? 999 : today().difference(dateOnly(last)).inDays;
      if (d >= days) out.add((user: u, days: d));
    }
    out.sort((a, b) => b.days.compareTo(a.days));
    return out;
  }

  // ------------------------------------------------------------- scan wajah
  /// SIMULASI pengenalan wajah: memilih member yang wajahnya terdaftar secara
  /// bergiliran. Untuk produksi, ganti dengan layanan pengenal wajah sungguhan
  /// (kirim foto hasil tangkapan kamera ke server dan terima member yang cocok).
  AppUser? recognizeFace() {
    final c = members.where((u) => u.hasFace).toList();
    if (c.isEmpty) return null;
    final u = c[_scanCursor % c.length];
    _scanCursor++;
    return u;
  }

  /// Alasan member TIDAK boleh masuk (null = boleh).
  String? entryDeniedReason(AppUser u) {
    if (u.blocked)
      return 'Akun diblokir: ${activeBlockOf(u.id)?.reason ?? '-'}';
    final m = _memberships[u.id];
    if (m == null) return 'Member belum punya paket';
    if (m.isFrozen) return 'Membership sedang dibekukan';
    if (!m.isActive) return 'Membership sudah berakhir';
    return null;
  }

  // API: POST /admin/checkins
  String? adminCheckIn(AppUser u, {String method = 'Check-in wajah'}) {
    final why = entryDeniedReason(u);
    if (why != null) return why;
    final last = lastVisitOf(u.id);
    if (last != null && DateTime.now().difference(last).inMinutes < 2) {
      return '${u.name} baru saja check-in';
    }
    (_checkIns[u.id] ??= []).add(CheckIn(DateTime.now(), method: method));
    _log(
      'checkin',
      method == 'Check-in wajah'
          ? 'Admin mengizinkan masuk (scan wajah)'
          : 'Admin check-in manual member',
      '${u.memberId} · ${u.name}',
    );
    notifyListeners();
    return null;
  }

  // ----------------------------------------------------------- blokir
  // API: POST /admin/members/:id/block
  String? blockMember(String id, String reason) {
    final u = userById(id);
    if (u == null) return 'Member tidak ditemukan';
    if (u.blocked) return 'Member sudah diblokir';
    if (reason.trim().isEmpty) return 'Alasan pemblokiran wajib diisi';
    u.blocked = true;
    blocks.add(
      BlockRecord(
        userId: id,
        reason: reason.trim(),
        by: _adminName,
        at: DateTime.now(),
      ),
    );
    _log('block', 'Admin memblokir member', '${u.memberId} · ${u.name}');
    notifyListeners();
    return null;
  }

  // API: POST /admin/members/:id/unblock
  String? unblockMember(String id, String note) {
    final u = userById(id);
    final b = activeBlockOf(id);
    if (u == null || b == null) return 'Member tidak sedang diblokir';
    u.blocked = false;
    b.active = false;
    b.unblockNote = note.trim().isEmpty ? null : note.trim();
    b.unblockAt = DateTime.now();
    _log('unblock', 'Admin membuka blokir member', '${u.memberId} · ${u.name}');
    notifyListeners();
    return null;
  }

  // ------------------------------------------------------- permintaan beku
  List<FreezeRequest> freezeRequestsBy(String status) =>
      freezeRequests.where((r) => r.status == status).toList();

  // API: POST /admin/freeze-requests/:id/decision
  String? decideFreezeRequest(String id, bool approve) {
    if (!isAdmin) return 'Hanya admin yang dapat memproses permintaan';
    final r = freezeRequests.where((e) => e.id == id).firstOrNull;
    if (r == null) return 'Permintaan tidak ditemukan';
    if (r.status != 'Menunggu') return 'Permintaan sudah diproses';
    final u = userById(r.userId);
    if (approve) {
      final err = switch (r.type) {
        FreezeRequestType.freeze =>
          _applyFreezeFor(r.userId, r.since, r.days, r.reason),
        FreezeRequestType.unfreeze => _unfreezeFor(r.userId),
      };
      if (err != null) return err;
      r.status = 'Disetujui';
    } else {
      r.status = 'Ditolak';
    }
    _log(
      'freeze',
      switch ((r.type, approve)) {
        (FreezeRequestType.freeze, true) => 'Admin menyetujui pembekuan',
        (FreezeRequestType.freeze, false) => 'Admin menolak pembekuan',
        (FreezeRequestType.unfreeze, true) => 'Admin menyetujui buka bekuan',
        (FreezeRequestType.unfreeze, false) => 'Admin menolak buka bekuan',
      },
      '${u?.memberId ?? ''} · ${u?.name ?? ''}',
    );
    notifyListeners();
    return null;
  }

  // -------------------------------------------------------------- paket
  List<PlanOption> get activePlans => plans.where((p) => p.enabled).toList();

  // API: PUT /admin/plans/:id
  String? updatePlanPrice(String id, int price) {
    if (price < 50000) return 'Harga minimal Rp 50.000';
    final i = plans.indexWhere((p) => p.id == id);
    if (i < 0) return 'Paket tidak ditemukan';
    final old = plans[i].price;
    if (old == price) return 'Harga baru sama dengan harga sekarang';
    plans[i] = plans[i].copyWith(price: price);
    _log(
      'price',
      'Admin mengubah harga paket',
      '${plans[i].name}: Rp $old → Rp $price',
    );
    notifyListeners();
    return null;
  }

  String? setPlanEnabled(String id, bool on) {
    final i = plans.indexWhere((p) => p.id == id);
    if (i < 0) return 'Paket tidak ditemukan';
    if (!on && activePlans.length <= 1 && plans[i].enabled) {
      return 'Minimal satu paket harus aktif';
    }
    plans[i] = plans[i].copyWith(enabled: on);
    _log(
      'price',
      on ? 'Admin mengaktifkan paket' : 'Admin menonaktifkan paket',
      plans[i].name,
    );
    notifyListeners();
    return null;
  }

  // -------------------------------------------------------------- promo
  Promo? promoFor(PlanOption plan, bool isRenewal) {
    Promo? best;
    for (final p in promos) {
      if (!p.isRunning) continue;
      if (!p.planIds.contains(plan.id)) continue;
      if (p.renewalOnly && !isRenewal) continue;
      if (best == null ||
          p.discountFor(plan.price) > best.discountFor(plan.price)) {
        best = p;
      }
    }
    return best;
  }

  String? validatePromo(Promo p) {
    if (p.name.trim().isEmpty) return 'Nama promo wajib diisi';
    if (p.value <= 0) return 'Nilai diskon harus lebih dari 0';
    if (p.type == PromoType.percent && p.value > 100) {
      return 'Diskon persen maksimal 100%';
    }
    if (p.quota <= 0) return 'Kuota harus lebih dari 0';
    if (p.planIds.isEmpty) return 'Pilih minimal satu paket';
    if (dateOnly(p.end).isBefore(dateOnly(p.start))) {
      return 'Tanggal selesai harus setelah tanggal mulai';
    }
    return null;
  }

  // API: POST /admin/promos
  String? addPromo(Promo p) {
    final err = validatePromo(p);
    if (err != null) return err;
    promos.add(p);
    _log('promo', 'Admin membuat promo', p.name);
    notifyListeners();
    return null;
  }

  String? updatePromo(Promo p) {
    final err = validatePromo(p);
    if (err != null) return err;
    _log('promo', 'Admin mengubah promo', p.name);
    notifyListeners();
    return null;
  }

  void endPromo(String id) {
    final p = promos.where((e) => e.id == id).firstOrNull;
    if (p == null) return;
    p.endedManually = true;
    _log('promo', 'Admin mengakhiri promo', p.name);
    notifyListeners();
  }

  void setPromoEnabled(String id, bool on) {
    final p = promos.where((e) => e.id == id).firstOrNull;
    if (p == null) return;
    p.enabled = on;
    notifyListeners();
  }

  String newPromoId() => 'p${DateTime.now().microsecondsSinceEpoch}';

  // ------------------------------------------------------------- informasi
  /// Informasi yang tampil untuk member yang sedang login, terbaru dulu.
  List<Announcement> get visibleAnnouncements =>
      announcements.where((a) => a.isLive && a.isFor(uid)).toList()
        ..sort((a, b) => b.at.compareTo(a.at));

  /// Banner terbaru untuk member yang sedang login (null = tidak ada banner).
  Announcement? get activeBanner =>
      visibleAnnouncements.where((a) => a.isBanner).firstOrNull;

  /// Semua informasi (termasuk draft/terjadwal/arsip) untuk admin.
  List<Announcement> get allAnnouncements =>
      List.of(announcements)..sort((a, b) => b.at.compareTo(a.at));

  String newAnnouncementId() => 'a${DateTime.now().microsecondsSinceEpoch}';

  String? validateAnnouncement(Announcement a) {
    if (a.title.trim().isEmpty) return 'Judul wajib diisi';
    if (a.status != InfoStatus.draft && a.body.trim().isEmpty) {
      return 'Isi informasi wajib diisi';
    }
    if (a.targetUserId != null && userById(a.targetUserId!) == null) {
      return 'Member tujuan tidak ditemukan';
    }
    final v = a.validUntil;
    if (v != null && dateOnly(v).isBefore(dateOnly(a.at))) {
      return 'Tanggal berlaku harus sama atau setelah tanggal terbit';
    }
    return null;
  }

  /// Menyimpan informasi baru atau memperbarui yang sudah ada (id sama).
  // API: POST /admin/announcements, PUT /admin/announcements/:id
  String? saveAnnouncement(Announcement draft) {
    final err = validateAnnouncement(draft);
    if (err != null) return err;
    final i = announcements.indexWhere((e) => e.id == draft.id);
    final isNew = i < 0;
    if (isNew) {
      announcements.add(draft);
    } else {
      announcements[i].assign(draft);
    }
    final target = draft.targetUserId == null
        ? 'semua member'
        : (userById(draft.targetUserId!)?.name ?? 'member');
    _log(
      'info',
      isNew ? 'Admin membuat informasi' : 'Admin mengubah informasi',
      '${draft.title} · $target',
    );
    notifyListeners();
    return null;
  }

  // API: PATCH /admin/announcements/:id
  void setAnnouncementArchived(String id, bool archived) {
    final a = announcements.where((e) => e.id == id).firstOrNull;
    if (a == null) return;
    a.status = archived ? InfoStatus.archived : InfoStatus.published;
    _log('info', archived ? 'Admin mengarsipkan informasi' : 'Admin menampilkan kembali informasi', a.title);
    notifyListeners();
  }

  // API: DELETE /admin/announcements/:id
  void deleteAnnouncement(String id) {
    final a = announcements.where((e) => e.id == id).firstOrNull;
    if (a == null) return;
    announcements.remove(a);
    _log('info', 'Admin menghapus informasi', a.title);
    notifyListeners();
  }

  /// Dipanggil saat member membuka detail informasi.
  // API: POST /announcements/:id/view
  void markAnnouncementViewed(String id) {
    final a = announcements.where((e) => e.id == id).firstOrNull;
    if (a == null) return;
    a.views++;
    notifyListeners();
  }

  // ---------------------------------------------------------- wajah member
  // API: POST /me/face
  void enrollFace(Uint8List bytes) {
    final u = currentUser;
    if (u == null) return;
    u.faceBytes = bytes;
    u.faceEnrolled = true;
    notifyListeners();
  }
}

class _MemberSeed {
  _MemberSeed(
    this.name,
    this.gid,
    this.gender,
    this.age,
    this.total,
    this.remaining,
    this.lastVisitAgo,
    this.freq, {
    this.blockReason,
    this.freezeReason,
    this.face = true,
    this.joinedToday = false,
  });
  final String name, gid, gender;
  final int age, total, remaining, lastVisitAgo;
  final double freq;
  final String? blockReason, freezeReason;
  final bool face, joinedToday;
}
