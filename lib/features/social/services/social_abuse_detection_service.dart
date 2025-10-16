import 'dart:async';
import 'dart:math' as math;

import '../../../core/utils/either.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/analytics/analytics_service.dart';

/// Service for detecting and monitoring abuse in social features
class SocialAbuseDetectionService {
  final AnalyticsService _analytics;
  // final StorageService _storage; // TODO: Use for persistence

  // Detection data
  final Map<String, UserBehaviorProfile> _userProfiles = {};
  final Map<String, List<AbuseSignal>> _abuseSignals = {};
  // final Map<String, List<ContentAnalysis>> _contentAnalyses = {}; // TODO: Define ContentAnalysis class
  final List<AbuseIncident> _recentIncidents = [];

  // Detection timers
  Timer? _behaviorAnalysisTimer;
  Timer? _patternDetectionTimer;
  Timer? _reportProcessingTimer;
  Timer? _cleanupTimer;

  // Configuration
  static const Duration _behaviorAnalysisInterval = Duration(minutes: 10);
  static const Duration _patternDetectionInterval = Duration(minutes: 30);
  static const Duration _reportProcessingInterval = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(days: 1);
  static const int _maxSignalHistory = 10000;

  // Detection thresholds (TODO: Use these in detection algorithms)
  // static const double _spamThreshold = 0.7;
  // static const double _harassmentThreshold = 0.8;
  // static const double _botBehaviorThreshold = 0.75;
  static const int _rapidActionThreshold = 10; // actions per minute

  SocialAbuseDetectionService({
    required AnalyticsService analytics,
    required StorageService storage, // TODO: Use storage for persistence
  })  : _analytics = analytics {
    _initializeAbuseDetection();
  }

