import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/request_model.dart';

class RequestCard extends StatelessWidget {
  final BuildRequestModel request;
  final VoidCallback? onTap;

  const RequestCard({super.key, required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: type + status
            Row(
              children: [
                _TypeBadge(type: request.requestType),
                const Spacer(),
                _StatusChip(status: request.status, label: request.statusLabel),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              request.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Description preview
            Text(
              request.description,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Footer: hosting + cost
            Row(
              children: [
                Icon(Icons.cloud_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  request.hostingType.toUpperCase(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: request.isFree
                        ? AppTheme.freeColor.withOpacity(0.1)
                        : AppTheme.paidColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.costLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: request.isFree ? AppTheme.freeColor : AppTheme.paidColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    String emoji;
    String label;
    switch (type) {
      case 'website':
        emoji = '🌐';
        label = 'Website';
        break;
      case 'mobile_app':
        emoji = '📱';
        label = 'Mobile App';
        break;
      default:
        emoji = '🌐📱';
        label = 'Both';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$emoji $label', style: const TextStyle(fontSize: 12)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String label;
  const _StatusChip({required this.status, required this.label});

  Color get _color {
    switch (status) {
      case 'completed': return AppTheme.successColor;
      case 'building': return AppTheme.primaryColor;
      case 'cancelled':
      case 'rejected': return AppTheme.errorColor;
      case 'queued': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}
