import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/crop_repository.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crop_model.dart';
import '../blockchain/blockchain_service.dart';

class CropCatalogScreen extends StatefulWidget {
  const CropCatalogScreen({super.key});

  @override
  State<CropCatalogScreen> createState() => _CropCatalogScreenState();
}

class _CropCatalogScreenState extends State<CropCatalogScreen> {
  final _cropRepo = CropRepository();
  final _blockchainService = BlockchainLedgerService();
  final _searchController = TextEditingController();

  List<CropModel> _crops = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() => _isLoading = true);
    final query = _searchController.text.trim();
    final list = await _cropRepo.searchCrops(
      query,
      statusFilter: _selectedStatus,
    );
    if (mounted) {
      setState(() {
        _crops = list;
        _isLoading = false;
      });
    }
  }

  void _openCropFormDialog({CropModel? existingCrop}) {
    final nameController = TextEditingController(text: existingCrop?.name ?? '');
    final varietyController = TextEditingController(text: existingCrop?.variety ?? '');
    final landAreaController = TextEditingController(
      text: existingCrop != null ? existingCrop.landAreaHa.toString() : '',
    );
    final yieldController = TextEditingController(
      text: existingCrop != null ? existingCrop.expectedYieldTon.toString() : '',
    );
    final notesController = TextEditingController(text: existingCrop?.notes ?? '');

    String status = existingCrop?.status ?? 'growing';
    DateTime plantingDate = existingCrop?.plantingDate ?? DateTime.now();
    DateTime? harvestDate = existingCrop?.harvestDate;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            existingCrop == null ? 'Register New Crop' : 'Edit Crop Parcel',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Crop Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Crop Commodity Name',
                          hintText: 'e.g., Organic Robusta Coffee',
                          prefixIcon: Icon(Icons.grass),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter crop name' : null,
                      ),
                      const SizedBox(height: 12),

                      // Variety
                      TextFormField(
                        controller: varietyController,
                        decoration: const InputDecoration(
                          labelText: 'Crop Variety / Cultivar',
                          hintText: 'e.g., Catimor Special Red',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter variety' : null,
                      ),
                      const SizedBox(height: 12),

                      // Land Area & Expected Yield
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: landAreaController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Land Area (Ha)',
                                prefixIcon: Icon(Icons.landscape_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter area';
                                final normalized = v.replaceAll(',', '.');
                                final val = double.tryParse(normalized);
                                if (val == null || val.isNaN || val.isInfinite || val <= 0) {
                                  return 'Invalid Ha';
                                }
                                if (val > 10000) return 'Max 10k Ha';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: yieldController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Exp. Yield (Ton)',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter yield';
                                final normalized = v.replaceAll(',', '.');
                                final val = double.tryParse(normalized);
                                if (val == null || val.isNaN || val.isInfinite || val < 0) {
                                  return 'Invalid Ton';
                                }
                                if (val > 500000) return 'Max 500k Ton';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Status
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'Crop Growth Status',
                          prefixIcon: Icon(Icons.energy_savings_leaf_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'growing', child: Text('Growing / Vegetative')),
                          DropdownMenuItem(value: 'harvest_ready', child: Text('Harvest Ready')),
                          DropdownMenuItem(value: 'harvested', child: Text('Harvested / In Storage')),
                          DropdownMenuItem(value: 'diseased', child: Text('Diseased / Attention Needed')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => status = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Planting Date Picker
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryGreen),
                        title: const Text('Planting Date', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        subtitle: Text(
                          DateFormat('dd MMMM yyyy').format(plantingDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: plantingDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setModalState(() => plantingDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Notes
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Soil / Field Notes',
                          hintText: 'e.g. pH 6.2, NPK 15-15-15 applied, drone mapped',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final userId = (await SessionManager.instance.getCurrentUserId()) ?? 1;
                          final landArea = double.parse(landAreaController.text.replaceAll(',', '.'));
                          final expYield = double.parse(yieldController.text.replaceAll(',', '.'));

                          if (existingCrop == null) {
                            final newCrop = CropModel(
                              userId: userId,
                              name: nameController.text.trim(),
                              variety: varietyController.text.trim(),
                              plantingDate: plantingDate,
                              harvestDate: harvestDate,
                              landAreaHa: landArea,
                              expectedYieldTon: expYield,
                              status: status,
                              notes: notesController.text.trim(),
                            );
                            final savedCrop = await _cropRepo.createCrop(newCrop);

                            // Also write blockchain proof
                            await _blockchainService.addRecord(
                              action: 'CROP_PLANTED',
                              itemName: savedCrop.name,
                              batchNumber: 'BATCH-CRP-${savedCrop.id}',
                              producerOrOwner: 'Agro User #$userId',
                              location: 'Parcel #${savedCrop.id} Field Zone',
                              quantity: savedCrop.expectedYieldTon,
                              unit: 'Tons',
                              extraDetails: {
                                'variety': savedCrop.variety,
                                'area_ha': savedCrop.landAreaHa,
                                'planting_date': savedCrop.plantingDate.toIso8601String(),
                              },
                            );
                          } else {
                            final updatedCrop = existingCrop.copyWith(
                              name: nameController.text.trim(),
                              variety: varietyController.text.trim(),
                              plantingDate: plantingDate,
                              landAreaHa: landArea,
                              expectedYieldTon: expYield,
                              status: status,
                              notes: notesController.text.trim(),
                            );
                            await _cropRepo.updateCrop(updatedCrop);

                            // Blockchain update
                            await _blockchainService.addRecord(
                              action: 'CROP_UPDATED',
                              itemName: updatedCrop.name,
                              batchNumber: 'BATCH-CRP-${updatedCrop.id}',
                              producerOrOwner: 'Agro User #$userId',
                              location: 'Parcel #${updatedCrop.id}',
                              quantity: updatedCrop.expectedYieldTon,
                              unit: 'Tons',
                              extraDetails: {'status': updatedCrop.status},
                            );
                          }

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          _loadCrops();

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                existingCrop == null
                                    ? 'Crop registered & minted to Ledger!'
                                    : 'Crop record updated!',
                              ),
                              backgroundColor: AppTheme.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(existingCrop == null ? 'CREATE RECORD' : 'SAVE CHANGES'),
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
  }

  Future<void> _confirmDeleteCrop(CropModel crop) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Crop Record?'),
        content: Text('Are you sure you want to remove "${crop.name}" (${crop.variety}) from local database?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true && crop.id != null) {
      await _cropRepo.deleteCrop(crop.id!);
      _loadCrops();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${crop.name}"'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agro & Farm Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            tooltip: 'Register Crop',
            onPressed: () => _openCropFormDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadCrops(),
                  decoration: InputDecoration(
                    hintText: 'Search crops by name, variety, notes...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadCrops();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Statuses', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Growing', 'growing'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Harvest Ready', 'harvest_ready'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Harvested', 'harvested'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Diseased', 'diseased'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Crop List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _crops.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.spa_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No crop records found',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _openCropFormDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Register First Crop'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _crops.length,
                        itemBuilder: (ctx, index) {
                          final crop = _crops[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.eco_rounded,
                                          color: AppTheme.primaryGreen,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              crop.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Variety: ${crop.variety}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark ? Colors.white70 : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildStatusBadge(crop.status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildDetailItem(
                                          'Area',
                                          '${crop.landAreaHa} Ha',
                                          Icons.landscape_outlined,
                                        ),
                                        _buildDetailItem(
                                          'Exp. Yield',
                                          '${crop.expectedYieldTon} Ton',
                                          Icons.inventory_2_outlined,
                                        ),
                                        _buildDetailItem(
                                          'Planted',
                                          DateFormat('dd/MM/yy').format(crop.plantingDate),
                                          Icons.event_outlined,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (crop.notes != null && crop.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Notes: ${crop.notes}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _openCropFormDialog(existingCrop: crop),
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        label: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _confirmDeleteCrop(crop),
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCropFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Crop'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = value);
          _loadCrops();
        }
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'growing':
        color = Colors.green;
        break;
      case 'harvest_ready':
        color = Colors.orange;
        break;
      case 'harvested':
        color = Colors.blue;
        break;
      case 'diseased':
        color = Colors.red;
        break;
      default:
        color = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
