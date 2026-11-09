import 'dart:math';
import 'dart:typed_data';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime today() => dateOnly(DateTime.now());
DateTime startOfWeek(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

enum Role { member, admin }

enum TargetPeriod { weekly, monthly }

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.memberId,
    this.phone = '',
    this.gender = '',
    this.birthDate,
    this.role = Role.member,
    this.joinedAt,
    this.faceBytes,
    this.blocked = false,
  });

  final String id;
  String name;
  String email;
  String password;
  String phone;
  String gender;
  DateTime? birthDate;
  final String memberId;
  final Role role;
  DateTime? joinedAt;

  /// Foto wajah terdaftar (disimpan di memori; di produksi simpan di server).
  Uint8List? faceBytes;
  bool blocked;
  bool faceEnrolled = false;
  bool get hasFace => faceEnrolled || faceBytes != null;

  String get initials {
    final p =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (p.isEmpty) return '?';
    if (p.length == 1) return p[0][0].toUpperCase();
    return (p[0][0] + p[1][0]).toUpperCase();
  }
}

class PlanOption {
  const PlanOption(this.id, this.name, this.days, this.price,
      {this.originalPrice, this.enabled = true});
  final String id;
  final String name;
  final int days;
  final int price;
  final int? originalPrice;
  final bool enabled;

  PlanOption copyWith({int? price, bool? enabled}) => PlanOption(
        id,
        name,
        days,
        price ?? this.price,
        originalPrice: originalPrice,
        enabled: enabled ?? this.enabled,
      );
}

const kPlans = [
  PlanOption('1m', '1 Bulan', 30, 350000),
  PlanOption('3m', '3 Bulan', 90, 900000),
  PlanOption('6m', '6 Bulan', 180, 1700000),
  PlanOption('12m', '1 Tahun', 360, 2999000, originalPrice: 3299000),
];

/// Kode promo contoh. Di produksi validasi HARUS dilakukan di server.
const kPromoCodes = <String, int>{'GYMKU20': 20, 'PROMO10': 10};

class FreezeRecord {
  FreezeRecord({
    required this.start,
    required this.end,
    required this.reason,
    required this.remainingAtStart,
  });
  final DateTime start;
  DateTime end; // inklusif
  final String reason;
  final int remainingAtStart;
  int get length => max(0, end.difference(start).inDays + 1);
}

class Membership {
  Membership({
    required this.planName,
    required this.start,
    required this.end,
    required this.totalDays,
  });

  String planName;
  DateTime start;
  DateTime end;
  int totalDays;
  FreezeRecord? freeze;
  int freezeDaysUsed = 0;
  static const maxFreezeDays = 30;

  FreezeRecord? get currentFreeze {
    final f = freeze;
    if (f == null) return null;
    return today().isAfter(f.end) ? null : f;
  }

  bool get isFrozen {
    final f = currentFreeze;
    return f != null && !today().isBefore(f.start);
  }

  bool get isFreezeScheduled => currentFreeze != null && !isFrozen;
  bool get isActive => !today().isAfter(end);

  int get remainingDays {
    final f = currentFreeze;
    if (f != null) {
      if (isFrozen) return f.remainingAtStart;
      return max(0, end.difference(today()).inDays - f.length);
    }
    return max(0, end.difference(today()).inDays);
  }

  int get freezeDaysLeft {
    final f = currentFreeze;
    if (f == null || !isFrozen) return 0;
    return max(0, f.end.difference(today()).inDays + 1);
  }

  int get freezeDaysAvailable => max(0, maxFreezeDays - freezeDaysUsed);

  double get progress =>
      totalDays == 0 ? 0 : (remainingDays / totalDays).clamp(0.0, 1.0);
}

class GymClass {
  GymClass({
    required this.id,
    required this.title,
    required this.studio,
    required this.coach,
    required this.category,
    required this.start,
    this.capacity = 10,
    this.bookedByOthers = 0,
  });
  final String id;
  final String title;
  final String studio;
  final String coach;
  final String category; // Yoga, HIIT, Zumba, Core
  final DateTime start;
  final int capacity;
  final int bookedByOthers;
}

class CheckIn {
  CheckIn(this.at,
      {this.area = 'Lantai Beban', this.method = 'Check-in wajah'});
  final DateTime at;
  final String area;
  final String method;
}

class Target {
  Target({
    required this.id,
    required this.name,
    required this.period,
    required this.count,
    this.days = const {},
    this.reminder = false,
    this.reminderHour = 10,
    this.reminderMinute = 0,
  });
  final String id;
  String name;
  TargetPeriod period;
  int count;
  Set<int> days; // 1=Senin ... 7=Minggu
  bool reminder;
  int reminderHour;
  int reminderMinute;
}

class Txn {
  Txn({
    required this.id,
    required this.planName,
    required this.method,
    required this.amount,
    required this.at,
    this.userId = '',
    this.memberName = '',
    this.memberId = '',
    int? basePrice,
    this.discount = 0,
    this.promoLabel,
    this.status = 'Berhasil',
    this.periodStart,
    this.periodEnd,
    this.planDays = 0,
  }) : basePrice = basePrice ?? amount;

  final String id;
  final String planName;
  final String method;
  final int amount; // total dibayar
  final DateTime at;
  final String userId;
  final String memberName;
  final String memberId;
  final int basePrice; // harga sebelum diskon
  final int discount;
  final String? promoLabel;
  final String status;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int planDays;

