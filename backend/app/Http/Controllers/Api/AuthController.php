<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $r): JsonResponse
    {
        $data = $r->validate([
            'name' => ['required', 'string', 'max:100', 'unique:users,name'],
            'email' => ['required', 'email', 'max:150', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
        ]);

        $user = User::create($data + [
            'role' => 'member',
            'joined_at' => today(),
        ]);
        $user->update(['member_code' => sprintf('GYM-%06d', $user->id)]);

        return response()->json([
            'token' => $user->createToken('mobile')->plainTextToken,
            'user' => $user->fresh()->toApi(),
        ], 201);
    }

    /** `login` boleh berisi email atau nama pengguna (sama seperti aplikasi). */
    public function login(Request $r): JsonResponse
    {
        $r->validate(['login' => 'required|string', 'password' => 'required|string']);

        $user = User::where('email', $r->login)->orWhere('name', $r->login)->first();
        if (!$user || !Hash::check($r->password, $user->password)) {
            throw ValidationException::withMessages(['login' => 'Nama/email atau kata sandi salah.']);
        }
        if ($user->is_blocked) {
            return response()->json(['message' => 'Akun Anda diblokir. Hubungi admin.'], 403);
        }

        return response()->json([
            'token' => $user->createToken('mobile')->plainTextToken,
            'user' => $user->toApi(),
        ]);
    }

    public function logout(Request $r): JsonResponse
    {
        $r->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Berhasil keluar.']);
    }

    public function me(Request $r): JsonResponse
    {
        $u = $r->user();
        return response()->json([
            'user' => $u->toApi(),
            'membership' => $u->membership?->toApi(),
        ]);
    }

    public function update(Request $r): JsonResponse
    {
        $data = $r->validate([
            'name' => ['sometimes', 'string', 'max:100', 'unique:users,name,' . $r->user()->id],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'gender' => ['sometimes', 'nullable', 'in:Laki-laki,Perempuan'],
            'birth_date' => ['sometimes', 'nullable', 'date', 'before:today'],
        ]);
        $r->user()->update($data);
        return response()->json(['user' => $r->user()->fresh()->toApi()]);
    }

    public function changePassword(Request $r): JsonResponse
    {
        $r->validate([
            'current_password' => 'required|string',
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers(), 'different:current_password'],
        ]);
        if (!Hash::check($r->current_password, $r->user()->password)) {
            throw ValidationException::withMessages(['current_password' => 'Kata sandi saat ini salah.']);
        }
        $r->user()->update(['password' => $r->password]);
        return response()->json(['message' => 'Kata sandi diperbarui.']);
    }
}
