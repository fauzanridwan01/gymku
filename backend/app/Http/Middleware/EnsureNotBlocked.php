<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Token milik akun yang diblokir ditolak (kecuali logout). */
class EnsureNotBlocked
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($why = $request->user()?->blockedReason()) {
            return response()->json(['message' => $why], 403);
        }
        return $next($request);
    }
}
