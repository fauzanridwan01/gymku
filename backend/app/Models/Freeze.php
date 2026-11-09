<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Freeze extends Model
{
    protected $table = 'freezes';
    protected $guarded = [];

    protected function casts(): array
    {
        return ['starts_on' => 'date', 'ends_on' => 'date'];
    }

    public function length(): int
    {
        return max(0, (int) $this->starts_on->diffInDays($this->ends_on) + 1);
    }
}
