import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/car_maintenance.dart';
import '../../../../data/repositories/car_maintenance_repository.dart';
import '../../common/esc_dismissible_dialog.dart';
import 'package:intl/intl.dart' as intl;

class CarMaintenanceDialog extends StatefulWidget {
  final String supervisorId;
  final String supervisorName;
  final CarMaintenance? initialCarMaintenance;

  const CarMaintenanceDialog({
    super.key,
    required this.supervisorId,
    required this.supervisorName,
    this.initialCarMaintenance,
  });

  @override
  State<CarMaintenanceDialog> createState() => _CarMaintenanceDialogState();
}

class _CarMaintenanceDialogState extends State<CarMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _maintenanceMeterController = TextEditingController();
  final _tyrePositionController = TextEditingController();
  
  CarMaintenance? _carMaintenance;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _selectedTyrePosition;
  DateTime? _selectedTyreChangeDate;

  final List<String> _tyrePositions = [
    TyrePositions.frontLeft,
    TyrePositions.frontRight,
    TyrePositions.rearLeft,
    TyrePositions.rearRight,
    TyrePositions.spare,
  ];

  @override
  void initState() {
    super.initState();
    _carMaintenance = widget.initialCarMaintenance;
    if (_carMaintenance?.maintenanceMeter != null) {
      _maintenanceMeterController.text = _carMaintenance!.maintenanceMeter.toString();
    }
    _selectedTyreChangeDate = DateTime.now();
  }

  @override
  void dispose() {
    _maintenanceMeterController.dispose();
    _tyrePositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, isDark),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMaintenanceMeterSection(isDark),
                      const SizedBox(height: 24),
                      _buildTyreChangesSection(isDark),
                      const SizedBox(height: 24),
                      _buildCurrentTyreChangesList(isDark),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButtons(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981),
            const Color(0xFF059669),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صيانة السيارة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.supervisorName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceMeterSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.speed_outlined,
              color: const Color(0xFF10B981),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'عداد الصيانة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maintenanceMeterController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'قراءة العداد (كم)',
            hintText: 'أدخل قراءة عداد الصيانة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.speed_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال قراءة العداد';
            }
            if (int.tryParse(value) == null) {
              return 'يرجى إدخال رقم صحيح';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTyreChangesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tire_repair_outlined,
              color: const Color(0xFFF59E0B),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'إضافة تغيير إطار',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTyrePosition,
                decoration: InputDecoration(
                  labelText: 'موقع الإطار',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                items: _tyrePositions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(TyrePositions.getArabicLabel(position)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTyrePosition = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى اختيار موقع الإطار';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectTyreChangeDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'تاريخ التغيير',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _selectedTyreChangeDate != null
                        ? intl.DateFormat('yyyy/MM/dd').format(_selectedTyreChangeDate!)
                        : 'اختر التاريخ',
                    style: TextStyle(
                      color: _selectedTyreChangeDate != null
                          ? (isDark ? Colors.white : const Color(0xFF1E293B))
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addTyreChange,
            icon: const Icon(Icons.add),
            label: const Text('إضافة تغيير الإطار'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTyreChangesList(bool isDark) {
    if (_carMaintenance?.tyreChanges.isEmpty ?? true) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            'لا توجد تغييرات إطارات مسجلة',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تغييرات الإطارات المسجلة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        ..._carMaintenance!.tyreChanges.map((change) => _buildTyreChangeItem(change, isDark)).toList(),
      ],
    );
  }

  Widget _buildTyreChangeItem(TyreChange change, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: const Color(0xFFF59E0B),
            size: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TyrePositions.getArabicLabel(change.tyrePosition),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'تاريخ التغيير: ${intl.DateFormat('yyyy/MM/dd').format(change.changeDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeTyreChange(change),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('إلغاء'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveCarMaintenance,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('حفظ'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTyreChangeDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTyreChangeDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTyreChangeDate = picked;
      });
    }
  }

  void _addTyreChange() {
    if (_selectedTyrePosition == null || _selectedTyreChangeDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار موقع الإطار وتاريخ التغيير'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newTyreChange = TyreChange(
      changeDate: _selectedTyreChangeDate!,
      tyrePosition: _selectedTyrePosition!,
    );

    setState(() {
      if (_carMaintenance == null) {
        _carMaintenance = CarMaintenance(
          id: '',
          supervisorId: widget.supervisorId,
          tyreChanges: [newTyreChange],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        _carMaintenance = _carMaintenance!.copyWith(
          tyreChanges: [..._carMaintenance!.tyreChanges, newTyreChange],
          updatedAt: DateTime.now(),
        );
      }
      _selectedTyrePosition = null;
      _selectedTyreChangeDate = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إضافة تغيير الإطار'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _removeTyreChange(TyreChange change) {
    setState(() {
      _carMaintenance = _carMaintenance!.copyWith(
        tyreChanges: _carMaintenance!.tyreChanges.where((c) => c != change).toList(),
        updatedAt: DateTime.now(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف تغيير الإطار'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
  }

  Future<void> _saveCarMaintenance() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = CarMaintenanceRepository(Supabase.instance.client);
      
      // Update maintenance meter if provided
      if (_maintenanceMeterController.text.isNotEmpty) {
        final maintenanceMeter = int.parse(_maintenanceMeterController.text);
        await repository.updateMaintenanceMeter(
          widget.supervisorId,
          maintenanceMeter,
          DateTime.now(),
        );
      }

      // Save tyre changes if any
      if (_carMaintenance?.tyreChanges.isNotEmpty ?? false) {
        await repository.upsertCarMaintenance(_carMaintenance!);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ بيانات صيانة السيارة بنجاح'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في حفظ البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  static Future<bool?> show(
    BuildContext context,
    String supervisorId,
    String supervisorName, {
    CarMaintenance? carMaintenance,
  }) {
    return context.showEscDismissibleDialog<bool>(
      barrierDismissible: false,
      builder: (dialogContext) => CarMaintenanceDialog(
        supervisorId: supervisorId,
        supervisorName: supervisorName,
        initialCarMaintenance: carMaintenance,
      ),
    );
  }
} 