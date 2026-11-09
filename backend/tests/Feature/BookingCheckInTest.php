<?php

namespace Tests\Feature;

use App\Models\BlockRecord;
use App\Models\Booking;
use App\Models\CheckIn;
use App\Models\Freeze;
use App\Models\GymClass;
use App\Models\Membership;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BookingCheckInTest extends TestCase
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

    private function gymClass(\DateTimeInterface $at, int $capacity = 10): GymClass
    {
        return GymClass::create(['title' => 'Yoga Flow', 'studio' => 'Studio A', 'coach' => 'Coach Rina',
            'category' => 'Yoga', 'starts_at' => $at, 'capacity' => $capacity]);
    }

    public function test_class_list_by_date_shows_slots_and_my_booking(): void
    {
        $u = $this->member();
        $tomorrow = $this->gymClass(now()->addDay()->setHour(10)->setMinute(0), 3);
        $this->gymClass(now()->addDays(2)->setHour(10)->setMinute(0));
        Booking::create(['user_id' => $this->member('Ani')->id, 'gym_class_id' => $tomorrow->id]);
        Booking::create(['user_id' => $u->id, 'gym_class_id' => $tomorrow->id]);

        Sanctum::actingAs($u);
        $res = $this->getJson('/api/classes?date=' . now()->addDay()->toDateString())->assertOk();
        $res->assertJsonCount(1, 'items');
        $res->assertJsonPath('items.0.booked_count', 2)->assertJsonPath('items.0.slots_left', 1)
            ->assertJsonPath('items.0.is_booked', true);
    }

    public function test_book_and_cancel(): void
    {
        $u = $this->member();
        $c = $this->gymClass(now()->addDay());
        Sanctum::actingAs($u);

        $this->postJson('/api/bookings', ['class_id' => $c->id])->assertCreated()->assertJsonPath('is_booked', true);
        $this->postJson('/api/bookings', ['class_id' => $c->id])->assertStatus(409);
        $this->getJson('/api/bookings')->assertJsonCount(1, 'items');

        $this->deleteJson("/api/bookings/{$c->id}")->assertOk();
        $this->assertSame(0, Booking::count());
    }

    public function test_cannot_book_full_started_or_without_membership(): void
    {
        $u = $this->member();
        $full = $this->gymClass(now()->addDay(), 1);
        Booking::create(['user_id' => $this->member('Ani')->id, 'gym_class_id' => $full->id]);
        $past = $this->gymClass(now()->subHour());

        Sanctum::actingAs($u);
        $this->postJson('/api/bookings', ['class_id' => $full->id])->assertStatus(422);
        $this->postJson('/api/bookings', ['class_id' => $past->id])->assertStatus(422);

        Sanctum::actingAs($this->member('Tamu', withMembership: false));
        $this->postJson('/api/bookings', ['class_id' => $full->id])->assertStatus(422);
    }

    public function test_cannot_cancel_within_one_hour(): void
    {
        $u = $this->member();
        $soon = $this->gymClass(now()->addMinutes(30));
        Booking::create(['user_id' => $u->id, 'gym_class_id' => $soon->id]);

        Sanctum::actingAs($u);
        $this->deleteJson("/api/bookings/{$soon->id}")->assertStatus(422);
        $this->assertSame(1, Booking::count());
    }

    public function test_frozen_member_cannot_book_or_check_in(): void
    {
        $u = $this->member();
        Freeze::create(['membership_id' => $u->membership->id, 'starts_on' => today()->subDay(),
            'ends_on' => today()->addDays(5), 'reason' => 'Sakit', 'remaining_at_start' => 60]);
        $c = $this->gymClass(now()->addDay());

        Sanctum::actingAs($u);
        $this->postJson('/api/bookings', ['class_id' => $c->id])->assertStatus(422);
        $this->postJson('/api/checkins')->assertForbidden();
    }

    public function test_cannot_book_class_inside_future_freeze(): void
    {
        $u = $this->member();
        Freeze::create(['membership_id' => $u->membership->id, 'starts_on' => today()->addDays(3),
            'ends_on' => today()->addDays(10), 'reason' => 'Liburan', 'remaining_at_start' => 55]);
        $inside = $this->gymClass(now()->addDays(5));
        $outside = $this->gymClass(now()->addDay());

        Sanctum::actingAs($u);
        $this->postJson('/api/bookings', ['class_id' => $inside->id])->assertStatus(422);
        $this->postJson('/api/bookings', ['class_id' => $outside->id])->assertCreated();
    }

    public function test_check_in_and_history(): void
    {
        $u = $this->member();
        Sanctum::actingAs($u);

        $this->postJson('/api/checkins')->assertCreated()->assertJsonPath('method', 'face');
        $this->postJson('/api/checkins')->assertStatus(409); // baru saja check-in

        $this->getJson('/api/checkins')->assertOk()
            ->assertJsonPath('visits_this_month', 1)->assertJsonPath('active_days_this_month', 1)
            ->assertJsonCount(1, 'items');
    }

    public function test_blocked_and_expired_cannot_check_in(): void
    {
        $blocked = $this->member('Agus');
        $blocked->update(['is_blocked' => true]);
        BlockRecord::create(['user_id' => $blocked->id, 'reason' => 'Meminjamkan akun', 'active' => true]);

        $expired = $this->member('Lama', withMembership: false);
        Membership::create(['user_id' => $expired->id, 'plan_name' => 'Premium', 'starts_on' => today()->subDays(40),
            'ends_on' => today()->subDays(10), 'total_days' => 30]);

        Sanctum::actingAs($blocked);
        $this->postJson('/api/checkins')->assertForbidden()->assertJsonPath('message', 'Akun diblokir: Meminjamkan akun');
        Sanctum::actingAs($expired);
        $this->postJson('/api/checkins')->assertForbidden();
    }

    public function test_admin_check_in_member(): void
    {
        $m = $this->member();
        Sanctum::actingAs($this->admin());

        $this->postJson('/api/admin/checkins', ['user_id' => $m->id, 'method' => 'manual'])
            ->assertCreated()->assertJsonPath('method', 'manual');
        $this->postJson('/api/admin/checkins', ['user_id' => $m->id])->assertStatus(409);
        $this->assertSame(1, CheckIn::where('user_id', $m->id)->whereNotNull('recorded_by')->count());

        Sanctum::actingAs($m);
        $this->postJson('/api/admin/checkins', ['user_id' => $m->id])->assertForbidden();
    }
}
