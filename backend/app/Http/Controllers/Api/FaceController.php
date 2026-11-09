<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FaceTemplate;
use App\Services\FaceMatcher;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Pendaftaran wajah. Algoritma pencocokan ada di App\Services\FaceMatcher (tim lain). */
class FaceController extends Controller
{
    public function enroll(Request $r, FaceMatcher $matcher): JsonResponse
    {
        $r->validate(['photo' => 'required|image|max:4096']);

        $path = $r->file('photo')->store('faces/' . $r->user()->id);
        FaceTemplate::updateOrCreate(
            ['user_id' => $r->user()->id],
            ['image_path' => $path, 'embedding' => $matcher->embed($r->file('photo')), 'enrolled_at' => now()],
        );

        return response()->json(['message' => 'Wajah terdaftar.', 'has_face' => true]);
    }
}
