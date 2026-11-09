<?php

use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\Admin\AnnouncementController as AdminAnnouncementController;
use App\Http\Controllers\Api\Admin\MemberController as AdminMemberController;
use App\Http\Controllers\Api\Admin\CheckInController as AdminCheckInController;
use App\Http\Controllers\Api\Admin\PlanController as AdminPlanController;
use App\Http\Controllers\Api\Admin\PromoController as AdminPromoController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\CheckInController;
use App\Http\Controllers\Api\ClassController;
use App\Http\Controllers\Api\FaceController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PlanController;
use App\Http\Middleware\EnsureAdmin;
use Illuminate\Support\Facades\Route;

Route::get('/ping', fn () => ['ok' => true, 'app' => 'GYMKU']);

Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
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

    // Admin
    Route::middleware(EnsureAdmin::class)->prefix('admin')->group(function () {
        Route::get('/members', [AdminMemberController::class, 'index']);
        Route::post('/checkins', [AdminCheckInController::class, 'store']);
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
