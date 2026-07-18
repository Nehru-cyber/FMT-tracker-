import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/sms_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: theme.isDarkMode,
              onChanged: (_) => theme.toggleTheme(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(theme.themeMode == ThemeMode.system ? 'System' : (theme.isDarkMode ? 'Dark' : 'Light')),
            onTap: () => _showThemeDialog(context, theme),
          ),
          const Divider(),
          // General Section
          _buildSectionHeader(context, 'General'),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text('${settings.currency} (${settings.currencySymbol})'),
            onTap: () => _showCurrencyDialog(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: Switch(
              value: settings.notificationsEnabled,
              onChanged: (v) => settings.setNotifications(v),
            ),
          ),
          const Divider(),
          // Security Section
          _buildSectionHeader(context, 'Security'),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric Lock'),
            subtitle: Text(
              auth.biometricAvailable
                  ? (auth.biometricEnabled ? 'Enabled' : 'Disabled')
                  : 'Not available on this device',
            ),
            trailing: Switch(
              value: auth.biometricEnabled,
              onChanged: auth.biometricAvailable
                  ? (v) async {
                      bool success;
                      if (v) {
                        success = await auth.enableBiometric();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Biometric lock enabled! 🔒'
                                  : 'Failed to enable biometric'),
                            ),
                          );
                        }
                      } else {
                        success = await auth.disableBiometric();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Biometric lock disabled'
                                  : 'Failed to disable biometric'),
                            ),
                          );
                        }
                      }
                    }
                  : null,
            ),
          ),
          const Divider(),
          // Data Section
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.sms),
            title: const Text('Import Bank SMS'),
            subtitle: const Text('Scan inbox for bank messages'),
            onTap: () => SmsService.readInbox(context, auth.user!.id),
          ),
          ListTile(
            leading: const Icon(Icons.phonelink_ring),
            title: const Text('Auto-read Bank SMS'),
            subtitle: const Text('Listen for incoming bank SMS'),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                SmsService.startListening(context, auth.user!.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Started listening for incoming SMS')),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Data'),
            subtitle: const Text('Save your data to cloud'),
            onTap: () => _showComingSoon(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Data'),
            subtitle: const Text('Restore from backup'),
            onTap: () => _showComingSoon(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
            title: const Text('Clear All Data', style: TextStyle(color: AppTheme.errorColor)),
            onTap: () => _showClearDataDialog(context),
          ),
          const Divider(),
          // About Section
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate App'),
            onTap: () => _showComingSoon(context),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share App'),
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: theme.themeMode,
              onChanged: (v) {
                theme.setThemeMode(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: theme.themeMode,
              onChanged: (v) {
                theme.setThemeMode(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: theme.themeMode,
              onChanged: (v) {
                theme.setThemeMode(v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.currencies.entries.map((entry) {
            return RadioListTile<String>(
              title: Text('${entry.value} (${entry.key})'),
              value: entry.key,
              groupValue: settings.currency,
              onChanged: (v) {
                settings.setCurrency(v!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will permanently delete all your data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              // TODO: Implement clear data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!')),
    );
  }
}
