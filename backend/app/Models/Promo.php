<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Promo extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'starts_on' => 'date', 'ends_on' => 'date',
            'is_enabled' => 'boolean', 'ended_manually' => 'boolean', 'renewal_only' => 'boolean',
        ];
    }

    public function plans(): BelongsToMany
    {
        return $this->belongsToMany(Plan::class, 'promo_plan');
    }

    public function isRunning(): bool
    {
        $t = today();
        return $this->is_enabled && !$this->ended_manually
            && !$t->lt($this->starts_on) && !$t->gt($this->ends_on)
            && $this->used < $this->quota;
    }

    public function discountFor(int $price): int
    {
        return $this->type === 'percent'
            ? (int) round($price * $this->value / 100)
            : min($price, $this->value);
    }

    public function isScheduled(): bool
    {
        return !$this->ended_manually && today()->lt($this->starts_on);
    }

    /** running | scheduled | done */
    public function status(): string
    {
        return $this->isRunning() ? 'running' : ($this->isScheduled() ? 'scheduled' : 'done');
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'type' => $this->type,
            'value' => $this->value,
            'quota' => $this->quota,
            'used' => $this->used,
            'plan_codes' => $this->plans->pluck('code')->values(),
            'renewal_only' => $this->renewal_only,
            'starts_on' => $this->starts_on->toDateString(),
            'ends_on' => $this->ends_on->toDateString(),
            'is_enabled' => $this->is_enabled,
            'ended_manually' => $this->ended_manually,
            'status' => $this->status(),
        ];
    }
}
