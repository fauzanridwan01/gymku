<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Plan extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['is_enabled' => 'boolean', 'is_popular' => 'boolean'];
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,
            'days' => $this->days,
            'price' => $this->price,
            'original_price' => $this->original_price,
            'is_enabled' => $this->is_enabled,
            'is_popular' => $this->is_popular,
        ];
    }
}
