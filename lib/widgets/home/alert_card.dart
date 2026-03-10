import 'package:flutter/material.dart';
import '../../config/theme.dart';

enum AlertType { emiDue, incomeSoon, lowBalance, overspending }

class AlertCard extends StatelessWidget {
  final AlertType type;
  final String title;
  final String subtitle;
  final int? daysRemaining;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    this.daysRemaining,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [config.color.withOpacity(0.8), config.color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: config.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(config.icon, color: Colors.white, size: 20),
                ),
                if (daysRemaining != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$daysRemaining days',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  _AlertConfig _getConfig() {
    switch (type) {
      case AlertType.emiDue:
        return _AlertConfig(
          color: const Color(0xFFEF4444),
          icon: Icons.payment,
        );
      case AlertType.incomeSoon:
        return _AlertConfig(
          color: const Color(0xFF10B981),
          icon: Icons.account_balance_wallet,
        );
      case AlertType.lowBalance:
        return _AlertConfig(
          color: const Color(0xFFF59E0B),
          icon: Icons.warning_amber_rounded,
        );
      case AlertType.overspending:
        return _AlertConfig(
          color: const Color(0xFFEF4444),
          icon: Icons.trending_up,
        );
    }
  }
}

class _AlertConfig {
  final Color color;
  final IconData icon;

  _AlertConfig({required this.color, required this.icon});
}
