import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/geocoding/data/models/place_model.dart';
import 'package:fuel_tracker_app/features/geocoding/data/services/nominatim_geocoding_service.dart';
import 'package:fuel_tracker_app/features/geocoding/presentation/widgets/place_suggestions_panel.dart';

/// Thanh tìm kiếm OSM — gợi ý Nominatim, chỉ đường qua [onNavigate].
class MapSearchBar extends StatefulWidget {
  final NominatimGeocodingService searchService;
  final LatLng? biasLocation;
  /// Luồng duy nhất: Enter + chạm gợi ý → chỉ đường ngay.
  final Future<void> Function(PlaceDetails destination) onNavigate;
  final ValueChanged<bool>? onPanelOpenChanged;
  final bool enabled;

  const MapSearchBar({
    super.key,
    required this.searchService,
    required this.onNavigate,
    this.biasLocation,
    this.onPanelOpenChanged,
    this.enabled = true,
  });

  @override
  State<MapSearchBar> createState() => MapSearchBarState();
}

class MapSearchBarState extends State<MapSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _anchorKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<PlaceSuggestion> _suggestions = const [];
  String _pendingQuery = '';
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
    _notifyPanel();
    _syncOverlay();
  }

  bool get _panelVisible {
    if (!widget.enabled) return false;
    if (!_focusNode.hasFocus && !_committing) return false;
    final q = _controller.text.trim();
    return q.isNotEmpty || _loading || _error != null || _suggestions.isNotEmpty;
  }

  void _notifyPanel() => widget.onPanelOpenChanged?.call(_panelVisible);

  void _syncOverlay() {
    if (!_panelVisible) {
      _removeOverlay();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_panelVisible) {
        _removeOverlay();
        return;
      }
      _showOrUpdateOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOrUpdateOverlay() {
    final anchor = _anchorKey.currentContext;
    if (anchor == null) return;
    final overlay = Overlay.maybeOf(anchor);
    if (overlay == null) return;

    Widget overlayContent(BuildContext ctx) {
      final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return const SizedBox.shrink();
      final topLeft = box.localToGlobal(Offset.zero);
      final top = topLeft.dy + box.size.height + 8;

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _focusNode.unfocus();
                _removeOverlay();
                if (mounted) setState(() {});
                _notifyPanel();
              },
            ),
          ),
          Positioned(
            left: topLeft.dx,
            top: top,
            width: box.size.width,
            child: PlaceSuggestionsPanel(
              loading: _loading,
              error: _error,
              query: _controller.text.trim(),
              suggestions: _suggestions,
              onPick: (s) => unawaited(_pickSuggestion(s)),
            ),
          ),
        ],
      );
    }

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: overlayContent);
      overlay.insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _onChanged(String value) {
    if (_committing) return;
    _debounce?.cancel();
    final q = value.trim();
    _pendingQuery = q;

    if (q.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _suggestions = const [];
      });
      _notifyPanel();
      _syncOverlay();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    _notifyPanel();
    _syncOverlay();

    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () async {
        final query = _pendingQuery;
        if (!mounted || query.isEmpty) return;
        try {
          final list = await widget.searchService.search(
            query: query,
            bias: widget.biasLocation,
          );
          if (!mounted || _pendingQuery != query) return;
          setState(() {
            _suggestions = list;
            _loading = false;
          });
        } catch (e) {
          if (!mounted || _pendingQuery != query) return;
          setState(() {
            _loading = false;
            _error = '$e';
            _suggestions = const [];
          });
        }
        _notifyPanel();
        _syncOverlay();
      },
    );
  }

  Future<void> _submitEnter() async {
    _debounce?.cancel();
    final q = _controller.text.trim();
    if (q.isEmpty || _committing) return;

    if (_suggestions.isNotEmpty) {
      await _pickSuggestion(_suggestions.first);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    _syncOverlay();

    try {
      final place = await widget.searchService.resolveFromQuery(
        query: q,
        bias: widget.biasLocation,
      );
      if (!mounted) return;
      await _commitNavigation(place, displayText: q);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
      _syncOverlay();
    }
  }

  Future<void> _pickSuggestion(PlaceSuggestion s) async {
    if (_committing) return;
    _committing = true;
    _removeOverlay();
    if (mounted) setState(() {});

    try {
      final place = await widget.searchService.resolveForNavigation(s);
      if (!mounted) return;
      await _commitNavigation(place, displayText: s.primaryText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không chỉ đường: $e')),
      );
    } finally {
      _committing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _commitNavigation(
    PlaceDetails place, {
    String? displayText,
  }) async {
    _removeOverlay();
    _focusNode.unfocus();
    setState(() {
      _loading = false;
      _suggestions = const [];
      _error = null;
    });
    _notifyPanel();

    if (displayText != null && displayText.isNotEmpty) {
      _controller.text = displayText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    await widget.onNavigate(place);
  }

  @override
  void didUpdateWidget(covariant MapSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isLight = b == Brightness.light;
    final inputColor = isLight ? const Color(0xFF0B1220) : Colors.white;
    final hintColor = (isLight ? Colors.black : Colors.white)
        .withValues(alpha: isLight ? 0.42 : 0.55);

    return Material(
      key: _anchorKey,
      color: Colors.transparent,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: VehicleUi.cardFor(b).withValues(alpha: isLight ? 0.94 : 0.96),
          borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
          border: Border.all(color: VehicleUi.glassBorderFor(b)),
          boxShadow: VehicleUi.floatingShadowNearFor(b),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: inputColor.withValues(alpha: 0.72),
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                onChanged: _onChanged,
                onSubmitted: (_) => unawaited(_submitEnter()),
                textInputAction: TextInputAction.search,
                autocorrect: false,
                enableSuggestions: false,
                cursorColor: VehicleUi.accentBlue,
                style: TextStyle(
                  color: inputColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Tìm địa điểm, địa chỉ...',
                  hintStyle: TextStyle(color: hintColor, fontSize: 16),
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
                icon: Icon(
                  Icons.close_rounded,
                  color: inputColor.withValues(alpha: 0.72),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
