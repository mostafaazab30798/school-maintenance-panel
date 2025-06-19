import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/admin_service.dart';
import '../../../data/models/admin.dart';

class UserInfoWidget extends StatelessWidget {
  final bool isCompact;
  
  const UserInfoWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Admin?>(
      future: AdminService(Supabase.instance.client).getCurrentAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B).withOpacity(0.5)
                  : const Color(0xFFF1F5F9).withOpacity(0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final admin = snapshot.data!;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        const Color(0xFF1E293B).withOpacity(0.8),
                        const Color(0xFF0F172A).withOpacity(0.6),
                      ]
                    : [
                        const Color(0xFFF8FAFC).withOpacity(0.9),
                        const Color(0xFFE2E8F0).withOpacity(0.8),
                      ],
              ),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF334155).withOpacity(0.5)
                    : const Color(0xFFCBD5E1).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: admin.role == 'super_admin'
                          ? [
                              const Color(0xFF8B5CF6),
                              const Color(0xFF7C3AED),
                            ]
                          : [
                              const Color(0xFF3B82F6),
                              const Color(0xFF1D4ED8),
                            ],
                    ),
                  ),
                  child: Icon(
                    admin.role == 'super_admin'
                        ? Icons.admin_panel_settings_rounded
                        : Icons.person_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isCompact) ...[
                  Text(
                    admin.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF374151),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: admin.role == 'super_admin'
                        ? const Color(0xFF8B5CF6).withOpacity(0.2)
                        : const Color(0xFF3B82F6).withOpacity(0.2),
                  ),
                                      child: Text(
                      isCompact
                          ? admin.name
                          : (admin.role == 'super_admin' ? 'مدير عام' : 'مسؤول'),
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 10,
                        fontWeight: FontWeight.w700,
                        color: admin.role == 'super_admin'
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF3B82F6),
                        letterSpacing: 0.2,
                      ),
                    ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
} 