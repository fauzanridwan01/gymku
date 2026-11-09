<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MemberController extends Controller
{
    /** Pencarian member (dipakai pemilih target di Buat Informasi). */
    public function index(Request $r): JsonResponse
    {
        $q = User::where('role', 'member')->orderBy('name');
        if ($r->filled('q')) {
            $term = '%' . str_replace(['%', '_'], ['\%', '\_'], mb_strtolower($r->q)) . '%';
            $q->where(fn ($w) => $w->whereRaw('LOWER(name) LIKE ?', [$term])
                ->orWhereRaw('LOWER(member_code) LIKE ?', [$term]));
        }
        return response()->json([
            'items' => $q->limit(30)->get()->map(fn ($u) => [
                'id' => $u->id, 'name' => $u->name, 'member_code' => $u->member_code,
                'is_blocked' => $u->is_blocked,
            ]),
        ]);
    }
}
