<?php

namespace Tests\Feature;

use App\Models\Announcement;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class GymkuApiTest extends TestCase
{
    use RefreshDatabase;

    private function member(string $name = 'Budi'): User
    {
        return User::factory()->create(['name' => $name, 'email' => strtolower($name) . '@x.id', 'role' => 'member']);
    }

    private function admin(): User
    {
        return User::factory()->create(['name' => 'admin', 'email' => 'admin@x.id', 'role' => 'admin']);
    }

    public function test_register_and_login_by_name(): void
    {
        $this->postJson('/api/auth/register', [
            'name' => 'Sinta', 'email' => 'sinta@x.id', 'password' => 'Abcdef12', 'password_confirmation' => 'Abcdef12',
        ])->assertCreated()->assertJsonStructure(['token', 'user' => ['member_code']]);

        $this->postJson('/api/auth/login', ['login' => 'Sinta', 'password' => 'Abcdef12'])
            ->assertOk()->assertJsonStructure(['token']);
        $this->postJson('/api/auth/login', ['login' => 'Sinta', 'password' => 'salah'])->assertStatus(422);
    }

    public function test_weak_password_rejected(): void
    {
        $this->postJson('/api/auth/register', [
            'name' => 'X', 'email' => 'x@x.id', 'password' => 'abcdefgh', 'password_confirmation' => 'abcdefgh',
        ])->assertStatus(422);
    }

    public function test_member_cannot_use_admin_routes(): void
    {
        Sanctum::actingAs($this->member());
        $this->getJson('/api/admin/announcements')->assertForbidden();
    }

    public function test_announcement_visibility_per_member_and_schedule(): void
    {
        $admin = $this->admin();
        $a = $this->member('Ani');
        $b = $this->member('Bayu');

        Sanctum::actingAs($admin);
        $base = ['category' => 'Pengumuman', 'body' => 'isi', 'status' => 'published'];
        $this->postJson('/api/admin/announcements', $base + ['title' => 'Untuk semua'])->assertCreated();
        $this->postJson('/api/admin/announcements', $base + ['title' => 'Khusus Ani', 'target_user_id' => $a->id])->assertCreated();
        $this->postJson('/api/admin/announcements', $base + ['title' => 'Terjadwal', 'publish_at' => now()->addDay()->toIso8601String()])->assertCreated();
        $this->postJson('/api/admin/announcements', ['title' => 'Draf', 'status' => 'draft'] + $base)->assertCreated();

        Sanctum::actingAs($a);
        $titles = collect($this->getJson('/api/announcements')->json('items'))->pluck('title')->all();
        $this->assertEqualsCanonicalizing(['Untuk semua', 'Khusus Ani'], $titles);

        Sanctum::actingAs($b);
        $titles = collect($this->getJson('/api/announcements')->json('items'))->pluck('title')->all();
        $this->assertSame(['Untuk semua'], $titles);
    }

    public function test_view_counter_and_target_must_be_member(): void
    {
        $admin = $this->admin();
        $m = $this->member();
        $info = Announcement::create(['category' => 'Kelas', 'title' => 't', 'body' => 'b', 'status' => 'published', 'published_at' => now()]);

        Sanctum::actingAs($m);
        $this->postJson("/api/announcements/{$info->id}/view")->assertOk()->assertJson(['views' => 1]);

        Sanctum::actingAs($admin);
        $this->postJson('/api/admin/announcements', [
            'category' => 'Promo', 'title' => 'x', 'body' => 'y', 'status' => 'published', 'target_user_id' => $admin->id,
        ])->assertStatus(422);
    }

    public function test_archive_hides_announcement(): void
    {
        $admin = $this->admin();
        $m = $this->member();
        $info = Announcement::create(['category' => 'Kelas', 'title' => 't', 'body' => 'b', 'status' => 'published', 'published_at' => now()]);

        Sanctum::actingAs($admin);
        $this->patchJson("/api/admin/announcements/{$info->id}/archive", ['archived' => true])->assertOk();

        Sanctum::actingAs($m);
        $this->assertCount(0, $this->getJson('/api/announcements')->json('items'));
    }
}