  /// Initialize abuse detection system
  void _initializeAbuseDetection() {
    // Behavior analysis every 10 minutes
    _behaviorAnalysisTimer = Timer.periodic(_behaviorAnalysisInterval, (_) async {
      await _analyzeBehaviorPatterns();
    });

    // Pattern detection every 30 minutes
    _patternDetectionTimer = Timer.periodic(_patternDetectionInterval, (_) async {
      await _detectAbusePatterns();
    });

    // Process reports every 5 minutes
    _reportProcessingTimer = Timer.periodic(_reportProcessingInterval, (_) async {
      await _processAbuseReports();
    });

    // Cleanup daily
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) async {
      await _cleanupOldData();
    });
  }

  /// Record user action for analysis
  void recordUserAction({
    required String userId,
    required String action,
    required String targetType,
    String? targetId,
    String? content,
    Map<String, dynamic>? metadata,
  }) {
    final signal = AbuseSignal(
      userId: userId,
      action: action,
      targetType: targetType,
      targetId: targetId,
      content: content,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      riskScore: _calculateInitialRiskScore(action, content),
    );

    // Add to signals buffer
    _abuseSignals.putIfAbsent(userId, () => <AbuseSignal>[]);
    final userSignals = _abuseSignals[userId]!;
    
    if (userSignals.length >= _maxSignalHistory) {
      userSignals.removeAt(0);
    }
    userSignals.add(signal);

    // Update user behavior profile
    _updateUserBehaviorProfile(userId, signal);

    // Check for immediate threats
    _checkImmediateThreats(userId, signal);

    // Track in analytics
    _analytics.trackEvent('abuse_signal_recorded', {
      'user_id': userId,
      'action': action,
      'target_type': targetType,
      'risk_score': signal.riskScore,
      'timestamp': signal.timestamp.toIso8601String(),
    });
  }

  /// Process abuse report
  Future<Either<String, String>> processAbuseReport({
    required String reporterId,
    required String reportedUserId,
    required String reportType,
    required String description,
    String? contentId,
    Map<String, dynamic>? evidence,
  }) async {
    try {
      final report = AbuseReport(
        id: _generateReportId(),
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reportType: reportType,
        description: description,
        contentId: contentId,
        evidence: evidence ?? {},
        timestamp: DateTime.now(),
        status: ReportStatus.pending,
        priority: _calculateReportPriority(reportType, evidence),
      );

      // Store the report
      await _storeAbuseReport(report);

      // Update user profiles with report data
      _updateProfileWithReport(report);

      // Check if this triggers immediate action
      final actionNeeded = await _assessImmediateAction(report);
      if (actionNeeded != null) {
        await _takeImmediateAction(report, actionNeeded);
      }

      // Track report
      _analytics.trackEvent('abuse_report_submitted', {
        'reporter_id': reporterId,
        'reported_user_id': reportedUserId,
        'report_type': reportType,
        'priority': report.priority.toString(),
        'timestamp': report.timestamp.toIso8601String(),
      });

      return Right(report.id);
    } catch (e) {
      return Left('Failed to process abuse report: $e');
    }
  }

  /// Get comprehensive abuse metrics
  Future<Either<String, SocialAbuseMetrics>> getAbuseMetrics({
    Duration period = const Duration(days: 7),
    bool includeDetails = false,
  }) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(period);

      // Calculate metrics
      final spamMetrics = await _calculateSpamMetrics(startTime, now);
      final harassmentMetrics = await _calculateHarassmentMetrics(startTime, now);
      final botDetectionMetrics = await _calculateBotDetectionMetrics(startTime, now);
      final reportingMetrics = await _calculateReportingMetrics(startTime, now);
      final moderationMetrics = await _calculateModerationMetrics(startTime, now);
      final trendAnalysis = await _calculateAbuseTrends(startTime, now);

      final metrics = SocialAbuseMetrics(
        period: period,
        calculatedAt: now,
        spamDetection: spamMetrics,
        harassmentDetection: harassmentMetrics,
        botDetection: botDetectionMetrics,
        reportingMetrics: reportingMetrics,
        moderationMetrics: moderationMetrics,
        trendAnalysis: trendAnalysis,
        riskUsers: await _identifyRiskUsers(),
        recentIncidents: includeDetails ? _recentIncidents : [],
      );

      return Right(metrics);
    } catch (e) {
      return Left('Failed to get abuse metrics: $e');
    }
  }

  /// Get spam detection metrics
  Future<SpamDetectionMetrics> _calculateSpamMetrics(DateTime start, DateTime end) async {
    final spamIncidents = _recentIncidents
        .where((i) => i.type == 'spam' && 
                     i.detectedAt.isAfter(start) && 
                     i.detectedAt.isBefore(end))
        .toList();

    final totalMessages = await _getTotalMessages(start, end);
    final spamRate = totalMessages == 0 ? 0.0 : spamIncidents.length / totalMessages;

    return SpamDetectionMetrics(
      totalSpamDetected: spamIncidents.length,
      spamRate: spamRate,
      autoModeratedSpam: spamIncidents.where((i) => i.autoModerated).length,
      commonSpamPatterns: _identifyCommonSpamPatterns(spamIncidents),
      spamSources: _analyzeSpamSources(spamIncidents),
      falsePositiveRate: await _calculateSpamFalsePositiveRate(start, end),
      detectionAccuracy: await _calculateSpamDetectionAccuracy(start, end),
    );
  }

  /// Get harassment detection metrics
  Future<HarassmentDetectionMetrics> _calculateHarassmentMetrics(DateTime start, DateTime end) async {
    final harassmentIncidents = _recentIncidents
        .where((i) => i.type == 'harassment' && 
                     i.detectedAt.isAfter(start) && 
                     i.detectedAt.isBefore(end))
        .toList();

    return HarassmentDetectionMetrics(
      totalHarassmentDetected: harassmentIncidents.length,
      severityDistribution: _analyzeSeverityDistribution(harassmentIncidents),
      targetedHarassment: harassmentIncidents.where((i) => i.severity == 'high').length,
      harassmentPatterns: _identifyHarassmentPatterns(harassmentIncidents),
      victimSupport: await _calculateVictimSupportMetrics(start, end),
      escalationRate: await _calculateHarassmentEscalationRate(start, end),
    );
  }

  /// Get bot detection metrics
  Future<BotDetectionMetrics> _calculateBotDetectionMetrics(DateTime start, DateTime end) async {
    final botIncidents = _recentIncidents
        .where((i) => i.type == 'bot_behavior' && 
                     i.detectedAt.isAfter(start) && 
                     i.detectedAt.isBefore(end))
        .toList();

    final suspiciousUsers = _identifySuspiciousBotUsers();

    return BotDetectionMetrics(
      suspiciousBotAccounts: suspiciousUsers.length,
      confirmedBots: botIncidents.where((i) => i.confidence > 0.9).length,
      botActivityPatterns: _analyzeBotActivityPatterns(botIncidents),
      automatedContentDetected: await _countAutomatedContent(start, end),
      botNetworkDetection: _detectBotNetworks(suspiciousUsers),
      botAccuracy: await _calculateBotDetectionAccuracy(start, end),
    );
  }

  /// Get reporting metrics
  Future<ReportingMetrics> _calculateReportingMetrics(DateTime start, DateTime end) async {
    final reports = await _getReportsInPeriod(start, end);
    
    final reportsByType = <String, int>{};
    final reportsByStatus = <ReportStatus, int>{};
    
    for (final report in reports) {
      reportsByType[report.reportType] = (reportsByType[report.reportType] ?? 0) + 1;
      reportsByStatus[report.status] = (reportsByStatus[report.status] ?? 0) + 1;
    }

    return ReportingMetrics(
      totalReports: reports.length,
      reportTypes: reportsByType,
      reportStatus: reportsByStatus,
      averageProcessingTime: await _calculateAverageProcessingTime(reports),
      falseReportRate: await _calculateFalseReportRate(reports),
      actionableReportRate: await _calculateActionableReportRate(reports),
      reporterEngagement: await _calculateReporterEngagement(start, end),
    );
  }

  /// Get moderation metrics
  Future<ModerationMetrics> _calculateModerationMetrics(DateTime start, DateTime end) async {
    final actions = await _getModerationActions(start, end);
    
    final actionsByType = <String, int>{};
    for (final action in actions) {
      actionsByType[action.type] = (actionsByType[action.type] ?? 0) + 1;
    }

    return ModerationMetrics(
      totalModerationActions: actions.length,
      actionTypes: actionsByType,
      autoModerationRate: _calculateAutoModerationRate(actions),
      manualReviewRate: _calculateManualReviewRate(actions),
      appealRate: await _calculateAppealRate(start, end),
      moderationEffectiveness: await _calculateModerationEffectiveness(start, end),
    );
  }

  /// Update user behavior profile
  void _updateUserBehaviorProfile(String userId, AbuseSignal signal) {
    _userProfiles.putIfAbsent(userId, () => UserBehaviorProfile(
      userId: userId,
      firstSeen: DateTime.now(),
      lastActivity: DateTime.now(),
      totalActions: 0,
      riskScore: 0.0,
      behaviorPatterns: {},
      flags: [],
    ));

    final profile = _userProfiles[userId]!;
    profile.lastActivity = signal.timestamp;
    profile.totalActions++;
    
    // Update behavior patterns
    final actionKey = signal.action;
    profile.behaviorPatterns[actionKey] = (profile.behaviorPatterns[actionKey] ?? 0) + 1;

    // Calculate new risk score
    profile.riskScore = _calculateUserRiskScore(userId, profile);

    // Check for flags
    _checkBehaviorFlags(userId, profile, signal);
  }

  /// Calculate initial risk score for an action
  double _calculateInitialRiskScore(String action, String? content) {
    double score = 0.0;

    // Action-based scoring
    switch (action) {
      case 'post':
        score = 0.1;
        break;
      case 'comment':
        score = 0.15;
        break;
      case 'message':
        score = 0.2;
        break;
      case 'friend_request':
        score = 0.3;
        break;
      case 'report':
        score = 0.4;
        break;
      default:
        score = 0.1;
    }

    // Content-based scoring
    if (content != null) {
      score += _analyzeContentRisk(content);
    }

    return math.min(1.0, score);
  }

  /// Analyze content for risk factors
  double _analyzeContentRisk(String content) {
    double risk = 0.0;
    
    final lowercaseContent = content.toLowerCase();
    
    // Check for spam indicators
    if (_isSpammy(lowercaseContent)) {
      risk += 0.3;
    }
    
    // Check for harassment indicators
    if (_isHarassment(lowercaseContent)) {
      risk += 0.4;
    }
    
    // Check for excessive caps
    if (_hasExcessiveCaps(content)) {
      risk += 0.1;
    }
    
    // Check for repetitive content
    if (_isRepetitive(content)) {
      risk += 0.2;
    }

    return math.min(1.0, risk);
  }

  /// Check for immediate threats
  void _checkImmediateThreats(String userId, AbuseSignal signal) {
    // Check for rapid actions
    final recentSignals = _abuseSignals[userId]?.where(
        (s) => DateTime.now().difference(s.timestamp).inMinutes < 1).toList() ?? [];
    
    if (recentSignals.length >= _rapidActionThreshold) {
      _handleRapidActionThreat(userId, recentSignals);
    }

    // Check high-risk content
    if (signal.riskScore > 0.8) {
      _handleHighRiskContent(userId, signal);
    }
  }

  /// Handle rapid action threat
  void _handleRapidActionThreat(String userId, List<AbuseSignal> signals) {
    final incident = AbuseIncident(
      id: _generateIncidentId(),
      type: 'rapid_actions',
      userId: userId,
      detectedAt: DateTime.now(),
      severity: 'medium',
      confidence: 0.8,
      autoModerated: true,
      description: 'Rapid action pattern detected: ${signals.length} actions in 1 minute',
      evidence: {'signals': signals.map((s) => s.action).toList()},
    );

    _recentIncidents.add(incident);
    
    // Could trigger rate limiting or temporary restrictions
    print('RAPID ACTION THREAT: User $userId performed ${signals.length} actions in 1 minute');
  }

  /// Handle high-risk content
  void _handleHighRiskContent(String userId, AbuseSignal signal) {
    if (signal.content != null) {
      final incident = AbuseIncident(
        id: _generateIncidentId(),
        type: _classifyContentThreat(signal.content!),
        userId: userId,
        detectedAt: DateTime.now(),
        severity: 'high',
        confidence: signal.riskScore,
        autoModerated: signal.riskScore > 0.9,
        description: 'High-risk content detected',
        evidence: {'content': signal.content, 'action': signal.action},
      );

      _recentIncidents.add(incident);
      
      print('HIGH RISK CONTENT: User $userId - ${signal.action}');
    }
  }

  /// Calculate user risk score
  double _calculateUserRiskScore(String userId, UserBehaviorProfile profile) {
    double riskScore = 0.0;
    
    // Base score from recent actions
    final recentSignals = _abuseSignals[userId]?.where(
        (s) => DateTime.now().difference(s.timestamp).inHours < 24).toList() ?? [];
    
    if (recentSignals.isNotEmpty) {
      final avgRiskScore = recentSignals.map((s) => s.riskScore).reduce((a, b) => a + b) / recentSignals.length;
      riskScore += avgRiskScore * 0.4;
    }
    
    // Account age factor
    final accountAge = DateTime.now().difference(profile.firstSeen).inDays;
    if (accountAge < 7) {
      riskScore += 0.2; // New accounts are riskier
    }
    
    // Activity frequency factor
    final actionsPerDay = profile.totalActions / math.max(1, accountAge);
    if (actionsPerDay > 100) {
      riskScore += 0.3; // Very active accounts might be bots
    }
    
    // Flag factor
    riskScore += profile.flags.length * 0.1;
    
    return math.min(1.0, riskScore);
  }

  /// Check for behavior flags
  void _checkBehaviorFlags(String userId, UserBehaviorProfile profile, AbuseSignal signal) {
    // Check for repetitive behavior
    final actionCounts = profile.behaviorPatterns;
    final totalActions = actionCounts.values.fold(0, (a, b) => a + b);
    
    for (final entry in actionCounts.entries) {
      final actionRatio = entry.value / totalActions;
      if (actionRatio > 0.8) {
        _addFlag(profile, 'repetitive_behavior', 'Over 80% of actions are ${entry.key}');
      }
    }
    
    // Check for bot-like patterns
    if (_detectBotPattern(userId, profile)) {
      _addFlag(profile, 'bot_behavior', 'Exhibits bot-like behavior patterns');
    }
  }

  /// Add flag to user profile
  void _addFlag(UserBehaviorProfile profile, String flagType, String reason) {
    final flag = BehaviorFlag(
      type: flagType,
      reason: reason,
      timestamp: DateTime.now(),
      severity: _getFlagSeverity(flagType),
    );
    
    // Don't duplicate flags
    if (!profile.flags.any((f) => f.type == flagType)) {
      profile.flags.add(flag);
    }
  }

  // Content analysis methods
  bool _isSpammy(String content) {
    // Check for spam patterns
    return content.contains('buy now') ||
           content.contains('click here') ||
           content.contains('free money') ||
           content.split(' ').where((word) => word == word.toUpperCase() && word.length > 3).length > 3;
  }

  bool _isHarassment(String content) {
    // Check for harassment patterns (would use more sophisticated ML models)
    final harassmentKeywords = ['hate', 'stupid', 'ugly', 'die', 'kill'];
    return harassmentKeywords.any((keyword) => content.contains(keyword));
  }

  bool _hasExcessiveCaps(String content) {
    if (content.isEmpty) return false;
    final capsCount = content.split('').where((char) => char == char.toUpperCase() && char != char.toLowerCase()).length;
    return capsCount / content.length > 0.7;
  }

  bool _isRepetitive(String content) {
    final words = content.split(' ');
    if (words.length < 5) return false;
    
    final wordCounts = <String, int>{};
    for (final word in words) {
      wordCounts[word] = (wordCounts[word] ?? 0) + 1;
    }
    
    return wordCounts.values.any((count) => count > words.length / 2);
  }

  String _classifyContentThreat(String content) {
    if (_isSpammy(content.toLowerCase())) return 'spam';
    if (_isHarassment(content.toLowerCase())) return 'harassment';
    return 'inappropriate_content';
  }

  bool _detectBotPattern(String userId, UserBehaviorProfile profile) {
    // Simple bot detection logic
    final actionVariety = profile.behaviorPatterns.keys.length;
    final totalActions = profile.totalActions;
    
    // Low action variety suggests bot
    if (totalActions > 50 && actionVariety < 3) return true;
    
    // Very regular timing patterns (would need more data)
    return false;
  }

  String _getFlagSeverity(String flagType) {
    switch (flagType) {
      case 'bot_behavior':
        return 'high';
      case 'repetitive_behavior':
        return 'medium';
      case 'spam':
        return 'high';
      case 'harassment':
        return 'critical';
      default:
        return 'low';
    }
  }

  // Helper methods
  String _generateReportId() => 'report_${DateTime.now().millisecondsSinceEpoch}';
  String _generateIncidentId() => 'incident_${DateTime.now().millisecondsSinceEpoch}';
  
  ReportPriority _calculateReportPriority(String reportType, Map<String, dynamic>? evidence) {
    switch (reportType) {
      case 'harassment':
      case 'threats':
        return ReportPriority.urgent;
      case 'spam':
        return ReportPriority.high;
      case 'inappropriate_content':
        return ReportPriority.medium;
      default:
        return ReportPriority.low;
    }
  }

  // Placeholder methods for detailed implementations
  Future<void> _analyzeBehaviorPatterns() async {}
  Future<void> _detectAbusePatterns() async {}
  Future<void> _processAbuseReports() async {}
  Future<void> _cleanupOldData() async {}
  Future<void> _storeAbuseReport(AbuseReport report) async {}
  void _updateProfileWithReport(AbuseReport report) {}
  Future<String?> _assessImmediateAction(AbuseReport report) async => null;
  Future<void> _takeImmediateAction(AbuseReport report, String action) async {}
  Future<int> _getTotalMessages(DateTime start, DateTime end) async => 10000;
  List<String> _identifyCommonSpamPatterns(List<AbuseIncident> incidents) => [];
  Map<String, int> _analyzeSpamSources(List<AbuseIncident> incidents) => {};
  Future<double> _calculateSpamFalsePositiveRate(DateTime start, DateTime end) async => 0.05;
  Future<double> _calculateSpamDetectionAccuracy(DateTime start, DateTime end) async => 0.92;
  Map<String, int> _analyzeSeverityDistribution(List<AbuseIncident> incidents) => {};
  List<String> _identifyHarassmentPatterns(List<AbuseIncident> incidents) => [];
  Future<Map<String, dynamic>> _calculateVictimSupportMetrics(DateTime start, DateTime end) async => {};
  Future<double> _calculateHarassmentEscalationRate(DateTime start, DateTime end) async => 0.1;
  List<String> _identifySuspiciousBotUsers() => [];
  Map<String, dynamic> _analyzeBotActivityPatterns(List<AbuseIncident> incidents) => {};
  Future<int> _countAutomatedContent(DateTime start, DateTime end) async => 50;
  List<String> _detectBotNetworks(List<String> users) => [];
  Future<double> _calculateBotDetectionAccuracy(DateTime start, DateTime end) async => 0.88;
  Future<List<AbuseReport>> _getReportsInPeriod(DateTime start, DateTime end) async => [];
  Future<Duration> _calculateAverageProcessingTime(List<AbuseReport> reports) async => const Duration(hours: 24);
  Future<double> _calculateFalseReportRate(List<AbuseReport> reports) async => 0.15;
  Future<double> _calculateActionableReportRate(List<AbuseReport> reports) async => 0.75;
  Future<Map<String, dynamic>> _calculateReporterEngagement(DateTime start, DateTime end) async => {};
  Future<List<ModerationAction>> _getModerationActions(DateTime start, DateTime end) async => [];
  double _calculateAutoModerationRate(List<ModerationAction> actions) => 0.6;
  double _calculateManualReviewRate(List<ModerationAction> actions) => 0.4;
  Future<double> _calculateAppealRate(DateTime start, DateTime end) async => 0.1;
  Future<double> _calculateModerationEffectiveness(DateTime start, DateTime end) async => 0.85;
  Future<AbuseTrendAnalysis> _calculateAbuseTrends(DateTime start, DateTime end) async => AbuseTrendAnalysis.empty();
  Future<List<String>> _identifyRiskUsers() async => [];

  /// Dispose resources
  void dispose() {
    _behaviorAnalysisTimer?.cancel();
    _patternDetectionTimer?.cancel();
    _reportProcessingTimer?.cancel();
    _cleanupTimer?.cancel();
  }
}

