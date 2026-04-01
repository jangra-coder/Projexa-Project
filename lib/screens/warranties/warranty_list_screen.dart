import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/warranty_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/warranty_card.dart';
import 'add_warranty_screen.dart';
import 'warranty_detail_screen.dart';

class WarrantyListScreen extends StatefulWidget {
  const WarrantyListScreen({super.key});

  @override
  State<WarrantyListScreen> createState() => _WarrantyListScreenState();
}

class _WarrantyListScreenState extends State<WarrantyListScreen> {
  String _searchQuery = '';
  WarrantyCategory? _selectedCategory;
  WarrantyStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            // Filter warranties
            List<WarrantyModel> filtered = provider.warranties;

            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              filtered = filtered.where((w) {
                return w.productName.toLowerCase().contains(query) ||
                    (w.brand?.toLowerCase().contains(query) ?? false) ||
                    w.category.label.toLowerCase().contains(query);
              }).toList();
            }

            if (_selectedCategory != null) {
              filtered =
                  filtered.where((w) => w.category == _selectedCategory).toList();
            }

            if (_selectedStatus != null) {
              filtered =
                  filtered.where((w) => w.status == _selectedStatus).toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Warranties',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentBlue
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddWarrantyScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkCardBg : AppColors.lightInputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightInputBorder,
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      onChanged: (val) =>
                          setState(() => _searchQuery = val),
                      style: TextStyle(
                        color:
                            isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search warranties...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _selectedStatus == null &&
                              _selectedCategory == null,
                          onTap: () => setState(() {
                            _selectedStatus = null;
                            _selectedCategory = null;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '✅ Active',
                          selected: _selectedStatus == WarrantyStatus.active,
                          onTap: () => setState(() {
                            _selectedStatus = WarrantyStatus.active;
                            _selectedCategory = null;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '⚠️ Expiring',
                          selected:
                              _selectedStatus == WarrantyStatus.expiringSoon,
                          onTap: () => setState(() {
                            _selectedStatus = WarrantyStatus.expiringSoon;
                            _selectedCategory = null;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '❌ Expired',
                          selected: _selectedStatus == WarrantyStatus.expired,
                          onTap: () => setState(() {
                            _selectedStatus = WarrantyStatus.expired;
                            _selectedCategory = null;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        ...WarrantyCategory.values.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: '${cat.emoji} ${cat.label}',
                              selected: _selectedCategory == cat,
                              onTap: () => setState(() {
                                _selectedCategory = cat;
                                _selectedStatus = null;
                              }),
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Results count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${filtered.length} warrant${filtered.length != 1 ? 'ies' : 'y'} found',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Warranty list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 60,
                                color: isDark
                                    ? AppColors.darkSubtext
                                    : AppColors.lightSubtext,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No warranties found',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? AppColors.darkSubtext
                                      : AppColors.lightSubtext,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final warranty = filtered[index];
                            return Dismissible(
                              key: Key(warranty.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerRed,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    backgroundColor: isDark
                                        ? AppColors.darkSurface
                                        : AppColors.lightSurface,
                                    title: const Text('Delete Warranty'),
                                    content: Text(
                                      'Delete "${warranty.productName}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                              color: AppColors.dangerRed),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) {
                                provider.deleteWarranty(warranty.id);
                              },
                              child: WarrantyCard(
                                warranty: warranty,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WarrantyDetailScreen(
                                          warranty: warranty),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.buttonGradient : null,
          color: selected
              ? null
              : (isDark ? AppColors.darkCardBg : AppColors.lightCardBg),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(
                  color:
                      isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  width: 0.5,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ),
      ),
    );
  }
}
