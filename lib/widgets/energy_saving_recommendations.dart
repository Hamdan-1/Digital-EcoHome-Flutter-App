import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/recommendation_service.dart';
import '../models/sustainability_score.dart';

class EnergySavingRecommendations extends StatefulWidget {
  const EnergySavingRecommendations({Key? key}) : super(key: key);

  @override
  State<EnergySavingRecommendations> createState() =>
      _EnergySavingRecommendationsState();
}

class _EnergySavingRecommendationsState
    extends State<EnergySavingRecommendations> {
  String _selectedCategory = 'All';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize with sample data or fetch real data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recommendationService = Provider.of<RecommendationService>(
        context,
        listen: false,
      );
      setState(() {
        _isLoading = true;
      });

      // Generate recommendations if none exist
      if (recommendationService.recommendations.isEmpty) {
        recommendationService.initWithSamples();
      }

      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendationService = Provider.of<RecommendationService>(context);
    final recommendations = recommendationService.recommendations;
    final savingsPotential = recommendationService.savingsPotential;

    // Get unique categories
    final categories = [
      'All',
      ...recommendations.map((rec) => rec.category).toSet().toList()..sort(),
    ];

    // Filter recommendations by selected category
    final filteredRecommendations =
        _selectedCategory == 'All'
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
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _isLoading = true;
                          });
                          recommendationService.generateRecommendations().then((
                            _,
                          ) {
                            setState(() {
                              _isLoading = false;
                            });
                          });
                        },
              ),
            ],
          ),
        ),

        // Savings potential summary card
        if (savingsPotential != null)
          _buildSavingsPotentialCard(savingsPotential, theme),

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
                  ),
                );
              },
            ),
          ),
        ),

        // Loading indicator
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),

        // Recommendations list
        if (!_isLoading)
          Expanded(
            child:
                filteredRecommendations.isEmpty
                    ? Center(
                      child: Text(
                        'No recommendations available for this category',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredRecommendations.length,
                      itemBuilder: (context, index) {
                        final recommendation = filteredRecommendations[index];
                        return _buildRecommendationCard(
                          recommendation,
                          theme,
                          recommendationService,
                          index,
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
                theme.colorScheme.primary.withOpacity(0.9),
                theme.colorScheme.secondary.withOpacity(0.9),
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
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor.withOpacity(0.1),
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
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              difficultyText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                                    : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: recommendation.isImplemented,
                          onChanged: (value) {
                            service.toggleRecommendationImplementation(
                              service.recommendations.indexOf(recommendation),
                              value,
                            );
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
