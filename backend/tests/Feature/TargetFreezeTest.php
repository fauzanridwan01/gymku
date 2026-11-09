<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\CheckIn;
use App\Models\Freeze;
use App\Models\FreezeRequest;
use App\Models\GymClass;
use App\Models\Membership;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TargetFreezeTest extends TestCase
{
    use RefreshDatabase;

    private function member(string $name = 'Budi', bool $withMembership = true): User
    {
        $u = User::factory()->create(['name' => $name, 'email' => strtolower($name) . '@x.id', 'role' => 'member', 'member_code' => 'GYM-' . strtoupper($name)]);
        if ($withMembership) {
            Membership::create(['user_id' => $u->id, 'plan_name' => 'Premium', 'starts_on' => today()->subDays(10),
                'ends_on' => today()->addDays(60), 'total_days' => 70]);
        }
        return $u;
    }

    private function admin(): User
    {
        return User::factory()->create(['name' => 'admin', 'email' => 'admin@x.id', 'role' => 'admin']);
    }

    private function visit(User $u, $at): void
    {
        CheckIn::create(['user_id' => $u->id, 'checked_in_at' => $at, 'method' => 'face']);
    }

    // ------------------------------------------------------------- target

    public function test_create_target_one_per_period_and_delete(): void
    {
        $u = $this->member();
        Sanctum::actingAs($u);

        $body = ['name' => 'Latihan rutin pagi', 'period' => 'weekly', 'count' => 4, 'days' => [1, 3, 5, 6], 'reminder' => true, 'reminder_time' => '06:30'];
        $id = $this->postJson('/api/targets', $body)->assertCreated()
            ->assertJsonPath('days', [1, 3, 5, 6])->assertJsonPath('reminder_time', '06:30')->json('id');
        $this->postJson('/api/targets', $body)->assertStatus(422);
        $this->postJson('/api/targets', ['name' => 'Bulanan', 'period' => 'monthly', 'count' => 16])->assertCreated();
        $this->postJson('/api/targets', ['name' => 'x', 'period' => 'weekly', 'count' => 9])->assertStatus(422);

        $this->deleteJson("/api/targets/{$id}")->assertOk();
        $this->getJson('/api/targets')->assertJsonCount(1, 'items');
    }

    public function test_target_requires_active_membership(): void
    {
        Sanctum::actingAs($this->member('Tamu', withMembership: false));
        $this->postJson('/api/targets', ['name' => 'x', 'period' => 'weekly', 'count' => 3])->assertStatus(422);
    }

    public function test_target_progress_dots_and_streak(): void
    {
        $u = $this->member();
        Sanctum::actingAs($u);
        $this->postJson('/api/targets', ['name' => 'Mingguan', 'period' => 'weekly', 'count' => 2])->assertCreated();

        $ws = today()->startOfWeek();
        $this->visit($u, $ws->copy()->setHour(10));
        $this->visit($u, $ws->copy()->setHour(15));                       // minggu ini: 2 kunjungan
        $this->visit($u, $ws->copy()->subWeek()->setHour(10));
        $this->visit($u, $ws->copy()->subWeek()->addDay()->setHour(10));  // minggu lalu: 2 kunjungan
        $this->visit($u, $ws->copy()->subWeeks(2)->setHour(10));          // 2 minggu lalu: hanya 1 (memutus streak)

        $res = $this->getJson('/api/targets')->assertOk();
        $res->assertJsonPath('items.0.progress', 2)
            ->assertJsonPath('current_streak_weeks', 2)
            ->assertJsonPath('best_streak_weeks', 2);
        $this->assertTrue($res->json('week_dots.0'));      // Senin ada kunjungan
        $this->assertFalse($res->json('week_dots.6') && today()->dayOfWeekIso !== 7); // Minggu kosong kecuali hari ini minggu
        $this->assertSame(2, $u->fresh()->best_streak);
    }

    // ----------------------------------------------------------- pembekuan

    public function test_freeze_request_validation(): void
    {
        $u = $this->member();
        Sanctum::actingAs($u);
        $start = today()->addDays(2)->toDateString();

        $this->postJson('/api/membership/freeze-requests', ['start' => today()->subDay()->toDateString(), 'days' => 5, 'reason' => 'Sakit'])->assertStatus(422);
        $this->postJson('/api/membership/freeze-requests', ['start' => $start, 'days' => 31, 'reason' => 'Sakit'])->assertStatus(422);
        $this->postJson('/api/membership/freeze-requests', ['start' => $start, 'days' => 5, 'reason' => ''])->assertStatus(422);

        $this->postJson('/api/membership/freeze-requests', ['start' => $start, 'days' => 5, 'reason' => 'Sakit'])
            ->assertCreated()->assertJsonPath('status', 'pending');
        // masih ada permintaan yang menunggu
        $this->postJson('/api/membership/freeze-requests', ['start' => $start, 'days' => 5, 'reason' => 'Lagi'])->assertStatus(422);
        $this->getJson('/api/membership/freeze')->assertOk()->assertJsonPath('pending_request.days', 5);
    }

    public function test_admin_approves_freeze_extends_membership_and_cancels_bookings(): void
    {
        $u = $this->member();
        $oldEnd = $u->membership->ends_on->toDateString();
        $inside = GymClass::create(['title' => 'Yoga', 'studio' => 'A', 'coach' => 'R', 'category' => 'Yoga',
            'starts_at' => now()->addDays(4), 'capacity' => 10]);
        $outside = GymClass::create(['title' => 'HIIT', 'studio' => 'B', 'coach' => 'D', 'category' => 'HIIT',
            'starts_at' => now()->addDays(20), 'capacity' => 10]);
        Booking::create(['user_id' => $u->id, 'gym_class_id' => $inside->id]);
        Booking::create(['user_id' => $u->id, 'gym_class_id' => $outside->id]);

        Sanctum::actingAs($u);
        $reqId = $this->postJson('/api/membership/freeze-requests', [
            'start' => today()->addDays(2)->toDateString(), 'days' => 7, 'reason' => 'Dinas luar',
        ])->json('id');

        Sanctum::actingAs($this->member('Bayu'));
        $this->postJson("/api/admin/freeze-requests/{$reqId}/decision", ['approve' => true])->assertForbidden();

        Sanctum::actingAs($this->admin());
        $this->getJson('/api/admin/freeze-requests?status=pending')->assertJsonCount(1, 'items');
        $this->postJson("/api/admin/freeze-requests/{$reqId}/decision", ['approve' => true])
            ->assertOk()->assertJsonPath('status', 'approved');
        $this->postJson("/api/admin/freeze-requests/{$reqId}/decision", ['approve' => true])->assertStatus(409);

        $m = $u->fresh()->membership;
        $this->assertSame(7, $m->freeze_days_used);
        $this->assertSame(today()->parse($oldEnd)->addDays(7)->toDateString(), $m->ends_on->toDateString());
        $this->assertNotNull($m->currentFreeze());
        $this->assertSame([$outside->id], Booking::where('user_id', $u->id)->pluck('gym_class_id')->all());
    }

    public function test_admin_rejects_request_and_nothing_changes(): void
    {
        $u = $this->member();
        $end = $u->membership->ends_on->toDateString();
        $req = FreezeRequest::create(['user_id' => $u->id, 'type' => 'freeze', 'reason' => 'x',
            'since' => today()->addDay(), 'days' => 5, 'status' => 'pending']);

        Sanctum::actingAs($this->admin());
        $this->postJson("/api/admin/freeze-requests/{$req->id}/decision", ['approve' => false, 'note' => 'Belum bisa'])
            ->assertOk()->assertJsonPath('status', 'rejected')->assertJsonPath('decision_note', 'Belum bisa');

        $this->assertSame($end, $u->fresh()->membership->ends_on->toDateString());
        $this->assertNull($u->fresh()->membership->currentFreeze());
    }

    public function test_unfreeze_in_progress_returns_unused_days(): void
    {
        $u = $this->member();
        $m = $u->membership;
        // beku 10 hari: mulai 2 hari lalu → hari ini adalah hari ke-3, tersisa 8 hari (inklusif)
        Freeze::create(['membership_id' => $m->id, 'starts_on' => today()->subDays(2), 'ends_on' => today()->addDays(7),
            'reason' => 'Sakit', 'remaining_at_start' => 60]);
        $m->update(['freeze_days_used' => 10, 'ends_on' => today()->addDays(70)]);

        Sanctum::actingAs($u);
        $reqId = $this->postJson('/api/membership/unfreeze-requests')->assertCreated()->assertJsonPath('days', 8)->json('id');

        Sanctum::actingAs($this->admin());
        $this->postJson("/api/admin/freeze-requests/{$reqId}/decision", ['approve' => true])->assertOk();

        $m = $u->fresh()->membership;
        $this->assertNull($m->currentFreeze());
        $this->assertSame(2, $m->freeze_days_used);
        $this->assertSame(today()->addDays(62)->toDateString(), $m->ends_on->toDateString());
    }

    public function test_cannot_request_unfreeze_without_active_freeze(): void
    {
        Sanctum::actingAs($this->member());
        $this->postJson('/api/membership/unfreeze-requests')->assertStatus(422);
    }
}
