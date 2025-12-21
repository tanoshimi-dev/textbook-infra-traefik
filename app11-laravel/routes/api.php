<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ApiController;

// Health check endpoint
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toIso8601String()
    ]);
});

// Simple API endpoints
Route::get('/users', [ApiController::class, 'getUsers']);
Route::get('/users/{id}', [ApiController::class, 'getUser']);
Route::post('/users', [ApiController::class, 'createUser']);
Route::put('/users/{id}', [ApiController::class, 'updateUser']);
Route::delete('/users/{id}', [ApiController::class, 'deleteUser']);

// Example: Get current user (protected route)
Route::middleware('api')->get('/me', function (Request $request) {
    return response()->json([
        'user' => [
            'id' => 1,
            'name' => 'Demo User',
            'email' => 'demo@example.com'
        ]
    ]);
});
