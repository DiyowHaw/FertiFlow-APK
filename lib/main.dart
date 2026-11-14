import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';

import 'package:fertiflow/services/app_state.dart';
import 'package:fertiflow/services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/treatment_screen.dart';

import 'screens/schedule_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/smart_consultation_screen.dart';
import 'package:image_picker/image_picker.dart';


import 'package:fertiflow/services/yolo_tflite_service.dart';
import 'package:fertiflow/services/zone_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi database dan load semua data tersimpan
  await DatabaseService.instance.database;
  await AppState.instance.loadFromDatabase();

  // Preload model TFLite ke memori agar scan pertama tidak lag
  YoloTfliteService.instance.loadModel().ignore();

  // Mulai subscribe sensor & relay dari Firebase (ESP32)
  AppState.instance.startIotSubscription();

  runApp(const FertiFlowApp());
}

class FertiFlowApp extends StatefulWidget {
  const FertiFlowApp({super.key});

  @override
  State<FertiFlowApp> createState() => _FertiFlowAppState();
}

class _FertiFlowAppState extends State<FertiFlowApp> {
  Locale? _lastLocale;
  ThemeMode? _lastThemeMode;

  @override
  void initState() {
    super.initState();
    _lastLocale = AppState.instance.locale;
    _lastThemeMode = AppState.instance.themeMode;
    AppState.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      final appState = AppState.instance;
      // Optimasi Performa: Hanya rebuild seluruh MaterialApp jika tema atau bahasa berubah
      if (_lastLocale != appState.locale || _lastThemeMode != appState.themeMode) {
        _lastLocale = appState.locale;
        _lastThemeMode = appState.themeMode;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: AppState.instance.locale,
      title: 'FertiFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
          surface: const Color(0xFFF0FDF4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE2E8F0),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
          surface: const Color(0xFF1E293B),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        dividerColor: const Color(0xFF334155),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: AppState.instance.themeMode,
      home: const SplashScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const MonitoringScreen(),
    const TreatmentScreen(),
    const ScheduleScreen(),
  ];

  void _showImageSourceBottomSheet(BuildContext context, AppState appState, ThemeData theme) {
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
              // Pull bar
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
                appState.locale.languageCode == 'id' ? 'Pilih Konteks & Gambar' : 'Select Context & Image',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                appState.locale.languageCode == 'id'
                    ? 'Pilih asal tanaman untuk membantu AI'
                    : 'Choose plant source to help AI',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              
              // Opsi-opsi (2x2 Grid)
              Row(
                children: [
                  Expanded(
                    child: _buildGridOption(
                      context,
                      theme,
                      title: 'Zona A',
                      subtitle: '(Cabai Rawit)',
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        ZoneService.instance.setActiveZone('z_1');
                        _processImage(context, ImageSource.camera, appState);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGridOption(
                      context,
                      theme,
                      title: 'Zona B',
                      subtitle: '(Cabai Keriting)',
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        ZoneService.instance.setActiveZone('z_2');
                        _processImage(context, ImageSource.camera, appState);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildGridOption(
                      context,
                      theme,
                      title: 'Bebas',
                      subtitle: '(Tanpa Zona)',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(ctx);
                        ZoneService.instance.setActiveZone(null);
                        _processImage(context, ImageSource.camera, appState);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGridOption(
                      context,
                      theme,
                      title: 'Galeri',
                      subtitle: '(Pilih Foto)',
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF0EA5E9),
                      onTap: () {
                        Navigator.pop(ctx);
                        ZoneService.instance.setActiveZone(null);
                        _processImage(context, ImageSource.gallery, appState);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridOption(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(BuildContext context, ImageSource source, AppState appState) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );

    if (photo != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            imagePath: photo.path,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final int currentIndex = AppState.instance.navIndex;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF0F172A),
                              const Color(0xFF1A2332),
                              const Color(0xFF0F172A),
                            ]
                          : [
                              const Color(0xFFFFFFFF),
                              const Color(0xFFE6F9EE),
                              const Color(0xFFFFFFFF),
                            ],
                    ),
                  ),
                ),
              ),
              // Active screen with IndexedStack agar state terjaga dan transisi tab 0ms instan
              IndexedStack(
                index: currentIndex,
                children: _screens,
              ),
            ],
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            height: 64,
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1E293B) 
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, AppState.instance.tr('nav_home'), isDark, theme),
                _buildNavItem(1, Icons.sensors_rounded, AppState.instance.tr('nav_iot'), isDark, theme),
                _buildNavItem(2, Icons.healing_rounded, AppState.instance.tr('nav_treatment'), isDark, theme),
                _buildNavItem(3, Icons.calendar_month_rounded, AppState.instance.tr('nav_schedule'), isDark, theme),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. AI Chat Button (Same style)
              Container(
                margin: const EdgeInsets.only(bottom: 12, right: 8),
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SmartConsultationScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
              // 2. Camera Button
              Container(
                margin: const EdgeInsets.only(bottom: 8, right: 8),
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => _showImageSourceBottomSheet(context, AppState.instance, theme),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark, ThemeData theme) {
    final bool isSelected = AppState.instance.navIndex == index;
    
    final List<Color> tabColors = [
      const Color(0xFF10B981), // Beranda - green
      const Color(0xFF0EA5E9), // IoT - blue
      const Color(0xFFF97316), // Tangani - orange
      const Color(0xFF14B8A6), // Jadwal - teal
    ];
    
    final Color activeColor = tabColors[index];
    
    return GestureDetector(
      onTap: () {
        AppState.instance.setNavIndex(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isSelected ? activeColor : (isDark ? Colors.white54 : theme.colorScheme.onSurface.withValues(alpha: 0.5)), 
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

