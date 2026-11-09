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

    public function toApi(?User $user = null, ?User $by = null): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'member_name' => $user?->name,
            'member_code' => $user?->member_code,
            'reason' => $this->reason,
            'blocked_by' => $by?->name,
            'blocked_at' => $this->created_at?->toIso8601String(),
            'active' => $this->active,
            'unblock_note' => $this->unblock_note,
            'unblocked_at' => $this->unblocked_at?->toIso8601String(),
        ];
    }
}