// Data models for abuse detection
enum ReportStatus { pending, investigating, resolved, dismissed }
enum ReportPriority { low, medium, high, urgent }

class AbuseSignal {
  final String userId;
  final String action;
  final String targetType;
  final String? targetId;
  final String? content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final double riskScore;

  const AbuseSignal({
    required this.userId,
    required this.action,
    required this.targetType,
    this.targetId,
    this.content,
    required this.metadata,
    required this.timestamp,
    required this.riskScore,
  });
}

class AbuseReport {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reportType;
  final String description;
  final String? contentId;
  final Map<String, dynamic> evidence;
  final DateTime timestamp;
  final ReportStatus status;
  final ReportPriority priority;

  const AbuseReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportType,
    required this.description,
    this.contentId,
    required this.evidence,
    required this.timestamp,
    required this.status,
    required this.priority,
  });
}

class AbuseIncident {
  final String id;
  final String type;
  final String userId;
  final DateTime detectedAt;
  final String severity;
  final double confidence;
  final bool autoModerated;
  final String description;
  final Map<String, dynamic> evidence;

  const AbuseIncident({
    required this.id,
    required this.type,
    required this.userId,
    required this.detectedAt,
    required this.severity,
    required this.confidence,
    required this.autoModerated,
    required this.description,
    required this.evidence,
  });
}

