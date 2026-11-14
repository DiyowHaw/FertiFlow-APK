import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fertiflow/services/app_state.dart';

class LogoPill extends StatelessWidget {
  const LogoPill({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final isOnline = AppState.instance.isDeviceOnline;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 16,
                    width: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                  children: const [
                    TextSpan(text: 'Ferti', style: TextStyle(color: Color(0xFF10B981))),
                    TextSpan(text: 'Flow', style: TextStyle(color: Color(0xFF0EA5E9))),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline 
                      ? const Color(0xFF10B981) // Hijau jika terkoneksi
                      : const Color(0xFFEF4444), // Merah jika terputus
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
