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
            'name' => ['required', 'string', 'max:100', $this->uniqueCi('name', 'Nama sudah dipakai.')],
            'email' => ['required', 'email', 'max:150', $this->uniqueCi('email', 'Email sudah terdaftar.')],
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
        ]);
        $data['name'] = trim($data['name']);
        $data['email'] = mb_strtolower(trim($data['email']));

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

        // Berisi "@" = email, selain itu = nama. Dipisah agar nama yang menyerupai email
        // tidak bisa bentrok dengan akun lain. Tidak membedakan huruf besar-kecil.
        $login = mb_strtolower(trim($r->login));
        $user = User::whereRaw(str_contains($login, '@') ? 'LOWER(email) = ?' : 'LOWER(name) = ?', [$login])->first();
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
            'name' => ['sometimes', 'string', 'max:100', $this->uniqueCi('name', 'Nama sudah dipakai.', $r->user()->id)],
            'email' => ['sometimes', 'email', 'max:150', $this->uniqueCi('email', 'Email sudah terdaftar.', $r->user()->id)],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'gender' => ['sometimes', 'nullable', 'in:Laki-laki,Perempuan'],
            'birth_date' => ['sometimes', 'nullable', 'date', 'before:today'],
        ]);
        if (isset($data['name'])) $data['name'] = trim($data['name']);
        if (isset($data['email'])) $data['email'] = mb_strtolower(trim($data['email']));
        $r->user()->update($data);
        return response()->json(['user' => $r->user()->fresh()->toApi()]);
    }

    /** Aturan unik yang tidak membedakan huruf besar-kecil (cocok dengan indeks LOWER() di database). */
    private function uniqueCi(string $column, string $message, ?int $ignoreId = null): \Closure
    {
        return function (string $attr, mixed $value, \Closure $fail) use ($column, $message, $ignoreId) {
            $q = User::whereRaw("LOWER($column) = ?", [mb_strtolower(trim((string) $value))]);
            if ($ignoreId) {
                $q->where('id', '!=', $ignoreId);
            }
            if ($q->exists()) {
                $fail($message);
            }
        };
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
