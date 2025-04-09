import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/sustainability_score.dart';
import '../models/gamification.dart'; // Import gamification models
import '../theme.dart';
import '../widgets/score_gauge.dart';
import '../widgets/factor_list_item.dart';
import '../widgets/improvement_tip_card.dart';
import '../widgets/neighborhood_ranking_chart.dart';
import '../widgets/challenge_card.dart'; // Import new widgets
import '../widgets/achievement_badge.dart';
import '../widgets/streak_display.dart';
import '../widgets/optimized_loading_indicator.dart';
import '../utils/error_handler.dart';

class SustainabilityScorePage extends StatefulWidget {
  const SustainabilityScorePage({super.key});

  @override
  State<SustainabilityScorePage> createState() =>
      _SustainabilityScorePageState();
}

class _SustainabilityScorePageState extends State<SustainabilityScorePage> {
  late SustainabilityScore _sustainabilityScore;
  bool _isLoading = true;
  String? _error; // Add state for error message
  late AppState _appState; // Store AppState for easy access

  @override
  void initState() {
    super.initState();
    // Get AppState instance once
    _appState = Provider.of<AppState>(context, listen: false);
    _loadSustainabilityScore();
    // Notify AppState that the score page was viewed for achievements
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appState.userViewedScorePage();
    });
  }

  Future<void> _loadSustainabilityScore() async {
    if (!mounted) return; // Check if mounted

    setState(() {
      _isLoading = true;
      _error = null; // Clear previous error on refresh/load
    });

    try {
      // Simulate network delay or actual async data fetching
      await Future.delayed(const Duration(milliseconds: 800));

      // Ensure AppState data is ready (if it were async, we'd check its status here)
      // For now, assume AppState methods provide data directly or handle their own errors

      // Use the stored _appState instance for calculations
      _sustainabilityScore = SustainabilityScore.calculate(
        averageDailyEnergyKwh: _appState.calculateAverageDailyUsage(),
        activeDevicesCount: _appState.getActiveDevicesCount(),
        hasSolarPanels: _appState.hasSolarPanels(),
        hasSmartThermostat: _appState.hasSmartThermostat(),
        usesLedLighting: _appState.usesLedLighting(),
        peakHourUsagePercent: _appState.calculatePeakHourUsagePercent(),
        recentDailyUsage: _appState.getRecentDailyUsage(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          // Error is already null from the start of the try block
        });
      }
    } catch (e, stackTrace) {
       debugPrint("Error loading sustainability score: $e\n$stackTrace");
       if (mounted) {
         setState(() {
           _isLoading = false;
           _error = "Could not calculate sustainability score. Please try again.";
         });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AppState changes for gamification updates
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: _buildBody(appState), // Use a helper to handle states
    );
  }

  Widget _buildBody(AppState appState) {
    if (_isLoading) {
      return const Center(child: OptimizedLoadingIndicator());
    }

    if (_error != null) {
      return Center(
        child: ErrorHandler.buildErrorDisplay(
          context: context,
          message: _error!,
          onRetry: _loadSustainabilityScore, // Allow retry
        ),
      );
    }

    // If loaded successfully and no error
    return _buildContent(appState.gamificationState);
  }

  Widget _buildContent(GamificationState gamificationState) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadSustainabilityScore,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Overview (Enhanced with Gamification)
              _buildScoreOverview(gamificationState), // Pass state

              const SizedBox(height: 24),

              // --- Gamification Section ---
              _buildGamificationSection(gamificationState),
              const SizedBox(height: 24),
              // --- End Gamification Section ---

              // Contributing Factors
              Semantics(header: true, child: _buildFactorsSectionHeader()),
              _buildFactorsList(),

              const SizedBox(height: 24),

              // Neighborhood Ranking
              Semantics(header: true, child: _buildNeighborhoodSectionHeader()),
              _buildNeighborhoodDetails(),

              const SizedBox(height: 24),

              // Improvement Tips
              Semantics(
                header: true,
                child: _buildImprovementTipsSectionHeader(),
              ),
              _buildImprovementTipsList(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Updated Score Overview to include points/level/streak
  Widget _buildScoreOverview(GamificationState gamificationState) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Semantics(
              header: true,
              child: Text(
                'Your Home Sustainability Score',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
           ),
           const SizedBox(height: 16), // Reduced space
           // KeyedSubtree removed as sustainabilityScoreGaugeKey is undefined
           ScoreGauge(
             score: _sustainabilityScore.score,
             scoreLabel: _sustainabilityScore.getScoreLabel(),
             scoreColor: _sustainabilityScore.getScoreColor(),
           ),
            const SizedBox(height: 16),
            // Gamification Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  Icons.star,
                  '${gamificationState.points} Pts',
                  context,
                ),
                _buildStatItem(
                  Icons.leaderboard,
                  'Level ${gamificationState.calculateLevel()}',
                  context,
                ),
                StreakDisplay(streakDays: gamificationState.streakDays),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: "Score calculation basis",
              child: Text(
                'Based on your energy usage patterns and home configuration',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, // Smaller font
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for stats in overview
  Widget _buildStatItem(IconData icon, String text, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.getTextSecondaryColor(context), size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimaryColor(context),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // New Section for Challenges and Achievements
  Widget _buildGamificationSection(GamificationState gamificationState) {
    final activeChallenges =
        gamificationState.activeChallenges
            .where(
              (c) =>
                  c.status == ChallengeStatus.active &&
                  c.expiryDate.isAfter(DateTime.now()),
            )
            .toList();
    final earnedAchievements = gamificationState.earnedAchievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active Challenges
        if (activeChallenges.isNotEmpty) ...[
          _buildSectionHeader(
            Icons.flag_outlined,
            'Active Challenges',
            context,
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeChallenges.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ChallengeCard(challenge: activeChallenges[index]),
              );
            },
          ),
          const SizedBox(height: 24),
        ], // Achievements
        _buildSectionHeader(
          Icons.emoji_events_outlined,
          'Achievements',
          context,
        ),
        const SizedBox(height: 12),
        SizedBox( // Replaced Container with SizedBox for height constraint
          height: 70, // Fixed height for horizontal scrolling badges
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _appState.allAchievements.length,
            itemBuilder: (context, index) {
              final achievement = _appState.allAchievements[index];
              // Find if this achievement is earned
              final isEarned = earnedAchievements.any(
                (earned) => earned.id == achievement.id,
              );
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: AchievementBadge(
                  achievement: achievement.copyWith(earned: isEarned),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper for section headers
  Widget _buildSectionHeader(
    IconData icon,
    String title,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.getPrimaryColor(context)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
      ],
    );
  }

  // --- Existing Sections (Factors, Neighborhood, Tips) ---
  // Use the helper for headers
  Widget _buildFactorsSectionHeader() {
    return _buildSectionHeader(
      Icons.architecture,
      'Contributing Factors',
      context,
    );
  }

  Widget _buildNeighborhoodSectionHeader() {
    return _buildSectionHeader(
      Icons.location_city,
      'Neighborhood Comparison',
      context,
    );
  }

  Widget _buildImprovementTipsSectionHeader() {
    return _buildSectionHeader(
      Icons.lightbulb_outline,
      'Ways to Improve',
      context,
    );
  }

  // ... (_buildFactorsList, _buildNeighborhoodDetails, _buildImprovementTipsList, _showTipDetails remain largely the same) ...
  // Ensure _buildFactorsList uses Padding as FactorListItem is now a Card
  Widget _buildFactorsList() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children:
            _sustainabilityScore.factors.map((factor) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 8.0,
                ), // Add space between factor cards
                child: FactorListItem(factor: factor),
              );
            }).toList(),
      ),
    );
  }

  // Ensure Neighborhood details uses the constrained height for the chart
  Widget _buildNeighborhoodDetails() {
    final ranking = _sustainabilityScore.neighborhoodRanking;
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Semantics(
                label:
                    "Your home ranks ${ranking.ranking} in your neighborhood.",
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                    children: [
                      const TextSpan(text: 'Your home ranks '),
                      TextSpan(
                        text: ranking.ranking,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getPrimaryColor(context),
                        ),
                      ),
                      const TextSpan(text: ' in your neighborhood'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Explicitly constrain chart height
              SizedBox(
                height: 150, // Keep the height constraint
                child: NeighborhoodRankingChart(
                  userScore: _sustainabilityScore.score,
                  neighborhoodScores: ranking.neighborhoodScores,
                  averageScore: ranking.averageScore,
                ),
              ),
              const SizedBox(height: 12),
              Container(/* ... existing percentile container ... */),
            ],
          ),
        ),
      ),
    );
  }

  // Ensure tips list uses the updated ImprovementTipCard with onTap
  Widget _buildImprovementTipsList() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children:
            _sustainabilityScore.improvementTips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ImprovementTipCard(
                  tip: tip,
                  onTap: () => _showTipDetails(context, tip), // onTap remains
                ),
              );
            }).toList(),
      ),
    );
  }

  // _showTipDetails remains the same as previous step
  void _showTipDetails(BuildContext context, SustainabilityTip tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to take more height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5, // Start at half screen height
          minChildSize: 0.3, // Minimum height
          maxChildSize: 0.8, // Maximum height
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                // Use ListView for scrollable content
                controller: scrollController,
                children: [
                  // Handle for dragging
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor, // Use theme color
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Tip Title and Icon
                  Row(
                    children: [
                      Icon(tip.icon, color: tip.getImpactColor(), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Impact Level
                  Text(
                    tip.impact,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tip.getImpactColor(),
                      fontSize: 14,
                    ),
                  ),
                  const Divider(height: 24),
                  // Detailed Description
                  Text(
                    tip.detailedDescription,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.getTextSecondaryColor(context),
                      height: 1.4, // Improve readability
                    ),
                  ),
                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            );
          },
        );
      },
    );
  }
}
