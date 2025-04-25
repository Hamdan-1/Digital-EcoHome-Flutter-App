import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../theme.dart'; // Import AppTheme
import '../models/app_state.dart'; // Import AppState

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final appState = Provider.of<AppState>(context); // Access AppState
    final aboutSettings = appState.appSettings.aboutSettings; // Access AboutSettings


    return Scaffold(
      appBar: AppBar(
        title: const Text('About Digital EcoHome'),
        backgroundColor: AppTheme.getPrimaryColor(context), // Use theme color
        foregroundColor: colorScheme.onPrimary, // Use theme color
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildInfoCard(
            context: context,
            title: 'App Information',
            children: [
              _buildInfoRow(
                context,
                Icons.info_outline,
                'App Name',
                _packageInfo.appName,
              ),
              _buildInfoRow(
                context,
                Icons.numbers,
                'Version',
                aboutSettings.appVersion, // Use version from AboutSettings
              ),
              _buildInfoRow(
                context,
                Icons.build_circle_outlined,
                'Build',
                aboutSettings.buildNumber, // Use build number from AboutSettings
              ),
              const SizedBox(height: 12.0),
              Text(
                'Digital EcoHome is a smart home application focused on energy efficiency and sustainability, developed as part of the AUS Senior Design Project.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildInfoCard(
            context: context,
            title: 'Meet the Team: The Digital Trailblazers',
            children: [
              _buildTeamMember(
                context,
                name: 'Ahmad Suleiman',
                role: 'Advisor',
                icon: Icons.school_outlined, // Example icon
              ),
              _buildTeamMember(
                context,
                name: 'Hamdan Moohialdin',
                role: 'Lead App Coder and Developer',
                icon: Icons.code, // Example icon
              ),
              _buildTeamMember(
                context,
                name: 'Mubarak Bushra',
                role: 'Developer and Hardware Coder',
                icon: Icons.memory, // Example icon
              ),
              _buildTeamMember(
                context,
                name: 'Mustafa Amer',
                role: 'Developer and Hardware Coder',
                icon: Icons.memory, // Example icon
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildInfoCard(
            context: context,
            title: 'Acknowledgements',
            children: [
              Text(
                'Special thanks to the American University of Sharjah (AUS) and the College of Engineering.', // Placeholder
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
              // Placeholder: Add more acknowledgements if needed
            ],
          ),
          const SizedBox(height: 16.0),
          _buildInfoCard(
            context: context,
            title: 'Licenses',
            children: [
              Text(
                'This application uses open-source software. Tap here to view licenses.', // Placeholder
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
              // Placeholder: Implement navigation to a licenses page or show licenses directly
            ],
            onTap: () {
              // Placeholder: Implement license viewing logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('License viewing not implemented yet.')),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper widget for consistent card structure
  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell( // Make card tappable if onTap is provided
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.getPrimaryColor(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Divider(height: 20, thickness: 1),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for consistent info rows (e.g., version)
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.getTextSecondaryColor(context), size: 20),
          const SizedBox(width: 16.0),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.getTextSecondaryColor(context),
                ),
          ),
        ],
      ),
    );
  }

  // Helper widget for team member list items
  Widget _buildTeamMember(
    BuildContext context, {
    required String name,
    required String role,
    required IconData icon,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.getPrimaryColor(context).withAlpha((0.1 * 255).round()),
        foregroundColor: AppTheme.getPrimaryColor(context),
        child: Icon(icon, size: 20),
      ),
      title: Text(
        name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextPrimaryColor(context),
            ),
      ),
      subtitle: Text(
        role,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getTextSecondaryColor(context),
            ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
    );
  }
}