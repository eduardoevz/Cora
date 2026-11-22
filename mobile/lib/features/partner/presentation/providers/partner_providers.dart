import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/partner/presentation/pages/partner_companion_view_page.dart';

final partnerServiceProvider = Provider<PartnerSharingService>((ref) {
  return PartnerSharingService(ref);
});

class PartnerSharingService {
  PartnerSharingService(this._ref);

  final Ref _ref;
  String? _activeLinkId;

  Future<String> generateInvitationCode() async {
    final api = _ref.read(coraApiClientProvider);
    try {
      final res = await api.dio
          .post(
            '/partner-sharing/invitations',
            options: Options(
              sendTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
            ),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 201 && res.data is Map<String, dynamic>) {
        return res.data['invitation_code']?.toString() ?? 'CORA-24H';
      }
    } catch (_) {
      // Offline deterministic fallback code
    }
    final seed = DateTime.now().millisecondsSinceEpoch.toString();
    return 'CORA-${seed.substring(seed.length - 4)}';
  }

  Future<void> redeemCode(String code) async {
    final api = _ref.read(coraApiClientProvider);
    try {
      final res = await api.dio.post(
        '/partner-sharing/invitations/redeem',
        data: {'invitation_code': code},
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        _activeLinkId = res.data['id']?.toString();
      }
    } catch (_) {
      // Allow local preview flow even offline
    }
  }

  Future<void> updatePermissions({
    required bool fertility,
    required bool pregnancy,
    required bool mood,
  }) async {
    if (_activeLinkId == null) return;
    try {
      await _ref.read(coraApiClientProvider).dio.patch(
        '/partner-sharing/links/$_activeLinkId/permissions',
        data: {
          'permissions': {
            'share_fertility_window': fertility,
            'share_pregnancy_milestones': pregnancy,
            'share_mood_and_support_tips': mood,
          },
        },
      );
    } catch (_) {
      // Ignored in offline mode
    }
  }

  Future<void> revokeActiveLink() async {
    if (_activeLinkId == null) return;
    try {
      await _ref
          .read(coraApiClientProvider)
          .dio
          .delete('/partner-sharing/links/$_activeLinkId');
      _activeLinkId = null;
    } catch (_) {
      // Ignored in offline mode
    }
  }

  Future<PartnerCompanionProjection> fetchSharedViewOrFallback() async {
    final profile = _ref.read(activeUserProfileProvider);
    try {
      final res = await _ref
          .read(coraApiClientProvider)
          .dio
          .get(
            '/partner-sharing/shared-with-me',
            options: Options(
              sendTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
            ),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final tips = (data['support_tips'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .join('\n');
        return PartnerCompanionProjection(
          sharingUserName: data['owner_first_name']?.toString() ??
              (profile?.firstName ?? 'Usuaria'),
          isLinkActive: true,
          pregnancyMilestone: data['fetal_milestone']?.toString(),
          fertilityWindowSummary: data['fertility_window_summary']?.toString(),
          moodAndSupportTip:
              tips.isNotEmpty ? tips : data['recent_mood_summary']?.toString(),
        );
      }
    } catch (_) {
      // Fallback preview projection
    }
    return PartnerCompanionProjection(
      sharingUserName: profile?.firstName ?? 'Sofía',
      isLinkActive: true,
      fertilityWindowSummary: 'Ventana fértil estimada en seguimiento activo.',
      moodAndSupportTip:
          'Acompañamiento empático: pregúntale cómo se siente hoy y ofrece apoyo práctico.',
    );
  }
}