class UserBehaviorProfile {
  final String userId;
  final DateTime firstSeen;
  DateTime lastActivity;
  int totalActions;
  double riskScore;
  final Map<String, int> behaviorPatterns;
  final List<BehaviorFlag> flags;

  UserBehaviorProfile({
    required this.userId,
    required this.firstSeen,
    required this.lastActivity,
    required this.totalActions,
    required this.riskScore,
    required this.behaviorPatterns,
    required this.flags,
  });
}

class BehaviorFlag {
  final String type;
  final String reason;
  final DateTime timestamp;
  final String severity;

  const BehaviorFlag({
    required this.type,
    required this.reason,
    required this.timestamp,
    required this.severity,
  });
}

class SocialAbuseMetrics {
  final Duration period;
  final DateTime calculatedAt;
  final SpamDetectionMetrics spamDetection;
  final HarassmentDetectionMetrics harassmentDetection;
  final BotDetectionMetrics botDetection;
  final ReportingMetrics reportingMetrics;
  final ModerationMetrics moderationMetrics;
  final AbuseTrendAnalysis trendAnalysis;
  final List<String> riskUsers;
  final List<AbuseIncident> recentIncidents;

  const SocialAbuseMetrics({
    required this.period,
    required this.calculatedAt,
    required this.spamDetection,
    required this.harassmentDetection,
    required this.botDetection,
    required this.reportingMetrics,
    required this.moderationMetrics,
    required this.trendAnalysis,
    required this.riskUsers,
    required this.recentIncidents,
  });
}

