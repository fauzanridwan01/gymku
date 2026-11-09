<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Member yang diblokir tidak boleh memakai API, walaupun token lamanya masih ada. */
class EnsureNotBlocked
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user && $user->is_blocked) {
            return response()->json(['message' => $user->blockedMessage()], 403);
        }
        return $next($request);
    }
}
