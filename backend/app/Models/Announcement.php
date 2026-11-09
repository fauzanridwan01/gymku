<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    public const CATEGORIES = ['Pengumuman', 'Kelas', 'Promo'];

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'is_banner' => 'boolean',
            'valid_until' => 'date',
            'published_at' => 'datetime',
        ];
    }

    public function isScheduled(): bool
    {
        return $this->status === 'published' && $this->published_at && $this->published_at->isFuture();
    }

    public function isExpired(): bool
    {
        return $this->valid_until !== null && today()->gt($this->valid_until);
    }

    /** Tayang sekarang: terbit, sudah waktunya, belum kedaluwarsa. */
    public function isLive(): bool
    {
        return $this->status === 'published' && !$this->isScheduled() && !$this->isExpired();
    }

    /** Sama dengan Announcement.isLive di Flutter, tetapi sebagai query. */
    public function scopeLive(Builder $q): Builder
    {
        return $q->where('status', 'published')
            ->where(fn ($w) => $w->whereNull('published_at')->orWhere('published_at', '<=', now()))
            ->where(fn ($w) => $w->whereNull('valid_until')->orWhereDate('valid_until', '>=', today()));
    }

    public function scopeVisibleTo(Builder $q, User $user): Builder
    {
        return $q->live()->where(fn ($w) => $w->whereNull('target_user_id')->orWhere('target_user_id', $user->id));
    }

    public function toApi(?User $target = null): array
    {
        return [
            'id' => $this->id,
            'category' => $this->category,
            'title' => $this->title,
            'body' => $this->body,
            'views' => $this->views,
            'target_user_id' => $this->target_user_id,
            'target_name' => $target?->name,
            'is_banner' => $this->is_banner,
            'valid_until' => $this->valid_until?->toDateString(),
            'status' => $this->status,
            'published_at' => $this->published_at?->toIso8601String(),
            'is_scheduled' => $this->isScheduled(),
            'is_expired' => $this->isExpired(),
            'is_live' => $this->isLive(),
        ];
    }
}