class SpamDetectionMetrics {
  final int totalSpamDetected;
  final double spamRate;
  final int autoModeratedSpam;
  final List<String> commonSpamPatterns;
  final Map<String, int> spamSources;
  final double falsePositiveRate;
  final double detectionAccuracy;

  const SpamDetectionMetrics({
    required this.totalSpamDetected,
    required this.spamRate,
    required this.autoModeratedSpam,
    required this.commonSpamPatterns,
    required this.spamSources,
    required this.falsePositiveRate,
    required this.detectionAccuracy,
  });
}

class HarassmentDetectionMetrics {
  final int totalHarassmentDetected;
  final Map<String, int> severityDistribution;
  final int targetedHarassment;
  final List<String> harassmentPatterns;
  final Map<String, dynamic> victimSupport;
  final double escalationRate;

  const HarassmentDetectionMetrics({
    required this.totalHarassmentDetected,
    required this.severityDistribution,
    required this.targetedHarassment,
    required this.harassmentPatterns,
    required this.victimSupport,
    required this.escalationRate,
  });
}

class BotDetectionMetrics {
  final int suspiciousBotAccounts;
  final int confirmedBots;
  final Map<String, dynamic> botActivityPatterns;
  final int automatedContentDetected;
  final List<String> botNetworkDetection;
  final double botAccuracy;

