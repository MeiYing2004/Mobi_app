import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';

import '../core/ios_design_tokens.dart';
import '../core/vehicle_ui_tokens.dart';
import '../models/place_model.dart';
import '../services/search_service.dart';

class SearchBarWidget extends StatefulWidget {
  final SearchService searchService;
  final LatLng? biasLocation;
  final ValueChanged<PlaceDetails> onPlaceSelected;

  const SearchBarWidget({
    super.key,
    required this.searchService,
    required this.onPlaceSelected,
    this.biasLocation,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<PlaceSuggestion> _suggestions = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      final q = v.trim();
      if (!mounted) return;
      if (q.isEmpty) {
        setState(() {
          _loading = false;
          _error = null;
          _suggestions = const [];
        });
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
      });

      try {
        final list = await widget.searchService.autocomplete(
          input: q,
          biasLocation: widget.biasLocation,
        );
        if (!mounted) return;
        setState(() {
          _suggestions = list;
          _loading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = '$e';
          _suggestions = const [];
        });
      }
    });
  }

  Future<void> _select(PlaceSuggestion s) async {
    setState(() {
      _loading = true;
      _error = null;
      _suggestions = const [];
    });
    _focusNode.unfocus();

    try {
      final PlaceDetails details;
      if (s.location != null) {
        details = widget.searchService.detailsFromSuggestion(s);
      } else {
        details = await widget.searchService.fetchDetails(placeId: s.placeId);
      }
      widget.searchService.rememberPlace(details);
      if (!mounted) return;
      _controller.text =
          details.name.isNotEmpty ? details.name : s.primaryText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      setState(() => _loading = false);
      widget.onPlaceSelected(details);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  IconData _iconForTypes(List<String> types) {
    if (types.contains('gas_station')) return Icons.local_gas_station_outlined;
    if (types.contains('restaurant') || types.contains('food')) return Icons.restaurant_outlined;
    if (types.contains('lodging')) return Icons.hotel_outlined;
    if (types.contains('route')) return Icons.route_outlined;
    if (types.contains('locality') || types.contains('administrative_area_level_1')) {
      return Icons.location_city_outlined;
    }
    return Icons.place_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isLight = b == Brightness.light;
    final showOverlay = _focusNode.hasFocus &&
        (_loading || _error != null || _suggestions.isNotEmpty);
    final recent = widget.searchService.recentPlaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: VehicleUi.cardFor(b).withValues(alpha: isLight ? 0.9 : 0.92),
                borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
                border: Border.all(color: VehicleUi.glassBorderFor(b)),
                boxShadow: VehicleUi.floatingShadowNearFor(b),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: (isLight ? Colors.black : Colors.white)
                        .withValues(alpha: isLight ? 0.62 : 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        color: isLight ? const Color(0xFF0B1220) : VehicleUi.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                      cursorColor: VehicleUi.accentBlue,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Tìm địa điểm, địa chỉ...',
                        hintStyle: TextStyle(
                          color: (isLight ? Colors.black : Colors.white)
                              .withValues(alpha: isLight ? 0.38 : 0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_controller.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                        _focusNode.requestFocus();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                      splashRadius: 18,
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      tooltip: 'Xóa',
                    )
                  else
                    IconButton(
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                      splashRadius: 18,
                      icon: const Icon(Icons.mic_none_rounded, color: Colors.white70),
                      tooltip: 'Voice',
                    ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.12, end: 0),
        if (showOverlay) ...[
          const SizedBox(height: 10),
          _SuggestionPanel(
            error: _error,
            suggestions: _suggestions,
            recentPlaces: recent,
            iconForTypes: _iconForTypes,
            onTap: _select,
            onRecentTap: (p) {
              _controller.text = p.name;
              widget.onPlaceSelected(p);
              _focusNode.unfocus();
              setState(() => _suggestions = const []);
            },
          ),
        ],
      ],
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  final String? error;
  final List<PlaceSuggestion> suggestions;
  final List<PlaceDetails> recentPlaces;
  final IconData Function(List<String> types) iconForTypes;
  final ValueChanged<PlaceSuggestion> onTap;
  final ValueChanged<PlaceDetails> onRecentTap;

  const _SuggestionPanel({
    required this.error,
    required this.suggestions,
    required this.recentPlaces,
    required this.iconForTypes,
    required this.onTap,
    required this.onRecentTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: IosDesign.titanGray.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: error != null
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        error!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    )
                  : suggestions.isEmpty && recentPlaces.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            'Gõ địa điểm tại Việt Nam…',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            if (recentPlaces.isNotEmpty && suggestions.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                                child: Text(
                                  'Gần đây',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...recentPlaces.take(5).map(
                                    (p) => InkWell(
                                      onTap: () => onRecentTap(p),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          10,
                                          12,
                                          10,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.history_rounded,
                                              color: Colors.white.withValues(alpha: 0.7),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                p.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              if (suggestions.isNotEmpty)
                                Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                            ],
                            ...List.generate(suggestions.length, (i) {
                              final s = suggestions[i];
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (i > 0)
                                    Divider(
                                      height: 1,
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                  InkWell(
                                    onTap: () => onTap(s),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.10),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              iconForTypes(s.types),
                                              color: Colors.white.withValues(alpha: 0.9),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.primaryText,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (s.secondaryText.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    s.secondaryText,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.65),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.06, end: 0);
  }
}

