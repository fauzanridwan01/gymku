<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FreezeRequest extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['since' => 'date', 'decided_at' => 'datetime'];
    }
}
