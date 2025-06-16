// Shared authentication state to prevent circular dependencies

// Track admin verification status to prevent redirect loops
final Map<String, bool> hasVerifiedAdminAccess = {};

// Helper functions to manage verification status
void clearAdminVerificationStatus(String userId) {
  if (hasVerifiedAdminAccess.containsKey(userId)) {
    hasVerifiedAdminAccess.remove(userId);
  }
}

void setAdminVerificationStatus(String userId, bool isAdmin) {
  hasVerifiedAdminAccess[userId] = isAdmin;
}

bool isUserVerified(String userId) {
  return hasVerifiedAdminAccess.containsKey(userId);
}

bool? getUserVerificationStatus(String userId) {
  return hasVerifiedAdminAccess[userId];
}