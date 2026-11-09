<?php

namespace Tests\Feature;

use App\Models\ActivityLog;
use App\Models\CheckIn;
use App\Models\Membership;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminToolsTest extends TestCase
{
    use RefreshDatabase;

    private function member(string $name, int $daysLeft = 60, ?string $gender = null): User
    {
        $u = User::factory()->create(['name' => $name, 'email' => strtolower(str_replace(' ', '.', $name)) . '@x.id',
            'role' => 'member', 'member_code' => 'GYM-' . strtoupper(substr(md5($name), 0, 5)), 'gender' => $gender,
            'joined_at' => today()->subDays(30)]);
        if ($daysLeft !== null) {
            Membership::create(['user_id' => $u->id, 'plan_name' => 'Premium', 'starts_on' => today()->subDays(30),
                'ends_on' => today()->addDays($daysLeft), 'total_days' => 90]);
        }
        return $u;
    }

    private function admin(): User
    {
        $a = User::factory()->create(['name' => 'admin', 'email' => 'admin@x.id', 'role' => 'admin']);
        Sanctum::actingAs($a);
        return $a;
    }

    private function paid(User $u, int $amount, $when): Transaction
    {
        return Transaction::create(['code' => 'T' . uniqid(), 'user_id' => $u->id, 'plan_name' => 'Premium 1 Bulan', 'plan_days' => 30,
            'base_price' => $amount, 'amount' => $amount, 'status' => 'paid', 'paid_at' => $when]);
    }

    public function test_member_list_search_and_status_filter(): void
    {
        $this->member('Naufal Hakim', 60, 'Laki-laki');
        $this->member('Dewi Sartika', 5, 'Perempuan');                 // akan berakhir
        $this->member('Lama Sekali', -10);                              // berakhir
        $blocked = $this->member('Agus Setiawan');
        $blocked->update(['is_blocked' => true]);
        $this->admin();

        $statuses = collect($this->getJson('/api/admin/members')->assertOk()->json('items'))->pluck('status', 'name');
        $this->assertSame('active', $statuses['Naufal Hakim']);
        $this->assertSame('expiring', $statuses['Dewi Sartika']);
        $this->assertSame('expired', $statuses['Lama Sekali']);
        $this->assertSame('blocked', $statuses['Agus Setiawan']);

        $this->getJson('/api/admin/members?q=naufal')->assertJsonCount(1, 'items');
        $this->getJson('/api/admin/members?status=expiring')->assertJsonCount(1, 'items')->assertJsonPath('items.0.name', 'Dewi Sartika');
        $this->getJson('/api/admin/members?gender=Perempuan')->assertJsonCount(1, 'items');
    }

    public function test_member_detail(): void
    {
        $m = $this->member('Budi');
        CheckIn::create(['user_id' => $m->id, 'checked_in_at' => now()->subDay()]);
        $this->paid($m, 350000, now()->subDays(3));
        $this->admin();

        $this->getJson("/api/admin/members/{$m->id}")->assertOk()
            ->assertJsonPath('member.name', 'Budi')->assertJsonPath('visits_this_month', fn ($v) => $v >= 0)
            ->assertJsonCount(1, 'checkins')->assertJsonCount(1, 'transactions')
            ->assertJsonPath('active_block', null);
    }

    public function test_block_unblock_flow_revokes_tokens_and_logs(): void
    {
        $m = $this->member('Agus');
        $m->createToken('mobile');
        $admin = $this->admin();

        $this->postJson("/api/admin/members/{$m->id}/block", [])->assertStatus(422);
        $this->postJson("/api/admin/members/{$m->id}/block", ['reason' => 'Meminjamkan akun'])->assertOk()
            ->assertJsonPath('status', 'blocked');
        $this->assertSame(0, $m->tokens()->count());
        $this->postJson("/api/admin/members/{$m->id}/block", ['reason' => 'lagi'])->assertStatus(422);

        $this->getJson('/api/admin/blocks')->assertJsonCount(1, 'active')->assertJsonCount(0, 'reopened')
            ->assertJsonPath('active.0.reason', 'Meminjamkan akun')->assertJsonPath('active.0.blocked_by', 'admin');
        $this->assertSame('Akun diblokir: Meminjamkan akun', $m->fresh()->blockedReason());

        $this->postJson("/api/admin/members/{$m->id}/unblock", ['note' => 'Sudah klarifikasi'])->assertOk()
            ->assertJsonPath('status', 'active');
        $this->postJson("/api/admin/members/{$m->id}/unblock")->assertStatus(422);
        $this->getJson('/api/admin/blocks')->assertJsonCount(0, 'active')->assertJsonCount(1, 'reopened')
            ->assertJsonPath('reopened.0.unblock_note', 'Sudah klarifikasi');

        $kinds = ActivityLog::pluck('kind')->all();
        $this->assertContains('block', $kinds);
        $this->assertContains('unblock', $kinds);
        $this->getJson('/api/admin/logs?kind=block')->assertJsonCount(1, 'items');
    }

    public function test_dashboard_numbers(): void
    {
        $a = $this->member('Aktif');
        $b = $this->member('Segera Habis', 3);
        $c = $this->member('Diblokir');
        $c->update(['is_blocked' => true]);
        $new = $this->member('Baru Hari Ini');
        $new->update(['joined_at' => today()]);

        CheckIn::create(['user_id' => $a->id, 'checked_in_at' => now()]);
        CheckIn::create(['user_id' => $b->id, 'checked_in_at' => today()->subDay()->setHour(10)]);
        $this->paid($a, 1000000, now()->subDays(2));
        $this->paid($b, 500000, now()->subDays(40));
        $this->admin();

        $this->getJson('/api/admin/dashboard')->assertOk()
            ->assertJsonPath('active_members', 3)        // Aktif, Segera Habis, Baru Hari Ini
            ->assertJsonPath('blocked_members', 1)
            ->assertJsonPath('new_members_today', 1)
            ->assertJsonCount(1, 'expiring_members')
            ->assertJsonPath('visits_today', 1)
            ->assertJsonPath('visits_yesterday', 1)
            ->assertJsonPath('revenue_30', 1000000)
            ->assertJsonPath('revenue_prev_30', 500000);
    }

    public function test_monthly_report_and_inactive_members(): void
    {
        $a = $this->member('Rajin');
        $b = $this->member('Malas');
        $month = today()->startOfMonth();

        CheckIn::create(['user_id' => $a->id, 'checked_in_at' => $month->copy()->setDay(2)->setHour(7)]);
        CheckIn::create(['user_id' => $a->id, 'checked_in_at' => $month->copy()->setDay(9)->setHour(19)]);
        CheckIn::create(['user_id' => $a->id, 'checked_in_at' => $month->copy()->setDay(24)->setHour(19)]);
        CheckIn::create(['user_id' => $b->id, 'checked_in_at' => today()->subDays(45)]);
        $this->paid($a, 350000, $month->copy()->setDay(3)->setHour(9));
        $this->admin();

        $res = $this->getJson('/api/admin/reports?month=' . $month->format('Y-m'))->assertOk();
        $res->assertJsonPath('weekly_visits', [1, 1, 0, 1])->assertJsonPath('revenue', 350000)
            ->assertJsonPath('visits', 3)->assertJsonCount(6, 'months');

        $inactive = collect($res->json('inactive_members'))->pluck('days', 'name');
        $this->assertSame(45, $inactive['Malas']);
        $this->assertArrayNotHasKey('Rajin', $inactive->all());
    }

    public function test_admin_transactions_list_and_scan_stub(): void
    {
        $m = $this->member('Budi');
        $this->paid($m, 350000, now());
        $this->admin();

        $this->getJson('/api/admin/transactions')->assertOk()->assertJsonPath('items.0.member_name', 'Budi');
        $this->postJson('/api/admin/scan', [])->assertStatus(422); // foto wajib
    }

    public function test_member_cannot_use_admin_tools(): void
    {
        $m = $this->member('Budi');
        Sanctum::actingAs($m);
        foreach (['/api/admin/dashboard', '/api/admin/reports', '/api/admin/logs', '/api/admin/blocks', "/api/admin/members/{$m->id}"] as $url) {
            $this->getJson($url)->assertForbidden();
        }
        $this->postJson("/api/admin/members/{$m->id}/block", ['reason' => 'x'])->assertForbidden();
    }
}
