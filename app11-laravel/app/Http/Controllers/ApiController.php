<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ApiController extends Controller
{
    // In-memory storage for demo purposes
    private static $users = [
        ['id' => 1, 'name' => 'John Doe', 'email' => 'john@example.com'],
        ['id' => 2, 'name' => 'Jane Smith', 'email' => 'jane@example.com'],
        ['id' => 3, 'name' => 'Bob Johnson', 'email' => 'bob@example.com'],
    ];

    /**
     * Get all users
     */
    public function getUsers(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => self::$users,
            'count' => count(self::$users)
        ]);
    }

    /**
     * Get a single user by ID
     */
    public function getUser(int $id): JsonResponse
    {
        $user = collect(self::$users)->firstWhere('id', $id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $user
        ]);
    }

    /**
     * Create a new user
     */
    public function createUser(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
        ]);

        $newUser = [
            'id' => count(self::$users) + 1,
            'name' => $validated['name'],
            'email' => $validated['email'],
        ];

        self::$users[] = $newUser;

        return response()->json([
            'success' => true,
            'message' => 'User created successfully',
            'data' => $newUser
        ], 201);
    }

    /**
     * Update an existing user
     */
    public function updateUser(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|max:255',
        ]);

        $userIndex = collect(self::$users)->search(fn($user) => $user['id'] == $id);

        if ($userIndex === false) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        if (isset($validated['name'])) {
            self::$users[$userIndex]['name'] = $validated['name'];
        }
        if (isset($validated['email'])) {
            self::$users[$userIndex]['email'] = $validated['email'];
        }

        return response()->json([
            'success' => true,
            'message' => 'User updated successfully',
            'data' => self::$users[$userIndex]
        ]);
    }

    /**
     * Delete a user
     */
    public function deleteUser(int $id): JsonResponse
    {
        $userIndex = collect(self::$users)->search(fn($user) => $user['id'] == $id);

        if ($userIndex === false) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        $deletedUser = self::$users[$userIndex];
        unset(self::$users[$userIndex]);
        self::$users = array_values(self::$users); // Re-index array

        return response()->json([
            'success' => true,
            'message' => 'User deleted successfully',
            'data' => $deletedUser
        ]);
    }
}
