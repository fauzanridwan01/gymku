<?php

namespace Tests\Feature;

use App\Models\BlockRecord;
use App\Models\FaceTemplate;
use App\Models\Membership;
use App\Models\Plan;
use App\Models\Target;
use App\Models\Transaction;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/** Regresi untuk bug yang ditemukan saat audit backend. */
class BugfixTest extends TestCase
{
    use RefreshDatabase;

    private function member(string $name = 'Budi'): User
    {
        $u = User::factory()->create(['name' => $name, 'email' => strtolower($name) . '@x.id', 'role' => 'member', 'member_code' => 'GYM-' . strtoupper($name)]);
        Membership::create(['user_id' => $u->id, 'plan_name' => 'Premium', 'starts_on' => today()->subDays(10),
            'ends_on' => today()->addDays(60), 'total_days' => 70]);
        return $u;
    }

    private function photo(): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('face.png', base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));
    }

    public function test_timezone_comes_from_env_config(): void
    {
        // config/app.php dulu menulis 'UTC' langsung sehingga APP_TIMEZONE di .env tidak berpengaruh.
        $this->assertSame(env('APP_TIMEZONE', 'UTC'), config('app.timezone'));
        $this->assertSame(config('app.timezone'), config('database.connections.pgsql.timezone'));
    }

    public function test_api_errors_are_json_even_without_accept_header(): void
    {
        $this->get('/api/me')->assertStatus(401)->assertJsonPath('message', 'Unauthenticated.');
    }

    public function test_order_code_does_not_collide_with_seeded_transaction(): void
    {
        $this->seed(DatabaseSeeder::class);
        $u = User::where('email', 'baru@gymku.id')->first();
        $plan = Plan::where('code', '1m')->first();

        // Isi id sampai 97 agar pesanan berikutnya bernomor 98 (dulu bentrok dengan TRX-0098 seeder).
        for ($i = Transaction::max('id') + 1; $i <= 97; $i++) {
            Transaction::create(['code' => 'DUMMY-' . $i, 'user_id' => $u->id, 'plan_id' => $plan->id,
                'plan_name' => 'x', 'base_price' => 1, 'amount' => 1, 'status' => 'cancelled']);
        }
        Sanctum::actingAs($u);
        $this->postJson('/api/orders', ['plan_code' => '1m'])->assertCreated()->assertJsonPath('code', 'TRX-0098');
    }

    public function test_simulate_pay_can_be_switched_off(): void
    {
        $u = $this->member('Sinta');
        Sanctum::actingAs($u);
        $code = $this->postJson('/api/orders', ['plan_code' => '1m'])->json('code');

        config(['services.gymku.simulate_pay' => false]);
        $this->postJson("/api/orders/{$code}/simulate-pay")->assertNotFound();
    }

    public function test_blocked_member_token_is_rejected_but_can_logout(): void
    {
        $u = $this->member('Agus');
        $token = $u->createToken('t')->plainTextToken;
        $u->update(['is_blocked' => true]);
        BlockRecord::create(['user_id' => $u->id, 'reason' => 'Pelanggaran', 'active' => true]);

        $h = ['Authorization' => "Bearer $token"];
        $this->withHeaders($h)->getJson('/api/me')->assertForbidden()->assertJsonPath('message', 'Akun diblokir: Pelanggaran');
        $this->withHeaders($h)->getJson('/api/plans')->assertForbidden();
        $this->withHeaders($h)->postJson('/api/auth/logout')->assertOk();
    }

    public function test_self_check_in_requires_photo_and_enrolled_face(): void
    {
        $u = $this->member();
        Sanctum::actingAs($u);

        $this->postJson('/api/checkins')->assertStatus(422);                         // tanpa foto
        $this->postJson('/api/checkins', ['photo' => $this->photo()])->assertStatus(422); // wajah belum terdaftar

        FaceTemplate::create(['user_id' => $u->id]);
        $u->unsetRelation('faceTemplate'); // model yang sama dipakai ulang di test; di produksi tiap request memuat ulang
        $this->postJson('/api/checkins', ['photo' => $this->photo()])->assertCreated();
    }

    public function test_email_update_and_case_insensitive_login_and_uniqueness(): void
    {
        $this->postJson('/api/auth/register', [
            'name' => 'Sinta', 'email' => 'Sinta@X.id', 'password' => 'Abcdef12', 'password_confirmation' => 'Abcdef12',
        ])->assertCreated()->assertJsonPath('user.email', 'sinta@x.id');

        // nama/email yang sama dengan huruf berbeda ditolak
        $this->postJson('/api/auth/register', [
            'name' => 'SINTA', 'email' => 'lain@x.id', 'password' => 'Abcdef12', 'password_confirmation' => 'Abcdef12',
        ])->assertStatus(422)->assertJsonValidationErrors('name');
        $this->postJson('/api/auth/register', [
            'name' => 'Lain', 'email' => 'SINTA@x.id', 'password' => 'Abcdef12', 'password_confirmation' => 'Abcdef12',
        ])->assertStatus(422)->assertJsonValidationErrors('email');

        // login tanpa membedakan huruf besar-kecil, via nama maupun email
        $this->postJson('/api/auth/login', ['login' => 'sinta', 'password' => 'Abcdef12'])->assertOk();
        $this->postJson('/api/auth/login', ['login' => 'SINTA@x.ID', 'password' => 'Abcdef12'])->assertOk();

        // ubah email dari profil benar-benar tersimpan
        $token = $this->postJson('/api/auth/login', ['login' => 'sinta', 'password' => 'Abcdef12'])->json('token');
        $this->withHeader('Authorization', "Bearer $token")->putJson('/api/me', ['email' => 'Baru@X.id'])
            ->assertOk()->assertJsonPath('user.email', 'baru@x.id');
    }

    public function test_name_that_looks_like_an_email_cannot_shadow_another_account(): void
    {
        $victim = $this->member('Korban');
        $this->postJson('/api/auth/register', [
            'name' => 'korban@x.id', 'email' => 'penyerang@x.id', 'password' => 'Abcdef12', 'password_confirmation' => 'Abcdef12',
        ])->assertCreated();

        // login memakai "@" dianggap email, jadi tetap menuju akun korban, bukan akun bernama sama
        $this->postJson('/api/auth/login', ['login' => 'korban@x.id', 'password' => 'Abcdef12'])->assertStatus(422);
        $this->assertNotNull($victim->fresh());
    }

    public function test_user_with_payments_cannot_be_deleted(): void
    {
        $this->seed(DatabaseSeeder::class);
        $naufal = User::where('email', 'naufal@gmail.com')->first();

        $this->expectException(QueryException::class);
        $naufal->delete();
    }

    public function test_one_target_per_period_per_user(): void
    {
        $u = $this->member();
        Target::create(['user_id' => $u->id, 'name' => 'A', 'period' => 'weekly', 'count' => 3]);

        $this->expectException(QueryException::class);
        Target::create(['user_id' => $u->id, 'name' => 'B', 'period' => 'weekly', 'count' => 4]);
    }
}
