import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/recommendation_service.dart';
// import '../models/sustainability_score.dart'; // Unused import
import '../widgets/optimized_loading_indicator.dart';
import '../utils/error_handler.dart'; // Import ErrorHandler

class EnergySavingRecommendations extends StatefulWidget {
  const EnergySavingRecommendations({super.key});

  @override
  State<EnergySavingRecommendations> createState() =>
      _EnergySavingRecommendationsState();
}

class _EnergySavingRecommendationsState
    extends State<EnergySavingRecommendations> {
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _error; // Add state for error message

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to fetch after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _loadInitialRecommendations();
    });
  }

  // Helper to load recommendations initially or on refresh
  Future<void> _loadInitialRecommendations() async {
    // Ensure the widget is still mounted before proceeding
    if (!mounted) return;

    final recommendationService = Provider.of<RecommendationService>(
      context,
      listen: false,
    );

    // Only load initial samples if the list is truly empty and not already loading/error
    // Assuming the service holds the state, we might not need local _isLoading/_error
    // Let's refactor to rely more on the service's potential state management later if needed.
    // For now, keep local state for simplicity of this widget.
    if (recommendationService.recommendations.isEmpty) {
       await _fetchRecommendations(recommendationService, isInitialLoad: true);
    }
  }

  // Fetches recommendations and handles loading/error states
  Future<void> _fetchRecommendations(RecommendationService service, {bool isInitialLoad = false}) async {
     if (!mounted) return; // Check if mounted

     setState(() {
       _isLoading = true;
       _error = null; // Clear previous error on new fetch attempt
     });

     try {
        if (isInitialLoad && service.recommendations.isEmpty) {
           // Using initWithSamples for initial load as per original logic
           // Assuming initWithSamples might become async or throw errors in the future
           // If initWithSamples is sync, wrap it to handle potential errors during init
           await Future.microtask(() => service.initWithSamples());
        } else {
           // Use generateRecommendations for refresh
           service.generateRecommendations();
        }

        // Check mounted state again after async operation
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          // Error is implicitly cleared here by setting it null above
        });

     } catch (e, stackTrace) {
        debugPrint("Error fetching recommendations: $e\n$stackTrace");
        // Check mounted state again after async operation
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = "Failed to load recommendations. Please try again.";
        });
     }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use watch to rebuild when recommendations change in the service
    final recommendationService = Provider.of<RecommendationService>(context);
    final recommendations = recommendationService.recommendations;
    final savingsPotential = recommendationService.savingsPotential;

    // Get unique categories only if data is loaded successfully
    final categories = _isLoading || _error != null || recommendations.isEmpty
        ? ['All'] // Provide default if no data
        : ['All', ...recommendations.map((rec) => rec.category).toSet().toList()..sort()];

    // Filter recommendations by selected category
    // Explicitly type the list when it might be empty initially
    final List<Recommendation> filteredRecommendations = _isLoading || _error != null
        ? [] // No filtering if loading or error
        : _selectedCategory == 'All'
            ? recommendations
            : recommendations
                .where((rec) => rec.category == _selectedCategory)
                .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and refresh button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Smart Energy Recommendations',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh recommendations',
                // Disable button only when loading
                onPressed: _isLoading ? null : () => _fetchRecommendations(recommendationService),
              ),
            ],
          ),
        ),

        // Savings potential summary card (show only if loaded and not error)
        if (!_isLoading && _error == null && savingsPotential != null)
          _buildSavingsPotentialCard(savingsPotential, theme),

        // --- Content Area: Loading / Error / Empty / Data ---
        Expanded(
          child: _buildContentArea(
            context,
            theme,
            recommendationService,
            recommendations,
            filteredRecommendations,
            categories,
          ),
        ),
      ],
    );
  }

  // Helper widget to build the main content area based on state
  Widget _buildContentArea(
      BuildContext context,
      ThemeData theme,
      RecommendationService recommendationService,
      List<Recommendation> recommendations,
      List<Recommendation> filteredRecommendations,
      List<String> categories) {

    // 1. Loading State
    if (_isLoading) {
      // Use SliverFillRemaining if this widget is inside a CustomScrollView,
      // otherwise Center is fine. Assuming it might be used standalone.
      return const Center(child: OptimizedLoadingIndicator(size: 30));
    }

    // 2. Error State
    if (_error != null) {
      return Center(
        child: ErrorHandler.buildErrorDisplay(
          context: context,
          message: _error!,
          onRetry: () => _fetchRecommendations(recommendationService),
        ),
      );
    }

    // 3. Overall Empty State (No recommendations fetched at all)
    if (recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(Icons.lightbulb_outline_rounded, size: 60, color: theme.disabledColor),
               const SizedBox(height: 16),
               Text(
                 'No Recommendations Yet',
                 style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 8),
               Text(
                 "We're analyzing your usage. Check back soon or tap refresh.",
                 style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 24),
               ElevatedButton.icon(
                 onPressed: () => _fetchRecommendations(recommendationService),
                 icon: const Icon(Icons.refresh),
                 label: const Text('Refresh Now'),
               ),
             ],
          ),
        ),
      );
    }

    // 4. Data Available State (Show filters and list)
    return Column(
      children: [
        // Category filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    // Consider using theme colors for chips
                    // selectedColor: theme.colorScheme.primaryContainer,
                    // labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                  ),
                );
              },
            ),
          ),
        ),

        // Recommendations list or Filtered Empty State
        Expanded(
          child: filteredRecommendations.isEmpty
              ? Center( // Filtered empty state
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No recommendations match the selected category.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder( // Actual list
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Adjust padding
                  itemCount: filteredRecommendations.length,
                  itemBuilder: (context, index) {
                    final recommendation = filteredRecommendations[index];
                    // Find the original index in the service's list to pass to the action
                    // Use title and description as a composite key since there's no ID
                    final originalIndex = recommendationService.recommendations.indexWhere(
                      (r) => r.title == recommendation.title && r.description == recommendation.description
                    );
                    return _buildRecommendationCard(
                      recommendation,
                      theme,
                      recommendationService,
                      originalIndex, // Pass original index
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSavingsPotentialCard(
    SavingsPotential savingsPotential,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withAlpha((0.9 * 255).round()),
                theme.colorScheme.secondary.withAlpha((0.9 * 255).round()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Potential Savings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () {
                        _showSavingsInfoDialog(context);
                      },
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSavingsMetric(
                      icon: Icons.bolt,
                      value: savingsPotential.annualSavingsKwh.toStringAsFixed(
                        0,
                      ),
                      unit: 'kWh',
                      label: 'Annual Energy',
                      theme: theme,
                    ),
                    _buildSavingsMetric(
                      icon: Icons.attach_money,
                      value: savingsPotential.annualSavingsCost.toStringAsFixed(
                        0,
                      ),
                      unit: '\$',
                      label: 'Annual Cost',
                      theme: theme,
                    ),
                    _buildSavingsMetric(
                      icon: Icons.eco,
                      value: savingsPotential.co2ReductionKg.toStringAsFixed(0),
                      unit: 'kg',
                      label: 'CO₂ Reduction',
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsMetric({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: unit,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    Recommendation recommendation,
    ThemeData theme,
    RecommendationService service,
    int index,
  ) {
    // Choose color based on category
    Color categoryColor;
    IconData categoryIcon;

    switch (recommendation.category) {
      case 'Lighting':
        categoryColor = Colors.amber;
        categoryIcon = Icons.lightbulb_outline;
        break;
      case 'Heating':
        categoryColor = Colors.orange;
        categoryIcon = Icons.thermostat;
        break;
      case 'Cooling':
        categoryColor = Colors.blue;
        categoryIcon = Icons.ac_unit;
        break;
      case 'Appliances':
        categoryColor = Colors.green;
        categoryIcon = Icons.kitchen;
        break;
      case 'Electronics':
        categoryColor = Colors.purple;
        categoryIcon = Icons.devices;
        break;
      case 'Water':
        categoryColor = Colors.lightBlue;
        categoryIcon = Icons.water_drop;
        break;
      case 'Insulation':
        categoryColor = Colors.brown;
        categoryIcon = Icons.home;
        break;
      default:
        categoryColor = Colors.grey;
        categoryIcon = Icons.eco;
    }

    // Choose icon for difficulty
    IconData difficultyIcon;
    String difficultyText;

    switch (recommendation.difficulty) {
      case 'Easy':
        difficultyIcon = Icons.sentiment_satisfied;
        difficultyText = 'Easy';
        break;
      case 'Medium':
        difficultyIcon = Icons.sentiment_neutral;
        difficultyText = 'Medium';
        break;
      case 'Hard':
        difficultyIcon = Icons.sentiment_dissatisfied;
        difficultyText = 'Advanced';
        break;
      default:
        difficultyIcon = Icons.sentiment_neutral;
        difficultyText = 'Medium';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha((0.1 * 255).round()),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor.withAlpha((0.1 * 255).round()),
          child: Icon(categoryIcon, color: categoryColor),
        ),
        title: Text(
          recommendation.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              difficultyIcon,
              size: 16,
              color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
            ),
            const SizedBox(width: 4),
            Text(
              difficultyText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.bolt, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              '${recommendation.potentialSavings.toStringAsFixed(1)} kWh/month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  recommendation.description,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Savings details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Potential Savings:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recommendation.potentialSavings.toStringAsFixed(1)} kWh/month',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${recommendation.costSavings.toStringAsFixed(2)}/month',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Implementation toggle
                    Row(
                      children: [
                        Text(
                          recommendation.isImplemented
                              ? 'Implemented'
                              : 'Mark as Done',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                recommendation.isImplemented
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()), // Corrected alpha calculation
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: recommendation.isImplemented,
                          onChanged: (value) {
                            // Use the originalIndex passed to the builder
                            if (index != -1) { // Check if index was found
                               service.toggleRecommendationImplementation(
                                 index,
                                 value,
                               );
                            } else {
                               // Log error if index wasn't found (shouldn't happen ideally)
                               // Add semicolon to fix syntax error
                               debugPrint("Error: Could not find original index for recommendation '${recommendation.title}'");
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSavingsInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About Potential Savings'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'These calculations represent potential savings if you implement all the recommended energy-saving measures. The estimates are based on:',
                  ),
                  const SizedBox(height: 16),
                  const Text('• Average energy costs of \$0.15 per kWh'),
                  const Text('• Typical household energy usage patterns'),
                  const Text('• Industry standard savings percentages'),
                  const Text('• CO₂ emissions of 0.44 kg per kWh (US average)'),
                  const SizedBox(height: 16),
                  const Text(
                    'Actual savings may vary based on your specific energy rates, devices, and usage patterns.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }
}
