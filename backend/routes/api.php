<?php

use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\Admin\AnnouncementController as AdminAnnouncementController;
use App\Http\Controllers\Api\Admin\MemberController as AdminMemberController;
use App\Http\Controllers\Api\Admin\CheckInController as AdminCheckInController;
use App\Http\Controllers\Api\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Api\Admin\FreezeRequestController as AdminFreezeRequestController;
use App\Http\Controllers\Api\Admin\LogController as AdminLogController;
use App\Http\Controllers\Api\Admin\PlanController as AdminPlanController;
use App\Http\Controllers\Api\Admin\PromoController as AdminPromoController;
use App\Http\Controllers\Api\Admin\ScanController as AdminScanController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\CheckInController;
use App\Http\Controllers\Api\ClassController;
use App\Http\Controllers\Api\FaceController;
use App\Http\Controllers\Api\FreezeController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PlanController;
use App\Http\Controllers\Api\TargetController;
use App\Http\Middleware\EnsureAdmin;
use App\Http\Middleware\EnsureNotBlocked;
use Illuminate\Support\Facades\Route;

Route::get('/ping', fn () => ['ok' => true, 'app' => 'GYMKU']);

Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Semua rute lain menolak akun yang diblokir
    Route::middleware(EnsureNotBlocked::class)->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::put('/me', [AuthController::class, 'update']);
        Route::put('/me/password', [AuthController::class, 'changePassword']);
        Route::post('/me/face', [FaceController::class, 'enroll']);

        // Pusat Informasi (member)
        Route::get('/announcements', [AnnouncementController::class, 'index']);
        Route::post('/announcements/{id}/view', [AnnouncementController::class, 'view']);

        // Paket & checkout (QRIS simulasi)
        Route::get('/plans', [PlanController::class, 'index']);
        Route::post('/orders', [OrderController::class, 'store']);
        Route::get('/orders/{code}', [OrderController::class, 'show']);
        Route::post('/orders/{code}/refresh', [OrderController::class, 'refresh']);
        Route::post('/orders/{code}/cancel', [OrderController::class, 'cancel']);
        Route::post('/orders/{code}/simulate-pay', [OrderController::class, 'simulatePay']);
        Route::get('/transactions', [OrderController::class, 'history']);

        // Kelas, booking, check-in
        Route::get('/classes', [ClassController::class, 'index']);
        Route::get('/bookings', [BookingController::class, 'index']);
        Route::post('/bookings', [BookingController::class, 'store']);
        Route::delete('/bookings/{classId}', [BookingController::class, 'destroy']);
        Route::get('/checkins', [CheckInController::class, 'index']);
        Route::post('/checkins', [CheckInController::class, 'store']);

        // Target & streak
        Route::get('/targets', [TargetController::class, 'index']);
        Route::post('/targets', [TargetController::class, 'store']);
        Route::delete('/targets/{id}', [TargetController::class, 'destroy']);

        // Pembekuan membership
        Route::get('/membership/freeze', [FreezeController::class, 'show']);
        Route::get('/membership/freeze-requests', [FreezeController::class, 'index']);
        Route::post('/membership/freeze-requests', [FreezeController::class, 'requestFreeze']);
        Route::post('/membership/unfreeze-requests', [FreezeController::class, 'requestUnfreeze']);

        // Admin
        Route::middleware(EnsureAdmin::class)->prefix('admin')->group(function () {
            Route::get('/members', [AdminMemberController::class, 'index']);
            Route::get('/members/{id}', [AdminMemberController::class, 'show']);
            Route::post('/members/{id}/block', [AdminMemberController::class, 'block']);
            Route::post('/members/{id}/unblock', [AdminMemberController::class, 'unblock']);
            Route::get('/blocks', [AdminMemberController::class, 'blocks']);
            Route::get('/dashboard', [AdminDashboardController::class, 'dashboard']);
            Route::get('/reports', [AdminDashboardController::class, 'reports']);
            Route::get('/logs', [AdminLogController::class, 'index']);
            Route::get('/transactions', [AdminLogController::class, 'transactions']);
            Route::post('/scan', [AdminScanController::class, 'recognize']);
            Route::post('/checkins', [AdminCheckInController::class, 'store']);
            Route::get('/freeze-requests', [AdminFreezeRequestController::class, 'index']);
            Route::post('/freeze-requests/{id}/decision', [AdminFreezeRequestController::class, 'decide']);
            Route::get('/plans', [AdminPlanController::class, 'index']);
            Route::put('/plans/{id}', [AdminPlanController::class, 'updatePrice']);
            Route::patch('/plans/{id}/enabled', [AdminPlanController::class, 'setEnabled']);
            Route::get('/promos', [AdminPromoController::class, 'index']);
            Route::post('/promos', [AdminPromoController::class, 'store']);
            Route::put('/promos/{id}', [AdminPromoController::class, 'update']);
            Route::post('/promos/{id}/end', [AdminPromoController::class, 'end']);
            Route::patch('/promos/{id}/enabled', [AdminPromoController::class, 'setEnabled']);
            Route::get('/announcements', [AdminAnnouncementController::class, 'index']);
            Route::post('/announcements', [AdminAnnouncementController::class, 'store']);
            Route::put('/announcements/{id}', [AdminAnnouncementController::class, 'update']);
            Route::patch('/announcements/{id}/archive', [AdminAnnouncementController::class, 'archive']);
            Route::delete('/announcements/{id}', [AdminAnnouncementController::class, 'destroy']);
        });
    });
});