  /// Nomor struk, diturunkan dari ID transaksi dan tanggal.
  String get receiptNo =>
      'INV/${at.year}${at.month.toString().padLeft(2, '0')}${at.day.toString().padLeft(2, '0')}/$id';
}

class PendingPayment {
  PendingPayment({
    required this.plan,
    required this.trxId,
    required this.expiresAt,
    this.method = 'QRIS',
    this.discountPercent = 0,
    this.promoCode,
    this.nominalOff = 0,
    this.autoPromoId,
  });
  final PlanOption plan;
  final String trxId;
  DateTime expiresAt;
  String method;
  int discountPercent;
  int nominalOff;
  String? promoCode; // kode atau nama promo otomatis
  String? autoPromoId;
  bool paid = false;
  int get discount => min(plan.price,
      (plan.price * discountPercent / 100).round() + nominalOff);
  int get total => plan.price - discount;
}

enum InfoStatus { draft, published, archived }

class Announcement {
  Announcement(
    this.category,
    this.title,
    this.views,
    this.at, {
    String? id,
    this.body = '',
    this.targetUserId,
    this.isBanner = false,
    this.validUntil,
    this.status = InfoStatus.published,
  }) : id = id ?? 'a${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  /// Penghitung agar id tetap unik walau dibuat dalam waktu yang sama.
  static int _seq = 0;

  final String id;
  String category; // Pengumuman, Kelas, Promo
  String title;
  String body;
  int views;

  /// Waktu terbit. Bila di masa depan, informasi berstatus "terjadwal".
  DateTime at;

  /// null = untuk semua member; selain itu hanya untuk member dengan id ini.
  String? targetUserId;

  /// Tampil sebagai banner di atas Pusat Informasi member.
  bool isBanner;

  /// Tanggal terakhir tampil (inklusif). null = tanpa batas.
  DateTime? validUntil;
  InfoStatus status;

  bool get isForAll => targetUserId == null;
  bool isFor(String userId) => targetUserId == null || targetUserId == userId;

  bool get isScheduled =>
      status == InfoStatus.published && at.isAfter(DateTime.now());
  bool get isExpired =>
      validUntil != null && dateOnly(validUntil!).isBefore(today());

  /// Sedang tampil di layar member.
  bool get isLive =>
      status == InfoStatus.published && !isScheduled && !isExpired;

  /// Salin semua isian yang bisa diubah dari [o] (id tidak berubah).
  void assign(Announcement o) {
    category = o.category;
    title = o.title;
    body = o.body;
    at = o.at;
    targetUserId = o.targetUserId;
    isBanner = o.isBanner;
    validUntil = o.validUntil;
    status = o.status;
  }
}

// ================================================================== ADMIN

enum MemberStatus { active, expiring, expired, frozen, blocked, none }

String statusLabel(MemberStatus s) => switch (s) {
      MemberStatus.active => 'Aktif',
      MemberStatus.expiring => 'Akan berakhir',
      MemberStatus.expired => 'Berakhir',
      MemberStatus.frozen => 'Dibekukan',
      MemberStatus.blocked => 'Diblokir',
      MemberStatus.none => 'Belum member',
    };

class BlockRecord {
  BlockRecord({
    required this.userId,
    required this.reason,
    required this.by,
    required this.at,
  });
  final String userId;
  final String reason;
  final String by;
  final DateTime at;
  bool active = true;
  String? unblockNote;
  DateTime? unblockAt;
}

enum FreezeRequestType { freeze, unfreeze }

class FreezeRequest {
  FreezeRequest({
    required this.id,
    required this.userId,
    required this.type,
    required this.reason,
    required this.since,
    required this.requestedAt,
    this.days = 0,
  });
  final String id;
  final String userId;
  final FreezeRequestType type;
  final String reason;
  final DateTime since;
  final DateTime requestedAt;
  final int days;
  String status = 'Menunggu'; // Menunggu | Disetujui | Ditolak
}

enum PromoType { percent, nominal }

class Promo {
  Promo({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.quota,
    required this.planIds,
    required this.renewalOnly,
    required this.start,
    required this.end,
  });
  final String id;
  String name;
  PromoType type;
  int value;
  int quota;
  int used = 0;
  Set<String> planIds;
  bool renewalOnly;
  DateTime start;
  DateTime end; // inklusif
  bool enabled = true; // saklar (promo terjadwal)
  bool endedManually = false;

  bool get isRunning {
    final t = today();
    return enabled &&
        !endedManually &&
        !t.isBefore(dateOnly(start)) &&
        !t.isAfter(dateOnly(end)) &&
        used < quota;
  }

  bool get isScheduled =>
      !endedManually && today().isBefore(dateOnly(start));
  bool get isDone => !isRunning && !isScheduled;

  int discountFor(int price) => type == PromoType.percent
      ? (price * value / 100).round()
      : min(price, value);

  String get valueLabel =>
      type == PromoType.percent ? '$value%' : 'Rp $value';
}

class LogEntry {
  LogEntry(this.kind, this.text, this.at, [this.detail = '']);
  final String kind; // price, payment, checkin, block, unblock, promo, freeze
  final String text;
  final DateTime at;
  final String detail;
}
