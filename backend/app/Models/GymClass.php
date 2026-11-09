<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GymClass extends Model
{
    protected $table = 'gym_classes';
    protected $guarded = [];

    protected function casts(): array
    {
        return ['starts_at' => 'datetime'];
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    public function toApi(int $bookedCount, bool $isBooked): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'studio' => $this->studio,
            'coach' => $this->coach,
            'category' => $this->category,
            'starts_at' => $this->starts_at->toIso8601String(),
            'capacity' => $this->capacity,
            'booked_count' => $bookedCount,
            'slots_left' => max(0, $this->capacity - $bookedCount),
            'is_booked' => $isBooked,
        ];
    }
}
