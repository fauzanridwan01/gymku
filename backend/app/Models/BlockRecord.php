<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BlockRecord extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['active' => 'boolean', 'unblocked_at' => 'datetime'];
    }
}
