/// Feature flag configuration for gradual rollout of new features
/// This allows safe deployment and testing of new functionality

import 'package:flutter/foundation.dart';

class FeatureFlags {
  static const String _logPrefix = '[FEATURE_FLAGS]';

  // =============================================================================
  // COMPUTED STATE FEATURES
  // =============================================================================

  /// Enable pre-computed Firestore state for instant badge updates
  /// When true: Uses poller-computed data for < 1 second response
  /// When false: Falls back to traditional client-side discovery (10-30 seconds)
  static const bool useComputedPendingState = true;

  /// Enable SQLite caching of computed state for offline support
  /// When true: Caches Firestore data locally for offline access
  /// When false: Always fetches from Firestore (network required)
  static const bool useComputedStateCache = true;

  /// Enable background refresh of stale computed state
  /// When true: Automatically refreshes stale data in background
  /// When false: Only refreshes on manual user action
  static const bool useBackgroundStateRefresh = true;

  /// Staleness threshold for computed state (in minutes)
  /// Data older than this will be considered stale and refreshed
  static const int computedStateStalenessMinutes = 15;

  // =============================================================================
  // SIGNING PATH FEATURES
  // =============================================================================

  /// Use signing paths from computed state instead of separate Firebase collection
  /// When true: Gets signing paths from computed state (single source of truth)
  /// When false: Uses separate Firebase signing paths collection
  static const bool useComputedSigningPaths = true;

  /// Enable fallback to legacy discovery when computed state is unavailable
  /// When true: Falls back to expensive client-side discovery
  /// When false: Shows error when computed state is missing
  static const bool allowLegacyDiscoveryFallback = true;

  // =============================================================================
  // DEVELOPMENT & TESTING
  // =============================================================================

  /// Enable debug logging for computed state operations
  /// When true: Logs detailed information about state loading and caching
  /// When false: Only logs errors and warnings
  static const bool debugComputedState = kDebugMode;

  /// Force refresh computed state on every app launch (for testing)
  /// When true: Always fetches fresh data from Firestore
  /// When false: Uses cached data when available
  static const bool alwaysRefreshOnLaunch = false;

  /// Simulate slow computed state loading (for testing UI)
  /// When true: Adds artificial delay to test loading states
  /// When false: No artificial delays
  static const bool simulateSlowLoading = false;

  /// Delay in milliseconds for simulated slow loading
  static const int simulatedLoadingDelayMs = 3000;

  // =============================================================================
  // GRADUAL ROLLOUT CONTROLS
  // =============================================================================

  /// Percentage of users to enable computed state for (0-100)
  /// Set to 100% for full rollout - we're going all in!
  static const int computedStateRolloutPercentage = 100;

  /// Check if computed state is enabled for a specific user
  /// This uses user ID hash to ensure consistent experience
  static bool isComputedStateEnabledForUser(String uid) {
    if (!useComputedPendingState) return false;
    if (computedStateRolloutPercentage >= 100) return true;
    if (computedStateRolloutPercentage <= 0) return false;

    // Use UID hash to determine if user is in rollout group
    final uidHash = uid.hashCode.abs();
    final userPercentile = uidHash % 100;
    final enabled = userPercentile < computedStateRolloutPercentage;

    if (debugComputedState) {
      debugPrint('$_logPrefix User $uid: hash=$uidHash, percentile=$userPercentile, '
          'enabled=$enabled (rollout: $computedStateRolloutPercentage%)');
    }

    return enabled;
  }

  // =============================================================================
  // LOGGING & MONITORING
  // =============================================================================

  /// Log feature flag status for monitoring and debugging
  static void logFeatureFlagStatus(String uid) {
    if (debugComputedState) {
      debugPrint('$_logPrefix Feature flags for user $uid:');
      debugPrint('$_logPrefix   useComputedPendingState: $useComputedPendingState');
      debugPrint('$_logPrefix   isEnabledForUser: ${isComputedStateEnabledForUser(uid)}');
      debugPrint('$_logPrefix   useComputedStateCache: $useComputedStateCache');
      debugPrint('$_logPrefix   useBackgroundStateRefresh: $useBackgroundStateRefresh');
      debugPrint('$_logPrefix   allowLegacyDiscoveryFallback: $allowLegacyDiscoveryFallback');
      debugPrint('$_logPrefix   staleness threshold: ${computedStateStalenessMinutes}min');
    }
  }

  // =============================================================================
  // CONFIGURATION VALIDATION
  // =============================================================================

  /// Validate feature flag configuration for potential issues
  static List<String> validateConfiguration() {
    final warnings = <String>[];

    if (useComputedPendingState && !allowLegacyDiscoveryFallback) {
      warnings.add('Computed state enabled without legacy fallback - may cause issues for new users');
    }

    if (computedStateStalenessMinutes < 5) {
      warnings.add('Very low staleness threshold (${computedStateStalenessMinutes}min) may cause excessive refreshes');
    }

    if (simulateSlowLoading && simulatedLoadingDelayMs > 10000) {
      warnings.add('Very high simulated loading delay (${simulatedLoadingDelayMs}ms) may impact testing');
    }

    if (alwaysRefreshOnLaunch && !kDebugMode) {
      warnings.add('Always refresh on launch enabled in production - may impact performance');
    }

    return warnings;
  }

  // =============================================================================
  // RUNTIME CONFIGURATION OVERRIDES
  // =============================================================================

  /// Allow runtime override of computed state staleness (for testing)
  static int _runtimeStalenessMinutes = computedStateStalenessMinutes;

  static int get effectiveComputedStateStalenessMinutes => _runtimeStalenessMinutes;

  static void setComputedStateStalenessMinutes(int minutes) {
    _runtimeStalenessMinutes = minutes;
    debugPrint('$_logPrefix Runtime staleness threshold set to ${minutes}min');
  }
}