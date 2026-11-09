<?php

namespace App\Services;

use App\Models\ActivityLog;

class ActivityLogger
{
    public static function log(string $kind, string $text, string $detail = '', ?int $actorId = null): void
    {
        ActivityLog::create([
            'kind' => $kind, 'text' => $text, 'detail' => $detail,
            'actor_id' => $actorId, 'created_at' => now(),
        ]);
    }
}
