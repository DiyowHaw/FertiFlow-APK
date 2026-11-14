import 'package:flutter/material.dart';
import 'package:fertiflow/widgets/logo_pill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fertiflow/services/app_state.dart';
import 'package:percent_indicator/percent_indicator.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.instance;

    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final isEn = appState.locale.languageCode == 'en';
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LogoPill(),
                  const SizedBox(height: 24),

                  // Header
                  Text(
                    appState.tr('sensor_control'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FertiFlow IoT Node',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ESP32 Connection Status Badge (FR-08, FR-09, FR-10)
                  _buildDeviceStatusBanner(appState, theme, isEn),
                  const SizedBox(height: 20),

                  _buildProgressCard(
                    name: appState.tr('water_tank'),
                    value: appState.waterTankLevel / 100.0,
                    color: const Color(0xFF0EA5E9),
                    theme: theme,
                    offline: !appState.isDeviceOnline || !appState.hasValidSensorData,
                  ),
                  const SizedBox(height: 28),

                  // Kontrol Sistem
                  _buildControlSystemCard(appState, theme, isEn),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceStatusBanner(AppState appState, ThemeData theme, bool isEn) {
    Color statusBg;
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    switch (appState.connectionStatus) {
      case IotConnectionStatus.notConnected:
        statusBg = Colors.grey.withValues(alpha: 0.1);
        statusColor = const Color(0xFF94A3B8);
        statusIcon = Icons.cloud_off_rounded;
        statusTitle = isEn ? 'ESP32 Not Connected' : 'ESP32 Belum Terhubung';
        statusSubtitle = isEn
            ? 'Waiting for sensor data transmission from node...'
            : 'Menunggu transmisi data sensor dari perangkat ESP32...';
        break;
      case IotConnectionStatus.disconnected:
        statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.portable_wifi_off_rounded;
        statusTitle = isEn ? 'ESP32 Disconnected' : 'Koneksi ESP32 Terputus';
        statusSubtitle = isEn
            ? 'Data is not real-time (Last active: ${appState.lastSensorUpdateFormatted})'
            : 'Data tidak terkini (Terakhir aktif: ${appState.lastSensorUpdateFormatted})';
        break;
      case IotConnectionStatus.connected:
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.1);
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_outline_rounded;
        statusTitle = isEn ? 'ESP32 Connected' : 'ESP32 Terhubung';
        statusSubtitle = isEn
            ? 'Node online • Sensor data streaming real-time'
            : 'Node online • Data sensor tersinkronisasi real-time';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required String name,
    required double value,
    required Color color,
    required ThemeData theme,
    bool offline = false,
  }) {
    final displayValue = offline ? 0.0 : value.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                offline ? '-- %' : '${(displayValue * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: offline
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : theme.colorScheme.onSurface,
                ),
              ),
              Icon(
                Icons.waves_rounded,
                color: offline ? theme.dividerColor : color,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 6.0,
            percent: displayValue,
            padding: EdgeInsets.zero,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.5),
            progressColor: offline ? theme.dividerColor : color,
            barRadius: const Radius.circular(3),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSystemCard(
    AppState appState,
    ThemeData theme,
    bool isEn,
  ) {
    final bool isAuto = appState.fertigationAutoMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appState.tr('system_control'),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? 'Controls sent directly to ESP32 via Firebase'
                        : 'Kontrol dikirim langsung ke ESP32 via Firebase',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Auto Mode Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Auto Watering' : 'Penyiraman Otomatis',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isAuto ? const Color(0xFF10B981) : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEn 
                          ? (isAuto ? 'Manual controls disabled' : 'Manual controls enabled')
                          : (isAuto ? 'Kontrol manual dinonaktifkan' : 'Kontrol manual diizinkan'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isAuto,
                activeTrackColor: const Color(0xFF10B981),
                onChanged: (val) => appState.setFertigationMode(val),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Toggle Pompa Air (CH1)
          _buildControlToggle(
            title: appState.tr('pump_water'),
            subtitle: appState.pumpStatus
                ? (isEn ? 'Running - CH1 ON' : 'Menyala - CH1 ON')
                : (isEn ? 'Off' : 'Mati'),
            value: appState.pumpStatus,
            onChanged: isAuto ? null : (_) => appState.togglePump(),
            theme: theme,
          ),
          const SizedBox(height: 12),
          Divider(height: 28, color: theme.dividerColor.withValues(alpha: 0.4)),

          // Toggle Pestisida A (CH2 + CH4)
          _buildControlToggle(
            title: 'Pestisida A',
            subtitle: appState.pesticideAStatus
                ? (isEn ? 'Running - CH2 + CH4 ON' : 'Menyala - CH2 + CH4 ON')
                : (isEn ? 'Off' : 'Mati'),
            value: appState.pesticideAStatus,
            onChanged: isAuto ? null : (_) => appState.togglePesticideA(),
            theme: theme,
          ),
          Divider(height: 28, color: theme.dividerColor.withValues(alpha: 0.4)),

          // Toggle Pestisida B (CH3 + CH4)
          _buildControlToggle(
            title: 'Pestisida B',
            subtitle: appState.pesticideBStatus
                ? (isEn ? 'Running - CH3 + CH4 ON' : 'Menyala - CH3 + CH4 ON')
                : (isEn ? 'Off' : 'Mati'),
            value: appState.pesticideBStatus,
            onChanged: isAuto ? null : (_) => appState.togglePesticideB(),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildControlToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required ThemeData theme,
  }) {
    final bool isDisabled = onChanged == null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: value
                      ? const Color(0xFF10B981)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: const Color(0xFF10B981),
          onChanged: onChanged,
        ),
      ],
    );
  }
}


