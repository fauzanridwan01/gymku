<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Pusat Informasi (sisi member). */
class AnnouncementController extends Controller
{
    public function index(Request $r): JsonResponse
    {
        $items = Announcement::visibleTo($r->user())->orderByDesc('published_at')->orderByDesc('id')->get();
        $banner = $items->firstWhere('is_banner', true);

        return response()->json([
            'banner' => $banner?->toApi(),
            'items' => $items->map->toApi()->values(),
        ]);
    }

    public function view(Request $r, int $id): JsonResponse
    {
        $a = Announcement::visibleTo($r->user())->findOrFail($id);
        $a->increment('views');
        return response()->json(['views' => $a->views]);
    }
}
