import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/profile/data/profile_repository.dart';
import 'package:memora_mobile/src/features/profile/domain/profile_settings.dart';

const profileFields = (
  displayName: 'Amani Perera',
  locale: 'en-LK',
  timezone: 'Asia/Colombo',
);
const accessibilityFields = (
  reducedMotion: false,
  soundEnabled: true,
  hapticsEnabled: true,
  timerVisible: false,
  highContrast: false,
);
const NotificationSettings notificationFields = (
  enabled: false,
  mission: true,
  reward: true,
  streak: true,
  quiet: (start: '22:00:00', end: '07:00:00'),
  preferred: null,
  timezone: 'Asia/Colombo',
  preview: PreviewDetail.minimal,
  dailyLimit: 1,
);
const ConfirmedSettings confirmedSettings = (
  profile: (fields: profileFields, version: 1),
  preferences: (
    fields: (
      notifications: notificationFields,
      accessibility: accessibilityFields,
    ),
    version: 1,
  ),
);

AppSessionState signedIn({
  String account = 'test-account',
  String owner = 'test-owner',
}) => AppSessionState.active(
  session: AuthSession(accessToken: 'synthetic-access', userId: account),
  bootstrapData: BootstrapData(
    accountStatus: AccountStatusDomain.active,
    profileSummary: ProfileSummaryDomain(
      userId: owner,
      displayName: profileFields.displayName,
    ),
    consentStatus: const ConsentStatusDomain(requiresReview: false),
    subjects: const [
      SubjectSummaryDomain(
        id: 'physics',
        code: 'PHYS',
        name: 'A/L Physics',
        curriculumEditionCode: 'test',
        curriculumVersionId: 'test-curriculum',
      ),
    ],
    capabilities: const CapabilityFlagsDomain(),
    serverTime: DateTime.utc(2026, 11, 1),
  ),
);

class FakeProfileRepository implements ProfileRepository {
  ConfirmedSettings data = confirmedSettings;
  ProfileFailure? readFailure;
  ProfileFailure? saveFailure;
  Future<ConfirmedSettings>? pendingRead;
  Future<void>? pendingSave;
  final keys = <String>[];
  var reads = 0;

  @override
  Future<ConfirmedSettings> load(ProfileAccess access) async {
    reads++;
    if (readFailure != null) throw readFailure!;
    return pendingRead ?? data;
  }

  @override
  Future<Profile> saveProfile(
    ProfileAccess access,
    Profile before,
    ProfileFields draft,
    String key,
  ) async {
    keys.add(key);
    await pendingSave;
    if (saveFailure != null) throw saveFailure!;
    final saved = (fields: draft, version: before.version + 1);
    data = (profile: saved, preferences: data.preferences);
    return saved;
  }

  @override
  Future<Preferences> savePreferences(
    ProfileAccess access,
    Preferences before,
    PreferenceFields draft,
    String key,
  ) async {
    keys.add(key);
    await pendingSave;
    if (saveFailure != null) throw saveFailure!;
    final saved = (fields: draft, version: before.version + 1);
    data = (profile: data.profile, preferences: saved);
    return saved;
  }
}
