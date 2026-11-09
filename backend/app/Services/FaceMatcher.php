<?php

namespace App\Services;

use App\Models\FaceTemplate;
use Illuminate\Http\UploadedFile;

/**
 * TEMPAT UNTUK ALGORITMA PENCOCOKAN WAJAH (dikerjakan anggota tim lain).
 *
 * Cukup ganti isi dua method di bawah; controller dan tabel face_templates
 * sudah siap dan tidak perlu diubah.
 */
class FaceMatcher
{
    /** Skor minimum agar wajah dianggap cocok (0..1). Sesuaikan dengan algoritma. */
    public const THRESHOLD = 0.8;

    /** Hasilkan embedding dari foto. Kembalikan null jika belum diimplementasikan. */
    public function embed(UploadedFile $photo): ?array
    {
        // TODO(tim wajah): panggil model/algoritma, kembalikan array angka.
        return null;
    }

    /**
     * Cocokkan foto dengan wajah terdaftar milik user.
     * Kembalikan skor 0..1; null = belum diimplementasikan.
     */
    public function match(UploadedFile $photo, FaceTemplate $template): ?float
    {
        // TODO(tim wajah): bandingkan embedding foto dengan $template->embedding.
        return null;
    }
}
