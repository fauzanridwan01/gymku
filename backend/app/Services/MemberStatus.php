<?php

namespace App\Services;

use App\Models\User;

/** Status keanggotaan untuk tampilan admin (sama dengan MemberStatus di aplikasi). */
class MemberStatus
{
    public const LABELS = [
        'active' => 'Aktif', 'expiring' => 'Akan berakhir', 'expired' => 'Berakhir',
        'frozen' => 'Dibekukan', 'blocked' => 'Diblokir', 'none' => 'Belum member',
    ];

    public static function of(User $u): string
    {
        if ($u->is_blocked) return 'blocked';
        $m = $u->membership;
        if (!$m) return 'none';
        if ($m->isFrozen()) return 'frozen';
        if (!$m->isActive()) return 'expired';
        if ($m->remainingDays() <= 7) return 'expiring';
        return 'active';
    }

    public static function isLive(string $status): bool
    {
        return in_array($status, ['active', 'expiring'], true);
    }
}
