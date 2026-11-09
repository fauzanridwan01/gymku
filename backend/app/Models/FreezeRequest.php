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

    public function toApi(bool $withUser = false): array
    {
        $a = [
            'id' => $this->id,
            'type' => $this->type,
            'reason' => $this->reason,
            'since' => $this->since->toDateString(),
            'days' => $this->days,
            'status' => $this->status,
            'requested_at' => $this->created_at?->toIso8601String(),
            'decided_at' => $this->decided_at?->toIso8601String(),
            'decision_note' => $this->decision_note,
        ];
        if ($withUser) {
            $u = User::find($this->user_id);
            $a['user'] = $u ? ['id' => $u->id, 'name' => $u->name, 'member_code' => $u->member_code] : null;
        }
        return $a;
    }
}
