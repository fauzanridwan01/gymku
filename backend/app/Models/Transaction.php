<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Transaction extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'period_start' => 'date', 'period_end' => 'date',
            'expires_at' => 'datetime', 'paid_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function toApi(): array
    {
        $at = $this->paid_at ?? $this->created_at;
        return [
            'id' => $this->id,
            'code' => $this->code,
            'receipt_no' => 'INV/' . $at->format('Ymd') . '/' . $this->code,
            'plan_name' => $this->plan_name,
            'plan_days' => $this->plan_days,
            'method' => $this->method,
            'base_price' => $this->base_price,
            'discount' => $this->discount,
            'amount' => $this->amount,
            'promo_label' => $this->promo_label,
            'status' => $this->status,
            'period_start' => $this->period_start?->toDateString(),
            'period_end' => $this->period_end?->toDateString(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'paid_at' => $this->paid_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            // Simulasi: isi QR palsu. Di produksi diganti string QRIS dari payment gateway.
            'qris_payload' => $this->status === 'pending' ? 'SIMULASI-GYMKU-' . $this->code : null,
        ];
    }
}
