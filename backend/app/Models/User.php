<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name', 'email', 'password', 'role', 'member_code', 'phone', 'gender',
        'birth_date', 'joined_at', 'is_blocked', 'best_streak',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'birth_date' => 'date',
            'joined_at' => 'date',
            'is_blocked' => 'boolean',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /** Alasan user TIDAK boleh booking/check-in (null = boleh). */
    public function entryDeniedReason(): ?string
    {
        if ($this->is_blocked) {
            $why = BlockRecord::where('user_id', $this->id)->where('active', true)->latest('id')->value('reason');
            return 'Akun diblokir: ' . ($why ?? '-');
        }
        $m = $this->membership;
        if (!$m) return 'Member belum punya paket';
        if ($m->isFrozen()) return 'Membership sedang dibekukan';
        if (!$m->isActive()) return 'Membership sudah berakhir';
        return null;
    }

    public function membership(): HasOne
    {
        return $this->hasOne(Membership::class);
    }

    public function faceTemplate(): HasOne
    {
        return $this->hasOne(FaceTemplate::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    public function targets(): HasMany
    {
        return $this->hasMany(Target::class);
    }

    public function checkins(): HasMany
    {
        return $this->hasMany(CheckIn::class);
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    /** Bentuk JSON yang dipakai aplikasi Flutter. */
    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role,
            'member_code' => $this->member_code,
            'phone' => $this->phone,
            'gender' => $this->gender,
            'birth_date' => $this->birth_date?->toDateString(),
            'joined_at' => $this->joined_at?->toDateString(),
            'is_blocked' => $this->is_blocked,
            'has_face' => $this->faceTemplate()->exists(),
        ];
    }
}