  const BotDetectionMetrics({
    required this.suspiciousBotAccounts,
    required this.confirmedBots,
    required this.botActivityPatterns,
    required this.automatedContentDetected,
    required this.botNetworkDetection,
    required this.botAccuracy,
  });
}

class ReportingMetrics {
  final int totalReports;
  final Map<String, int> reportTypes;
  final Map<ReportStatus, int> reportStatus;
  final Duration averageProcessingTime;
  final double falseReportRate;
  final double actionableReportRate;
  final Map<String, dynamic> reporterEngagement;

  const ReportingMetrics({
    required this.totalReports,
    required this.reportTypes,
    required this.reportStatus,
    required this.averageProcessingTime,
    required this.falseReportRate,
    required this.actionableReportRate,
    required this.reporterEngagement,
  });
}

class ModerationMetrics {
  final int totalModerationActions;
  final Map<String, int> actionTypes;
  final double autoModerationRate;
  final double manualReviewRate;
  final double appealRate;
  final double moderationEffectiveness;

  const ModerationMetrics({
    required this.totalModerationActions,
    required this.actionTypes,
    required this.autoModerationRate,
    required this.manualReviewRate,
    required this.appealRate,
    required this.moderationEffectiveness,
  });
}

class ModerationAction {
  final String id;
  final String type;
  final String userId;
  final DateTime timestamp;
  final bool automated;

  const ModerationAction({
    required this.id,
    required this.type,
    required this.userId,
    required this.timestamp,
    required this.automated,
  });
}

class AbuseTrendAnalysis {
  static AbuseTrendAnalysis empty() => const AbuseTrendAnalysis();
  const AbuseTrendAnalysis();
}
