import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../discovery/domain/destination_filter.dart';
import '../../discovery/domain/destination_summary.dart';
import '../../discovery/presentation/discovery_providers.dart';

class AdminCuratorScreen extends ConsumerStatefulWidget {
  const AdminCuratorScreen({super.key});

  @override
  ConsumerState<AdminCuratorScreen> createState() => _AdminCuratorScreenState();
}

class _AdminCuratorScreenState extends ConsumerState<AdminCuratorScreen> {
  String _query = '';
  bool _loading = true;
  String? _error;
  List<DestinationSummary> _items = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(destinationRepositoryProvider)
          .fetchDestinations(DestinationFilter(query: _query, limit: 100));
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _toggleStatus(DestinationSummary item) async {
    final nextStatus = item.verificationStatus == 'verified'
        ? 'needs_field_verification'
        : 'verified';
    try {
      await ref
          .read(dioProvider)
          .patch<Map<String, dynamic>>(
            ApiEndpoints.adminDestinationStatus(item.id),
            data: {'verification_status': nextStatus},
          );
      ref.invalidate(exploreFeedProvider);
      ref.invalidate(filteredDestinationsProvider);
      await _load();
    } on DioException catch (e) {
      _showMsg(ApiException.fromDio(e).message, isError: true);
    } catch (e) {
      _showMsg(e.toString(), isError: true);
    }
  }

  Future<void> _openEditSheet(DestinationSummary item) async {
    final feeCtrl = TextEditingController(
      text: (item.pricing.entranceFeeAdult ?? 0).toStringAsFixed(0),
    );
    final imgCtrl = TextEditingController(text: item.imageUrl ?? '');
    var tempClosed = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.ivorySand,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: feeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Adult entrance fee (PHP)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: imgCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Photo image URL',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mark all days temporarily closed'),
                        value: tempClosed,
                        onChanged: (v) => setModalState(() => tempClosed = v),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () async {
                          final fee = double.tryParse(feeCtrl.text.trim()) ?? 0;
                          final imageText = imgCtrl.text.trim();
                          final payload = <String, dynamic>{
                            'image_url': imageText.isEmpty ? null : imageText,
                            'pricing': {
                              'entrance_fee_adult': fee,
                              'is_free': fee <= 0,
                            },
                            if (tempClosed)
                              'operatingHours': [
                                for (var d = 0; d <= 6; d += 1)
                                  {
                                    'day_of_week': d,
                                    'opening_time': '08:00',
                                    'closing_time': '17:00',
                                    'is_24_hours': false,
                                    'temporarily_closed': true,
                                  },
                              ],
                          };
                          try {
                            await ref
                                .read(dioProvider)
                                .put<Map<String, dynamic>>(
                                  ApiEndpoints.adminDestination(item.id),
                                  data: payload,
                                );
                            ref.invalidate(exploreFeedProvider);
                            ref.invalidate(filteredDestinationsProvider);
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            _showMsg('Updated ${item.name}.');
                            await _load();
                          } on DioException catch (e) {
                            _showMsg(
                              ApiException.fromDio(e).message,
                              isError: true,
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: AppColors.ivorySand,
                        ),
                        child: const Text('Save changes'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    feeCtrl.dispose();
    imgCtrl.dispose();
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppColors.danger : AppColors.deepForest,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        backgroundColor: AppColors.warmSand,
        title: const Text('Curator Console'),
        actions: [
          IconButton(
            tooltip: 'Refresh destinations',
            onPressed: _load,
            icon: const Icon(CupertinoIcons.refresh, size: 18),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (v) {
                _query = v.trim();
                _load();
              },
              decoration: InputDecoration(
                hintText: 'Search destinations to verify or edit...',
                prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                filled: true,
                fillColor: AppColors.ivorySand,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.hairline,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final item = _items[idx];
                      final isVerified = item.verificationStatus == 'verified';
                      return AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.lguName} · ${item.priceLabel}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.mutedForest,
                                      fontFeatures: AppTypography.tabularFigures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ActionChip(
                              label: Text(isVerified ? 'Verified' : 'Pending'),
                              backgroundColor: isVerified
                                  ? AppColors.skyBlueWash
                                  : AppColors.terracottaWash,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _toggleStatus(item);
                              },
                            ),
                            IconButton(
                              tooltip: 'Edit pricing & photo',
                              onPressed: () => _openEditSheet(item),
                              icon: const Icon(CupertinoIcons.pencil, size: 18),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
