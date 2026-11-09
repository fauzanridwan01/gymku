<?php

namespace Tests\Feature;

use App\Models\Membership;
use App\Models\Plan;
use App\Models\Promo;
use App\Models\PromoCode;
use App\Models\Transaction;
use App\Models\User;
use Database\Seeders\PlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CheckoutTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(PlanSeeder::class);
        PromoCode::create(['code' => 'GYMKU20', 'discount_percent' => 20]);
    }

    private function member(string $name = 'Budi'): User
    {
        return User::factory()->create(['name' => $name, 'email' => strtolower($name) . '@x.id', 'role' => 'member']);
    }

    private function admin(): User
    {
        return User::factory()->create(['name' => 'admin', 'email' => 'admin@x.id', 'role' => 'admin']);
    }

    /** Bayar (simulasi) dan wajib 200; jika gagal, tampilkan isi respons. */
    private function pay(string $code)
    {
        $res = $this->postJson("/api/orders/{$code}/simulate-pay");
        $this->assertSame(200, $res->status(), 'Respons: ' . $res->getContent());
        return $res;
    }

    private function renewalPromo(): Promo
    {
        $p = Promo::create([
            'name' => 'Perpanjang 20%', 'type' => 'percent', 'value' => 20, 'quota' => 5, 'used' => 0,
            'renewal_only' => true, 'starts_on' => today()->subDay(), 'ends_on' => today()->addDays(10),
        ]);
        $p->plans()->sync(Plan::whereIn('code', ['3m', '6m'])->pluck('id'));
        return $p;
    }

    public function test_plans_list_shows_renewal_promo_only_for_active_members(): void
    {
        $this->renewalPromo();
        $new = $this->member('Baru');
        $old = $this->member('Lama');
        Membership::create(['user_id' => $old->id, 'plan_name' => 'Premium', 'starts_on' => today()->subDays(10),
            'ends_on' => today()->addDays(20), 'total_days' => 30]);

        Sanctum::actingAs($new);
        $items = collect($this->getJson('/api/plans')->assertOk()->json('items'))->keyBy('code');
        $this->assertNull($items['6m']['promo']);

        Sanctum::actingAs($old);
        $items = collect($this->getJson('/api/plans')->json('items'))->keyBy('code');
        $this->assertSame(1360000, $items['6m']['promo']['final_price']); // 1.700.000 - 20%
        $this->assertNull($items['1m']['promo']);
    }

    public function test_order_and_simulated_payment_creates_membership(): void
    {
        $u = $this->member();
        Sanctum::actingAs($u);

        $order = $this->postJson('/api/orders', ['plan_code' => '1m'])->assertCreated()
            ->assertJson(['status' => 'pending', 'amount' => 350000])->json();
        $this->assertMatchesRegularExpression('/^TRX-\d{4}$/', $order['code']);

        $this->pay($order['code'])
            ->assertJson(['transaction' => ['status' => 'paid'], 'membership' => ['total_days' => 30, 'is_active' => true]]);

        $this->assertNotNull($u->fresh()->joined_at);
        $this->postJson("/api/orders/{$order['code']}/simulate-pay")->assertStatus(409);
        $this->getJson('/api/transactions')->assertOk()->assertJsonCount(1, 'items');
    }

    public function test_renewal_extends_existing_membership_and_counts_promo_use(): void
    {
        $promo = $this->renewalPromo();
        $u = $this->member();
        Membership::create(['user_id' => $u->id, 'plan_name' => 'Premium', 'starts_on' => today()->subDays(10),
            'ends_on' => today()->addDays(20), 'total_days' => 30]);
        Sanctum::actingAs($u);

        $order = $this->postJson('/api/orders', ['plan_code' => '3m'])->assertCreated()
            ->assertJson(['discount' => 180000, 'amount' => 720000])->json();
        $this->pay($order['code']);

        $m = $u->fresh()->membership;
        $this->assertSame(120, $m->total_days);
        $this->assertSame(today()->addDays(110)->toDateString(), $m->ends_on->toDateString());
        $this->assertSame(1, $promo->fresh()->used);
    }

    public function test_promo_code_overrides_auto_promo_and_invalid_code_rejected(): void
    {
        $this->renewalPromo();
        Sanctum::actingAs($this->member());

        $this->postJson('/api/orders', ['plan_code' => '1m', 'promo_code' => 'gymku20'])->assertCreated()
            ->assertJson(['discount' => 70000, 'amount' => 280000, 'promo_label' => 'GYMKU20']);
        $this->postJson('/api/orders', ['plan_code' => '1m', 'promo_code' => 'NGAWUR'])->assertStatus(422);
    }

    public function test_expired_order_cannot_be_paid_but_can_be_refreshed(): void
    {
        $u = $this->member();
        Sanctum::actingAs($u);
        $order = $this->postJson('/api/orders', ['plan_code' => '1m'])->json();
        Transaction::where('code', $order['code'])->update(['expires_at' => now()->subMinute()]);

        $this->postJson("/api/orders/{$order['code']}/simulate-pay")->assertStatus(422);
        $this->assertSame('expired', Transaction::where('code', $order['code'])->value('status'));

        $this->postJson("/api/orders/{$order['code']}/refresh")->assertOk()->assertJson(['status' => 'pending']);
        $this->pay($order['code']);
    }

    public function test_cannot_touch_someone_elses_order(): void
    {
        Sanctum::actingAs($this->member('Ani'));
        $code = $this->postJson('/api/orders', ['plan_code' => '1m'])->json('code');

        Sanctum::actingAs($this->member('Bayu'));
        $this->getJson("/api/orders/{$code}")->assertNotFound();
        $this->postJson("/api/orders/{$code}/simulate-pay")->assertNotFound();
    }

    public function test_admin_can_change_price_and_toggle_plan(): void
    {
        Sanctum::actingAs($this->admin());
        $id = Plan::where('code', '1m')->value('id');

        $this->putJson("/api/admin/plans/{$id}", ['price' => 400000])->assertOk()->assertJson(['price' => 400000]);
        $this->putJson("/api/admin/plans/{$id}", ['price' => 400000])->assertStatus(422);
        $this->putJson("/api/admin/plans/{$id}", ['price' => 1000])->assertStatus(422);

        $this->patchJson("/api/admin/plans/{$id}/enabled", ['enabled' => false])->assertOk();
        Plan::where('code', '!=', '3m')->update(['is_enabled' => false]);
        $last = Plan::where('code', '3m')->value('id');
        $this->patchJson("/api/admin/plans/{$last}/enabled", ['enabled' => false])->assertStatus(422);
    }

    public function test_admin_promo_crud_and_member_forbidden(): void
    {
        $body = [
            'name' => 'Promo Baru', 'type' => 'percent', 'value' => 15, 'quota' => 10,
            'plan_codes' => ['1m', '3m'], 'renewal_only' => false,
            'starts_on' => today()->toDateString(), 'ends_on' => today()->addDays(5)->toDateString(),
        ];

        Sanctum::actingAs($this->member());
        $this->postJson('/api/admin/promos', $body)->assertForbidden();

        Sanctum::actingAs($this->admin());
        $this->postJson('/api/admin/promos', array_merge($body, ['value' => 150]))->assertStatus(422);
        $id = $this->postJson('/api/admin/promos', $body)->assertCreated()
            ->assertJson(['status' => 'running'])->json('id');
        $this->postJson("/api/admin/promos/{$id}/end")->assertOk()->assertJson(['status' => 'done']);
    }
}
