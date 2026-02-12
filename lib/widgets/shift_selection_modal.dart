import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ShiftSelectionModal extends StatefulWidget {
  final List<Map<String, String>> shifts;
  final String? initialShift;
  final String actionType;

  const ShiftSelectionModal({
    Key? key,
    required this.shifts,
    this.initialShift,
    this.actionType = 'Check In',
  }) : super(key: key);

  @override
  State<ShiftSelectionModal> createState() => _ShiftSelectionModalState();
}

class _ShiftSelectionModalState extends State<ShiftSelectionModal> {
  late String? _tempSelectedShift;

  @override
  void initState() {
    super.initState();
    _tempSelectedShift = widget.initialShift;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.schedule,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Pilih Jadwal Shift',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Shift List
          Expanded(
            child: ListView.builder(
              itemCount: widget.shifts.length,
              itemBuilder: (context, index) {
                final shift = widget.shifts[index];
                final shiftKey = '${shift['time']} - ${shift['name']}';
                final isSelected = _tempSelectedShift == shiftKey;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected 
                        ? AppColors.primary 
                        : AppColors.primary.withOpacity(0.3),
                      width: isSelected ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.white,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _tempSelectedShift = isSelected ? null : shiftKey;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                    ? AppColors.primary
                                    : AppColors.primary.withOpacity(0.5),
                                  width: 2,
                                ),
                                color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              ),
                              child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shift['name']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    shift['time']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _tempSelectedShift != null
                    ? () => Navigator.pop(context, _tempSelectedShift)
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tempSelectedShift != null
                      ? AppColors.primary
                      : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Pilih',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
