<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\User;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** Buat Informasi (admin). Target: semua member atau satu member. */
class AnnouncementController extends Controller
{
    public function index(Request $r): JsonResponse
    {
        $q = Announcement::query()->orderByDesc('id');
        if ($r->filled('status')) {
            $q->where('status', $r->status);
        }
        $rows = $q->get();
        $targets = User::whereIn('id', $rows->pluck('target_user_id')->filter())->get()->keyBy('id');

        return response()->json([
            'items' => $rows->map(fn ($a) => $a->toApi($targets->get($a->target_user_id)))->values(),
        ]);
    }

    public function store(Request $r): JsonResponse
    {
        $a = Announcement::create($this->payload($r) + ['created_by' => $r->user()->id])->refresh();
        ActivityLogger::log('info', 'Informasi dibuat: ' . $a->title,
            $a->target_user_id ? 'Untuk satu member' : 'Untuk semua member', $r->user()->id);
        return response()->json($this->show($a), 201);
    }

    public function update(Request $r, int $id): JsonResponse
    {
        $a = Announcement::findOrFail($id);
        $a->update($this->payload($r));
        ActivityLogger::log('info', 'Informasi diubah: ' . $a->title, '', $r->user()->id);
        return response()->json($this->show($a));
    }

    public function archive(Request $r, int $id): JsonResponse
    {
        $r->validate(['archived' => 'required|boolean']);
        $a = Announcement::findOrFail($id);
        $a->update(['status' => $r->boolean('archived') ? 'archived' : 'published']);
        ActivityLogger::log('info', ($r->boolean('archived') ? 'Informasi diarsipkan: ' : 'Informasi diaktifkan: ') . $a->title, '', $r->user()->id);
        return response()->json($this->show($a));
    }

    public function destroy(Request $r, int $id): JsonResponse
    {
        $a = Announcement::findOrFail($id);
        $a->delete();
        ActivityLogger::log('info', 'Informasi dihapus: ' . $a->title, '', $r->user()->id);
        return response()->json(['message' => 'Informasi dihapus.']);
    }

    private function show(Announcement $a): array
    {
        return $a->toApi($a->target_user_id ? User::find($a->target_user_id) : null);
    }

    private function payload(Request $r): array
    {
        $d = $r->validate([
            'category' => ['required', Rule::in(Announcement::CATEGORIES)],
            'title' => ['required', 'string', 'max:120'],
            'body' => ['required', 'string', 'max:2000'],
            'target_user_id' => ['nullable', Rule::exists('users', 'id')->where('role', 'member')],
            'is_banner' => ['boolean'],
            'valid_until' => ['nullable', 'date', 'after_or_equal:today'],
            'publish_at' => ['nullable', 'date'], // jadwal tayang (opsional)
            'status' => ['required', Rule::in(['draft', 'published'])],
        ]);

        $publishedAt = null;
        if ($d['status'] === 'published') {
            $publishedAt = isset($d['publish_at']) ? \Illuminate\Support\Carbon::parse($d['publish_at']) : now();
        }

        return [
            'category' => $d['category'],
            'title' => trim($d['title']),
            'body' => trim($d['body']),
            'target_user_id' => $d['target_user_id'] ?? null,
            'is_banner' => (bool) ($d['is_banner'] ?? false),
            'valid_until' => $d['valid_until'] ?? null,
            'status' => $d['status'],
            'published_at' => $publishedAt,
        ];
    }
}
