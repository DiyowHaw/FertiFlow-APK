import 'package:flutter/material.dart';
import 'package:fertiflow/widgets/logo_pill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fertiflow/services/app_state.dart';
import 'package:fertiflow/screens/activity_history_screen.dart';
import 'package:fertiflow/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final appState = AppState.instance;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: Colors.transparent,
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
                // 1. Logo Pill & Settings + Notification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const LogoPill(),
                    Row(
                      children: [
                        _buildSettingsButton(context, theme),
                        const SizedBox(width: 10),
                        _buildNotificationBell(context, appState, theme),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 2. Header Section
                Text(
                  appState.tr('system_status'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      appState.connectionStatus == IotConnectionStatus.notConnected
                          ? Icons.cloud_off_rounded
                          : appState.connectionStatus == IotConnectionStatus.disconnected
                              ? Icons.portable_wifi_off_rounded
                              : (appState.soilMoisture < 50
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded),
                      color: appState.connectionStatus == IotConnectionStatus.notConnected
                          ? const Color(0xFF94A3B8)
                          : appState.connectionStatus == IotConnectionStatus.disconnected
                              ? const Color(0xFFF59E0B)
                              : (appState.soilMoisture < 50
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981)),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.connectionStatus == IotConnectionStatus.notConnected
                                ? (appState.locale.languageCode == 'id'
                                      ? 'Belum Terhubung'
                                      : 'Not Connected')
                                : appState.connectionStatus == IotConnectionStatus.disconnected
                                    ? (appState.locale.languageCode == 'id'
                                          ? 'Data Tidak Terkini'
                                          : 'Outdated Data')
                                    : (appState.soilMoisture < 50
                                          ? (appState.locale.languageCode == 'id'
                                                ? 'Perlu Penanganan'
                                                : 'Needs Attention')
                                          : appState.tr('status_normal')),
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (appState.connectionStatus == IotConnectionStatus.disconnected &&
                              appState.lastSensorTimestamp != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              appState.locale.languageCode == 'id'
                                  ? 'Terakhir diperbarui: ${appState.lastSensorUpdateFormatted}'
                                  : 'Last updated: ${appState.lastSensorUpdateFormatted}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFF59E0B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2.1 Low Moisture Warning Banner
                if ((appState.isDeviceOnline &&
                    appState.soilMoisture < 50)) ...[
                  _buildDrySoilAlertCard(appState, theme),
                  const SizedBox(height: 24),
                ],

                // 3. â˜… Deteksi Hama Terbaru â€” HIGHLIGHT UTAMA (paling atas)
                _buildLatestDetectionCard(appState, theme),
                const SizedBox(height: 24),

                // 4. Status Cards Row (Healthy vs Attention)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        title: appState.tr('healthy_plants'),
                        value: '${appState.healthyPlantCount}',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF10B981),
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        title: appState.tr('needs_attention'),
                        value: '${appState.needsAttentionCount}',
                        icon: Icons.error_outline_rounded,
                        color: const Color(0xFFEF4444),
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Sensor Cards (Kelembapan Tanah, Suhu, Kelembapan Udara)
                _buildSensorCardsSection(appState, theme),
                const SizedBox(height: 24),

                // 6. Grafik Data Sensor (7 hari terakhir)
                _buildSensorChartCard(appState, theme, isDark),
                const SizedBox(height: 24),

                // 7. Fertigation Activity Chart
                _buildChartCard(appState, theme, isDark),
                const SizedBox(height: 24),

                // 8. Status Penyemprotan Card
                _buildLatestSprayCard(context, appState, theme),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}

// â”€â”€ Settings Icon Button (di sebelah notif) â”€â”€
Widget _buildSettingsButton(BuildContext context, ThemeData theme) {
  return GestureDetector(
    onTap: () {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    },
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Icon(
        Icons.settings_rounded,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        size: 22,
      ),
    ),
  );
}

Widget _buildNotificationBell(
  BuildContext context,
  AppState appState,
  ThemeData theme,
) {
  // Hitung notifikasi dinamis
  int dynamicCount = 0;
  if (appState.isDeviceOnline && appState.soilMoisture < 50) dynamicCount++;
  if (appState.waterTankLevel < 20) dynamicCount++;

  return GestureDetector(
    onTap: () {
      _showDynamicNotificationSheet(context, appState, theme);
    },
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            size: 22,
          ),
          if (dynamicCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$dynamicCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

void _showDynamicNotificationSheet(BuildContext context, AppState appState, ThemeData theme) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Notifikasi Sistem',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (!appState.isDeviceOnline || (appState.soilMoisture >= 50 && appState.waterTankLevel >= 20))
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('Tidak ada notifikasi sistem saat ini.', style: GoogleFonts.inter(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              )
            else ...[
              if (appState.isDeviceOnline && appState.soilMoisture < 50)
                ListTile(
                  leading: const Icon(Icons.water_drop, color: Color(0xFFEF4444)),
                  title: Text('Kelembapan Tanah Rendah', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  subtitle: Text('Tanah kering (${appState.soilMoisture}%), segera lakukan penyiraman.'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      appState.togglePump();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Siram', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              if (appState.isDeviceOnline && appState.waterTankLevel < 20)
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                  title: Text('Air Tandon Kritis', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  subtitle: Text('Level air hanya ${appState.waterTankLevel}%. Segera isi ulang.'),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

Widget _buildStatusCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required ThemeData theme,
}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
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

// â”€â”€ Sensor Cards Section (dari IoT screen) â”€â”€
Widget _buildSensorCardsSection(AppState appState, ThemeData theme) {
  final bool isOffline = !appState.isDeviceOnline || !appState.hasValidSensorData;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            appState.tr('sensor_control'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10B981),
              letterSpacing: 1.5,
            ),
          ),
          if (isOffline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                appState.connectionStatus == IotConnectionStatus.notConnected
                    ? (appState.locale.languageCode == 'id' ? 'Menunggu ESP32' : 'Waiting ESP32')
                    : (appState.locale.languageCode == 'id' ? 'Data Terputus' : 'Offline'),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildSensorMiniCard(
              name: appState.tr('soil_moisture'),
              value: appState.soilMoistureDisplay,
              icon: Icons.grass_rounded,
              color: const Color(0xFF10B981),
              theme: theme,
              isOffline: isOffline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSensorMiniCard(
              name: appState.tr('air_temp'),
              value: appState.airTemperatureDisplay,
              icon: Icons.thermostat_rounded,
              color: const Color(0xFFF97316),
              theme: theme,
              isOffline: isOffline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSensorMiniCard(
              name: appState.tr('air_humidity'),
              value: appState.airHumidityDisplay,
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF0EA5E9),
              theme: theme,
              isOffline: isOffline,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildSensorMiniCard({
  required String name,
  required String value,
  required IconData icon,
  required Color color,
  required ThemeData theme,
  bool isOffline = false,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isOffline
                ? theme.dividerColor.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isOffline
                ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                : color,
            size: 16,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isOffline
                ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          maxLines: 2,
        ),
      ],
    ),
  );
}

// ─── Grafik Data Sensor (Menyesuaikan Mesin ESP32) ───
Widget _buildSensorChartCard(AppState appState, ThemeData theme, bool isDark) {
  final bool isMachineActive = appState.isDeviceOnline && appState.hasValidSensorData;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appState.locale.languageCode == 'id'
                        ? 'Grafik Data Sensor'
                        : 'Sensor Data Chart',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appState.locale.languageCode == 'id'
                        ? 'Suhu & Kelembapan 7 Hari'
                        : '7-Day Temperature & Humidity',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isMachineActive ? const Color(0xFF10B981) : Colors.grey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isMachineActive ? const Color(0xFF10B981) : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isMachineActive ? 'ONLINE' : 'OFFLINE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isMachineActive ? const Color(0xFF10B981) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Jika mesin offline / data sensor belum ada, tampilkan Kosongan (Empty State)
        if (!isMachineActive) ...[
          const SizedBox(height: 16),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sensors_off_rounded,
                  size: 32,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  appState.locale.languageCode == 'id'
                      ? 'Data Sensor Belum Tersedia'
                      : 'Sensor Data Unavailable',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    appState.locale.languageCode == 'id'
                        ? 'Grafik suhu & kelembapan akan muncul saat ESP32 terhubung dan mengirim data'
                        : 'Temperature & humidity charts will appear once ESP32 is online and sending data',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'])
                Text(
                  day,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
        ] else ...[
          // Mesin aktif: Tampilkan data aktual
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildChartLegend(
                '${appState.tr('soil_moisture')} (${appState.soilMoisture.toStringAsFixed(0)}%)',
                const Color(0xFF10B981),
              ),
              _buildChartLegend(
                '${appState.tr('air_temp')} (${appState.airTemperature.toStringAsFixed(1)}°C)',
                const Color(0xFFF97316),
              ),
              _buildChartLegend(
                '${appState.tr('air_humidity')} (${appState.airHumidity.toStringAsFixed(0)}%)',
                const Color(0xFF0EA5E9),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 150,
            width: double.infinity,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SensorMultiLineChartPainter(
                  soilData: appState.weeklySoilMoisture,
                  tempData: appState.weeklyTemperature,
                  humidData: appState.weeklyHumidity,
                  gridColor: theme.dividerColor,
                  isDark: isDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 7; i++)
                Text(
                  ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][i],
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: i == (DateTime.now().weekday - 1)
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: i == (DateTime.now().weekday - 1)
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildChartLegend(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

// ─── Fertigation Activity Chart (Menyesuaikan Mesin ESP32) ───
Widget _buildChartCard(AppState appState, ThemeData theme, bool isDark) {
  final bool isMachineActive = appState.isDeviceOnline;
  final double totalWater = appState.totalWeeklyWater;
  final bool hasWaterData = isMachineActive && totalWater > 0.0;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appState.locale.languageCode == 'id'
                        ? 'Aktivitas Air Dikeluarkan'
                        : 'Fertigation Water Usage',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appState.locale.languageCode == 'id'
                        ? 'Volume Air 7 Hari Terakhir'
                        : 'Last 7 Days Dispensed Volume',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (hasWaterData ? const Color(0xFF10B981) : Colors.grey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                hasWaterData
                    ? '${totalWater.toStringAsFixed(1)} L Total'
                    : (isMachineActive ? '0.0 L Total' : '-- L Total'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasWaterData ? const Color(0xFF10B981) : Colors.grey,
                ),
              ),
            ),
          ],
        ),

        // Jika mesin belum idup / belum ada air yang dikeluarkan, tampilkan Kosongan
        if (!hasWaterData) ...[
          const SizedBox(height: 20),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 32,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  appState.locale.languageCode == 'id'
                      ? 'Belum Ada Air Yang Dikeluarkan'
                      : 'No Water Dispensed Yet',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    !isMachineActive
                        ? (appState.locale.languageCode == 'id'
                            ? 'Menunggu mesin ESP32 aktif & tersambung ke aplikasi'
                            : 'Awaiting active ESP32 connection')
                        : (appState.locale.languageCode == 'id'
                            ? 'Debit air akan otomatis tercatat saat pompa/irigasi menyala'
                            : 'Water volume will be tracked when irrigation runs'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'])
                Expanded(
                  child: _buildLegendItem(
                    day,
                    isMachineActive ? '0.0L' : '--',
                    theme,
                  ),
                ),
            ],
          ),
        ] else ...[
          // Ada data air dikeluarkan dari mesin!
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _FertigationChartPainter(
                  data: appState.weeklyWaterUsage,
                  themeColor: const Color(0xFF10B981),
                  gridColor: theme.dividerColor,
                  isDark: isDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: _buildLegendItem(
                    ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][i],
                    '${appState.weeklyWaterUsage[i].toStringAsFixed(1)}L',
                    theme,
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildLegendItem(String day, String value, ThemeData theme) {
  return Column(
    children: [
      Text(
        day,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    ],
  );
}

Widget _buildLatestDetectionCard(AppState appState, ThemeData theme) {
  final history = appState.detectionHistory;
  final item = history.isNotEmpty ? history.first : null;

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
            Expanded(
              child: Text(
                appState.tr('latest_detection'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => appState.setNavIndex(2),
              child: Text(
                appState.tr('see_all'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (item != null) ...[
          Builder(
            builder: (context) {
              final String rawLabel = item['label'] ?? 'Unknown';
              final String rawSeverity = item['severity'] ?? 'Sedang';
              final isEn = appState.locale.languageCode == 'en';

              String displayLabel = rawLabel;
              if (isEn) {
                if (rawLabel.contains('Kutu Daun')) displayLabel = 'Aphids';
                if (rawLabel.contains('Thrips')) displayLabel = 'Thrips';
                if (rawLabel.contains('Tungau')) displayLabel = 'Mites';
              }

              String displaySeverity = rawSeverity;
              if (isEn) {
                if (rawSeverity == 'Ringan') displaySeverity = 'Mild';
                if (rawSeverity == 'Sedang') displaySeverity = 'Moderate';
                if (rawSeverity == 'Berat') displaySeverity = 'Severe';
              }

              Color severityColor = const Color(0xFFF59E0B);
              if (rawSeverity == 'Berat') {
                severityColor = const Color(0xFFEF4444);
              }
              if (rawSeverity == 'Ringan') {
                severityColor = const Color(0xFF10B981);
              }

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bug_report_rounded,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayLabel,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['plantId']} - ${(item['confidence'] * 100).toStringAsFixed(0)}% Match',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displaySeverity,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ] else
          Text(
            appState.locale.languageCode == 'id'
                ? 'Tidak ada riwayat deteksi.'
                : 'No detection history found.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
      ],
    ),
  );
}

Widget _buildLatestSprayCard(
  BuildContext context,
  AppState appState,
  ThemeData theme,
) {
  final status = appState.latestSprayStatus;
  Color statusColor = const Color(0xFF94A3B8);
  if (status == 'Sedang Berjalan') statusColor = const Color(0xFFF59E0B);
  if (status == 'Selesai') statusColor = const Color(0xFF10B981);

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
            Expanded(
              child: Text(
                appState.tr('latest_spray'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF10B981),
            side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_rounded, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  appState.tr('activity_history'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildDrySoilAlertCard(AppState appState, ThemeData theme) {
  final isEn = appState.locale.languageCode == 'en';
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn
                    ? 'Low Soil Moisture Alert!'
                    : 'Peringatan Kelembapan Tanah Rendah!',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          isEn
              ? 'Soil moisture is currently at ${appState.soilMoisture.toStringAsFixed(0)}%, which is below the optimal threshold (50%). Plant roots may suffer water stress.'
              : 'Kelembapan tanah saat ini ${appState.soilMoisture.toStringAsFixed(0)}%, terlalu kering (di bawah 50%). Segera lakukan penyiraman agar tanaman tidak layu.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isEn
                    ? 'Action: Activate Water Pump.'
                    : 'Tindakan: Nyalakan Pompa Air.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                appState.setNavIndex(1); // Switch to IoT screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                isEn ? 'Go to IoT' : 'Ke Tab IoT',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// â”€â”€ Multi-Line Sensor Chart Painter â”€â”€
class _SensorMultiLineChartPainter extends CustomPainter {
  final List<double> soilData;
  final List<double> tempData;
  final List<double> humidData;
  final Color gridColor;
  final bool isDark;

  _SensorMultiLineChartPainter({
    required this.soilData,
    required this.tempData,
    required this.humidData,
    required this.gridColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    const int gridRows = 4;
    final double rowHeight = size.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      final double y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Normalize all data to 0-100 range for display
    // Soil moisture: already 0-100%
    // Temp: normalize 20-40Â°C â†’ 0-100, clamp to ensure in-range
    // Humidity: already 0-100%

    List<double> normSoil = soilData.map((v) => v.clamp(0.0, 100.0)).toList();
    List<double> normTemp = tempData
        .map((v) => v > 0.0 ? ((v - 15) / 25 * 100).clamp(5.0, 100.0) : 0.0)
        .toList();
    List<double> normHumid = humidData.map((v) => v.clamp(0.0, 100.0)).toList();

    _drawLine(canvas, size, normSoil, const Color(0xFF10B981), 3.0, drawFill: true);
    _drawLine(canvas, size, normTemp, const Color(0xFFF97316), 2.5);
    _drawLine(canvas, size, normHumid, const Color(0xFF0EA5E9), 2.5);
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double> data,
    Color color,
    double strokeWidth, {
    bool drawFill = false,
  }) {
    if (data.isEmpty || data.every((v) => v <= 0.0)) return;

    const double maxVal = 100.0;
    const double minVal = 0.0;
    const double valRange = maxVal - minVal;
    final double stepX = size.width / (data.length - 1);

    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double normY = (data[i] - minVal) / (valRange == 0 ? 1 : valRange);
      final double y =
          size.height - (normY * size.height * 0.8) - (size.height * 0.1);
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      if (drawFill) {
        // Gradient fill
        final fillPath = Path()..moveTo(0, size.height);
        for (var p in points) {
          fillPath.lineTo(p.dx, p.dy);
        }
        fillPath.lineTo(size.width, size.height);
        fillPath.close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;
        canvas.drawPath(fillPath, fillPaint);
      }

      // Line connecting all 7 days exactly like FertigationChartPainter
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // Data points circles for all 7 days
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;

    for (var p in points) {
      canvas.drawCircle(p, 5.0, pointPaint);
      canvas.drawCircle(p, 2.5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SensorMultiLineChartPainter oldDelegate) {
    return oldDelegate.soilData != soilData ||
        oldDelegate.tempData != tempData ||
        oldDelegate.humidData != humidData ||
        oldDelegate.isDark != isDark;
  }
}

// â”€â”€ Fertigation Chart Painter (existing) â”€â”€
class _FertigationChartPainter extends CustomPainter {
  final List<double> data;
  final Color themeColor;
  final Color gridColor;
  final bool isDark;

  _FertigationChartPainter({
    required this.data,
    required this.themeColor,
    required this.gridColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    const int gridRows = 3;
    final double rowHeight = size.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      final double y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (data.isEmpty || data.every((v) => v <= 0.0)) return;

    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    const double minVal = 0.0;
    final double valRange = maxVal - minVal;

    final double stepX = size.width / (data.length - 1);

    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double normY = (data[i] - minVal) / (valRange == 0 ? 1 : valRange);
      final double y =
          size.height - (normY * size.height * 0.8) - (size.height * 0.1);
      points.add(Offset(x, y));
    }

    // Path for gradient fill
    final fillPath = Path()..moveTo(0, size.height);
    for (var p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          themeColor.withValues(alpha: 0.3),
          themeColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Path for line
    final linePaint = Paint()
      ..color = themeColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw data points circles
    final pointPaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;

    for (var p in points) {
      canvas.drawCircle(p, 6.0, pointPaint);
      canvas.drawCircle(p, 3.5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FertigationChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.isDark != isDark;
  }
}
