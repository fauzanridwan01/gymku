<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Membership extends Model
{
    public const MAX_FREEZE_DAYS = 30;

    protected $guarded = [];

    protected function casts(): array
    {
        return ['starts_on' => 'date', 'ends_on' => 'date'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function freezes(): HasMany
    {
        return $this->hasMany(Freeze::class);
    }

    public function currentFreeze(): ?Freeze
    {
        return $this->freezes()->whereDate('ends_on', '>=', today())->orderByDesc('starts_on')->first();
    }

    public function isFrozen(): bool
    {
        $f = $this->currentFreeze();
        return $f !== null && !today()->lt($f->starts_on);
    }

    public function isActive(): bool
    {
        return !today()->gt($this->ends_on);
    }

    public function remainingDays(): int
    {
        $f = $this->currentFreeze();
        if ($f) {
            if (!today()->lt($f->starts_on)) {
                return $f->remaining_at_start; // sedang dibekukan
            }
            return max(0, today()->diffInDays($this->ends_on, false) - $f->length());
        }
        return max(0, (int) today()->diffInDays($this->ends_on, false));
    }

    public function toApi(): array
    {
        $f = $this->currentFreeze();
        $frozen = $f && !today()->lt($f->starts_on);
        return [
            'plan_name' => $this->plan_name,
            'starts_on' => $this->starts_on->toDateString(),
            'ends_on' => $this->ends_on->toDateString(),
            'total_days' => $this->total_days,
            'remaining_days' => $this->remainingDays(),
            'is_active' => $this->isActive(),
            'is_frozen' => $frozen,
            'freeze_days_available' => max(0, self::MAX_FREEZE_DAYS - $this->freeze_days_used),
        ];
    }
}
