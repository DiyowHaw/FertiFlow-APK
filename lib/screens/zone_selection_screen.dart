import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fertiflow/services/app_state.dart';
import 'package:fertiflow/services/zone_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fertiflow/screens/analysis_screen.dart';

class ZoneSelectionScreen extends StatefulWidget {
  const ZoneSelectionScreen({super.key});

  @override
  State<ZoneSelectionScreen> createState() => _ZoneSelectionScreenState();
}

class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  final ZoneService _zoneService = ZoneService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pilih Zona Tanaman',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _zoneService,
        builder: (context, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _zoneService.zones.length,
            itemBuilder: (context, index) {
              final zone = _zoneService.zones[index];
              return _buildZoneCard(zone, theme, appState);
            },
          );
        },
      ),
    );
  }

  Widget _buildZoneCard(PlantZone zone, ThemeData theme, AppState appState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.eco_rounded, color: Color(0xFF10B981)),
        ),
        title: Text(
          zone.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Jenis: ${zone.plantType}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              'Jumlah: ${zone.plantCount} Tanaman',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          _zoneService.setActiveZone(zone.id);
          _processImage(context, ImageSource.camera);
        },
      ),
    );
  }

  Future<void> _processImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );

    if (photo != null && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(imagePath: photo.path),
        ),
      );
    }
  }
}
