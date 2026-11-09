<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CheckIn extends Model
{
    protected $table = 'checkins';
    protected $guarded = [];

    protected function casts(): array
    {
        return ['checked_in_at' => 'datetime'];
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'checked_in_at' => $this->checked_in_at->toIso8601String(),
            'area' => $this->area,
            'method' => $this->method,
            'method_label' => $this->method === 'face' ? 'Check-in wajah' : 'Check-in manual',
        ];
    }
}
