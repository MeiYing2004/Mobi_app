import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/geocoding/data/models/place_model.dart';

/// Danh sách gợi ý Nominatim dưới thanh tìm kiếm.
class PlaceSuggestionsPanel extends StatelessWidget {
  final bool loading;
  final String? error;
  final String query;
  final List<PlaceSuggestion> suggestions;
  final ValueChanged<PlaceSuggestion> onPick;

  const PlaceSuggestionsPanel({
    super.key,
    required this.loading,
    required this.error,
    required this.query,
    required this.suggestions,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      shadowColor: Colors.black.withValues(alpha: 0.45),
      color: const Color(0xF0142235),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: AppConstants.searchSuggestionsMaxHeight,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (error != null) {
      return _statusText(error!);
    }
    if (loading && suggestions.isEmpty && query.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Đang tìm…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    if (suggestions.isEmpty) {
      return _statusText(
        query.isEmpty
            ? 'Gõ địa điểm — chạm gợi ý hoặc Enter để chỉ đường'
            : 'Không có kết quả',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      itemCount: suggestions.length + 1,
      separatorBuilder: (_, i) {
        if (i == 0) return const SizedBox.shrink();
        return Divider(
          height: 1,
          color: Colors.white.withValues(alpha: 0.07),
        );
      },
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
            child: Text(
              'Kết quả tìm kiếm',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.52),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        final s = suggestions[i - 1];
        return _SuggestionTile(
          suggestion: s,
          onTap: () => onPick(s),
        );
      },
    );
  }

  Widget _statusText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final PlaceSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.place_outlined,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.primaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (suggestion.secondaryText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        suggestion.secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onTap,
                icon: Icon(
                  Icons.navigation_rounded,
                  color: VehicleUi.accentBlue.withValues(alpha: 0.95),
                  size: 20,
                ),
                tooltip: 'Chỉ đường',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
