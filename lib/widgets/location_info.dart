import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/location_service.dart';

class LocationInfo extends StatefulWidget {
  const LocationInfo({Key? key}) : super(key: key);

  @override
  State<LocationInfo> createState() => _LocationInfoState();
}

class _LocationInfoState extends State<LocationInfo> {
  final LocationService _locationService = LocationService();

  Future<void> _refreshLocation() async {
    await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _locationService,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DEBUG: Lokasi Saat Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (_locationService.isLoading)
                const SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_locationService.errorMessage != null)
                Text(
                  _locationService.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                )
              else if (_locationService.currentPosition != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_locationService.isMockLocation)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lokasi tidak akurat (${_locationService.currentPosition!.accuracy.toStringAsFixed(2)}m)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildLocationRow(
                      'Latitude',
                      _locationService.currentPosition!.latitude.toStringAsFixed(6),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationRow(
                      'Longitude',
                      _locationService.currentPosition!.longitude.toStringAsFixed(6),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationRow(
                      'Akurasi',
                      '${_locationService.currentPosition!.accuracy.toStringAsFixed(2)} m',
                    ),
                  ],
                )
              else
                const Text(
                  'Belum ada lokasi',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _locationService.isLoading ? null : _refreshLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Lokasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
