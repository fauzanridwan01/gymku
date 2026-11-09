<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FaceTemplate extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['embedding' => 'array', 'enrolled_at' => 'datetime'];
    }
}
