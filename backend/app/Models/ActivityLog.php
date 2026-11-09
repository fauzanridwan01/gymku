<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActivityLog extends Model
{
    public $timestamps = false;
    protected $guarded = [];

    protected function casts(): array
    {
        return ['created_at' => 'datetime'];
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'kind' => $this->kind,
            'text' => $this->text,
            'detail' => $this->detail,
            'at' => $this->created_at?->toIso8601String(),
        ];
    }
}
