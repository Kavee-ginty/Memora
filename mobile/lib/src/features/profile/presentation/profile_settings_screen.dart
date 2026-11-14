import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/button.dart';
import '../../../design_system/components/dialog.dart';
import '../../../design_system/components/skeleton.dart';
import '../../../design_system/components/text_field.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../routing/app_routes.dart';
import '../../auth/application/session_controller.dart';
import '../application/profile_controller.dart';
import '../domain/profile_settings.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen(this.section, {super.key});

  final SettingsSection section;

  String get title => switch (section) {
    SettingsSection.profile => 'Edit profile',
    SettingsSection.notifications => 'Notifications',
    SettingsSection.accessibility => 'Accessibility and mission settings',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final confirmed = state.confirmed;
    final account = ref.watch(
      sessionControllerProvider.select(
        (state) =>
            (state.session?.userId, state.bootstrapData?.profileSummary.userId),
      ),
    );
    void leave() => context.go(AppRoutes.profile);
    final theme = Theme.of(context);
    final linkStyle = MediaQuery.highContrastOf(context)
        ? theme.textButtonTheme.style
        : theme.textButtonTheme.style?.copyWith(
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? null
                  : const Color(0xFF0056A3),
            ),
          );
    return Theme(
      data: theme.copyWith(
        textButtonTheme: TextButtonThemeData(style: linkStyle),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to Profile',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter = constraints.maxWidth < 360 ? 16.0 : 24.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Focus(
                          autofocus: true,
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state.cached)
                          const _Status('Showing the last confirmed settings.'),
                        if (confirmed == null &&
                            state.phase == ProfilePhase.failed &&
                            (state.section == null || state.section == section))
                          _FailureNotice(state, onRetry: controller.retry),
                        if (state.phase == ProfilePhase.conflict &&
                            state.section == section)
                          const _Status(
                            'These settings changed elsewhere. Review the updated values before saving again.',
                          ),
                        if (state.phase == ProfilePhase.saving &&
                            state.section == section)
                          const _Status('Saving settings…'),
                        if (state.phase == ProfilePhase.saved &&
                            state.section == section)
                          const _Status('Settings saved.'),
                        if (state.cacheWriteFailed)
                          const _Status(
                            'Saved online. Settings could not be stored on this device.',
                          ),
                        if (confirmed != null)
                          _SettingsForm(
                            key: ValueKey(account),
                            section: section,
                            confirmed: confirmed,
                            state: state,
                          )
                        else if (state.phase == ProfilePhase.loading)
                          MemoraLoadingTimeoutView(
                            skeleton: const Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                MemoraSkeleton(height: 56),
                                SizedBox(height: 16),
                                MemoraSkeleton(height: 56),
                              ],
                            ),
                            loadingMessage: 'Loading settings…',
                            timeoutMessage:
                                'Settings are taking longer to load.',
                            onLeave: leave,
                          )
                        else
                          TextButton(
                            onPressed: leave,
                            child: const Text('Return to Profile'),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(bottom: MemoraSpacing.space12),
      child: Text(message),
    ),
  );
}

class _FailureNotice extends StatelessWidget {
  const _FailureNotice(this.state, {this.onRetry});
  final ProfileState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Status(
          failure?.code == 'network_error'
              ? 'You may be offline. Check your connection and try again.'
              : failure?.message ?? 'Settings are unavailable.',
        ),
        if (failure?.retryable == true && onRetry != null)
          TextButton(
            onPressed: state.waitingToRetry ? null : onRetry,
            child: Text(
              state.waitingToRetry ? 'Wait before retrying' : 'Retry',
            ),
          ),
      ],
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({
    super.key,
    required this.section,
    required this.confirmed,
    required this.state,
  });

  final SettingsSection section;
  final ConfirmedSettings confirmed;
  final ProfileState state;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _form = GlobalKey<FormState>();
  final _validationFocus = FocusNode();
  final _name = TextEditingController();
  final _locale = TextEditingController();
  final _timezone = TextEditingController();
  late NotificationSettings _notifications;
  late AccessibilitySettings _accessibility;
  late ProfileController _controller;
  bool _invalid = false;
  bool _discard = false;
  bool _dialogOpen = false;
  bool _canRetrySave = false;
  VoidCallback? _restoreConflictDraft;
  int _formRevision = 0;

  SettingsSection get _section => widget.section;
  bool get _saving => widget.state.phase == ProfilePhase.saving;
  bool get _refreshing => widget.state.phase == ProfilePhase.loading;
  bool get _locked => _saving || _refreshing;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(profileControllerProvider.notifier);
    _setConfirmed();
  }

  @override
  void didUpdateWidget(covariant _SettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.confirmed != oldWidget.confirmed) {
      _restoreConflictDraft =
          widget.state.phase == ProfilePhase.conflict &&
              widget.state.section == _section
          ? _retainConflictDraft(oldWidget.confirmed)
          : null;
      _setConfirmed();
    } else if (widget.state.phase == ProfilePhase.failed &&
        widget.state.section == SettingsSection.accessibility &&
        oldWidget.state.phase != ProfilePhase.failed) {
      // The controller retains the failed logical save for Retry. The switches
      // show the confirmed settings while that save is unresolved.
      _accessibility = widget.confirmed.preferences.fields.accessibility;
    }
    if (widget.state.failure?.fields.isNotEmpty == true &&
        widget.state.failure != oldWidget.state.failure &&
        widget.state.section == _section) {
      _focusErrors();
    }
  }

  void _setConfirmed() {
    final fields = widget.confirmed.profile.fields;
    _name.text = fields.displayName;
    _locale.text = fields.locale;
    _notifications = widget.confirmed.preferences.fields.notifications;
    _timezone.text = _section == SettingsSection.profile
        ? fields.timezone
        : _notifications.timezone;
    _accessibility = widget.confirmed.preferences.fields.accessibility;
    _invalid = false;
    _canRetrySave = false;
    _formRevision++;
  }

  VoidCallback _retainConflictDraft(ConfirmedSettings previous) {
    T keep<T>(T draft, T original, T latest) =>
        draft == original ? latest : draft;

    switch (_section) {
      case SettingsSection.profile:
        final draft = _profileDraft;
        final original = previous.profile.fields;
        final latest = widget.confirmed.profile.fields;
        return () {
          _name.text = keep(
            draft.displayName,
            original.displayName,
            latest.displayName,
          );
          _locale.text = keep(draft.locale, original.locale, latest.locale);
          _timezone.text = keep(
            draft.timezone,
            original.timezone,
            latest.timezone,
          );
        };
      case SettingsSection.notifications:
        final draft = _notificationDraft;
        final original = previous.preferences.fields.notifications;
        final latest = widget.confirmed.preferences.fields.notifications;
        return () {
          _notifications = (
            enabled: keep(draft.enabled, original.enabled, latest.enabled),
            mission: keep(draft.mission, original.mission, latest.mission),
            reward: keep(draft.reward, original.reward, latest.reward),
            streak: keep(draft.streak, original.streak, latest.streak),
            quiet: keep(draft.quiet, original.quiet, latest.quiet),
            preferred: keep(
              draft.preferred,
              original.preferred,
              latest.preferred,
            ),
            timezone: keep(draft.timezone, original.timezone, latest.timezone),
            preview: keep(draft.preview, original.preview, latest.preview),
            dailyLimit: keep(
              draft.dailyLimit,
              original.dailyLimit,
              latest.dailyLimit,
            ),
          );
          _timezone.text = _notifications.timezone;
        };
      case SettingsSection.accessibility:
        final draft = _accessibility;
        final original = previous.preferences.fields.accessibility;
        final latest = widget.confirmed.preferences.fields.accessibility;
        return () {
          _accessibility = (
            reducedMotion: keep(
              draft.reducedMotion,
              original.reducedMotion,
              latest.reducedMotion,
            ),
            soundEnabled: keep(
              draft.soundEnabled,
              original.soundEnabled,
              latest.soundEnabled,
            ),
            hapticsEnabled: keep(
              draft.hapticsEnabled,
              original.hapticsEnabled,
              latest.hapticsEnabled,
            ),
            timerVisible: keep(
              draft.timerVisible,
              original.timerVisible,
              latest.timerVisible,
            ),
            highContrast: keep(
              draft.highContrast,
              original.highContrast,
              latest.highContrast,
            ),
          );
          _controller.previewAccessibility(_accessibility);
        };
    }
  }

  ProfileFields get _profileDraft => (
    displayName: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
    locale: _locale.text.trim(),
    timezone: _timezone.text.trim(),
  );

  NotificationSettings get _notificationDraft => (
    enabled: _notifications.enabled,
    mission: _notifications.mission,
    reward: _notifications.reward,
    streak: _notifications.streak,
    quiet: _notifications.quiet,
    preferred: _notifications.preferred,
    timezone: _timezone.text.trim(),
    preview: _notifications.preview,
    dailyLimit: _notifications.dailyLimit,
  );

  bool get _dirty => switch (_section) {
    SettingsSection.profile => _profileDraft != widget.confirmed.profile.fields,
    SettingsSection.notifications =>
      _notificationDraft != widget.confirmed.preferences.fields.notifications,
    SettingsSection.accessibility =>
      _accessibility != widget.confirmed.preferences.fields.accessibility,
  };

  Future<void> _save() async {
    final valid = _form.currentState!.validate();
    setState(() => _invalid = !valid);
    if (!valid) {
      _focusErrors();
      return;
    }
    setState(() => _canRetrySave = true);
    await switch (_section) {
      SettingsSection.profile => _controller.saveProfile(_profileDraft),
      SettingsSection.notifications => _controller.saveNotifications(
        _notificationDraft,
      ),
      SettingsSection.accessibility => _controller.saveAccessibility(
        _accessibility,
      ),
    };
  }

  void _editDraft(VoidCallback update) {
    setState(() {
      update();
      _canRetrySave = false;
    });
  }

  void _textEdited(String _) => _editDraft(() {});

  void _focusErrors() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _validationFocus.requestFocus();
      final summary = _validationFocus.context;
      if (summary != null) Scrollable.ensureVisible(summary);
    });
  }

  Future<void> _confirmDiscard() async {
    if (_dialogOpen || _saving) return;
    _dialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialog) => MemoraDialog(
        title: 'Discard your changes?',
        message: 'Your last saved settings will stay in place.',
        primaryActionLabel: 'Keep editing',
        onPrimaryAction: () => Navigator.of(dialog).pop(false),
        secondaryActionLabel: 'Discard changes',
        onSecondaryAction: () => Navigator.of(dialog).pop(true),
      ),
    );
    _dialogOpen = false;
    if (!mounted || discard != true) return;
    if (_section == SettingsSection.accessibility) {
      _controller.previewAccessibility(null);
    }
    setState(() => _discard = true);
    context.go(AppRoutes.profile);
  }

  @override
  void dispose() {
    _validationFocus.dispose();
    _name.dispose();
    _locale.dispose();
    _timezone.dispose();
    super.dispose();
  }

  String? _serverError(String field) =>
      widget.state.section == _section &&
          (widget.state.failure?.fields.contains(field) ?? false)
      ? 'Check this setting and try again.'
      : null;

  @override
  Widget build(BuildContext context) {
    final serverFields =
        widget.state.section == _section &&
        (widget.state.failure?.fields.isNotEmpty ?? false);
    return PopScope(
      canPop: _discard || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.state.phase == ProfilePhase.failed &&
                (widget.state.section == null ||
                    widget.state.section == _section))
              _FailureNotice(
                widget.state,
                onRetry:
                    widget.state.section == null ||
                        widget.state.reconciling ||
                        _canRetrySave
                    ? _controller.retry
                    : null,
              ),
            if (_restoreConflictDraft != null)
              TextButton(
                onPressed: _locked
                    ? null
                    : () {
                        _editDraft(() {
                          _restoreConflictDraft!.call();
                          _restoreConflictDraft = null;
                          _formRevision++;
                        });
                      },
                child: const Text('Restore my edits'),
              ),
            if (_invalid || serverFields)
              Focus(
                focusNode: _validationFocus,
                child: const _Status('Check the highlighted fields.'),
              ),
            ...switch (_section) {
              SettingsSection.profile => _profileFields(),
              SettingsSection.notifications => _notificationFields(),
              SettingsSection.accessibility => _accessibilityFields(),
            },
            const SizedBox(height: 16),
            MemoraButton(
              label: _saving ? 'Saving…' : 'Save changes',
              onPressed:
                  !_dirty ||
                      _locked ||
                      widget.state.waitingToRetry ||
                      widget.state.reconciling
                  ? null
                  : _save,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _profileFields() => [
    MemoraTextField(
      label: 'Display name',
      controller: _name,
      onChanged: _textEdited,
      enabled: !_locked,
      errorText: _serverError('display_name'),
      validator: (_) {
        final name = _profileDraft.displayName;
        if (name.isEmpty ||
            name.runes.length > 100 ||
            name.runes.any((rune) => rune < 32)) {
          return 'Enter a display name with 1 to 100 visible characters.';
        }
        return null;
      },
    ),
    const SizedBox(height: 16),
    MemoraTextField(
      label: 'Language and region',
      hintText: 'en-LK',
      controller: _locale,
      onChanged: _textEdited,
      enabled: !_locked,
      errorText: _serverError('locale'),
      validator: (input) {
        final locale = input?.trim() ?? '';
        return locale.length <= 35 &&
                RegExp(r'^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$').hasMatch(locale)
            ? null
            : 'Enter a language and region such as en-LK.';
      },
    ),
    const SizedBox(height: 16),
    _timezoneField(),
  ];

  Widget _timezoneField() => MemoraTextField(
    label: 'Time zone',
    hintText: 'Asia/Colombo',
    controller: _timezone,
    onChanged: _textEdited,
    enabled: !_locked,
    errorText: _serverError('timezone'),
    validator: (input) {
      final zone = input?.trim() ?? '';
      return zone.isNotEmpty &&
              zone.length <= 100 &&
              RegExp(r'^[A-Za-z0-9_+/-]+$').hasMatch(zone)
          ? null
          : 'Enter a time zone such as Asia/Colombo.';
    },
  );

  Widget _toggle(
    String label,
    bool value,
    ValueChanged<bool> change, {
    String? subtitle,
  }) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: subtitle == null ? null : Text(subtitle),
    value: value,
    onChanged: _locked ? null : change,
  );

  void _changeNotifications({
    bool? enabled,
    bool? mission,
    bool? reward,
    bool? streak,
    PreviewDetail? preview,
    int? limit,
    LocalWindow? Function()? quiet,
    LocalWindow? Function()? preferred,
  }) {
    final current = _notifications;
    _editDraft(() {
      _notifications = (
        enabled: enabled ?? current.enabled,
        mission: mission ?? current.mission,
        reward: reward ?? current.reward,
        streak: streak ?? current.streak,
        quiet: quiet == null ? current.quiet : quiet(),
        preferred: preferred == null ? current.preferred : preferred(),
        timezone: current.timezone,
        preview: preview ?? current.preview,
        dailyLimit: limit ?? current.dailyLimit,
      );
    });
  }

  List<Widget> _notificationFields() => [
    _toggle(
      'Notifications',
      _notifications.enabled,
      (value) => _changeNotifications(enabled: value),
      subtitle:
          'You can keep using Memora with notifications off. '
          'Manage device notification permission in your device settings.',
    ),
    _toggle(
      'Mission reminders',
      _notifications.mission,
      (value) => _changeNotifications(mission: value),
    ),
    _toggle(
      'Reward updates',
      _notifications.reward,
      (value) => _changeNotifications(reward: value),
    ),
    _toggle(
      'Streak reminders',
      _notifications.streak,
      (value) => _changeNotifications(streak: value),
    ),
    _window(
      'Preferred reminder window',
      _notifications.preferred,
      (value) => _changeNotifications(preferred: () => value),
      error:
          _serverError('preferred_window_start_local') ??
          _serverError('preferred_window_end_local'),
    ),
    _window(
      'Quiet hours',
      _notifications.quiet,
      (value) => _changeNotifications(quiet: () => value),
      error:
          _serverError('quiet_start_local') ?? _serverError('quiet_end_local'),
    ),
    const SizedBox(height: 16),
    _timezoneField(),
    const SizedBox(height: 16),
    DropdownButtonFormField<PreviewDetail>(
      key: ValueKey(('preview', _formRevision)),
      initialValue: _notifications.preview == PreviewDetail.unknown
          ? null
          : _notifications.preview,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Lock screen preview',
        errorText: _serverError('lock_screen_detail'),
      ),
      hint: const Text('Choose preview detail'),
      items: const [
        DropdownMenuItem(value: PreviewDetail.minimal, child: Text('Minimal')),
        DropdownMenuItem(value: PreviewDetail.subject, child: Text('Subject')),
        DropdownMenuItem(
          value: PreviewDetail.detailed,
          child: Text('Detailed'),
        ),
      ],
      onChanged: _locked
          ? null
          : (value) => _changeNotifications(preview: value),
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<int>(
      key: ValueKey(('limit', _formRevision)),
      initialValue: _notifications.dailyLimit,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Daily reminder limit',
        errorText: _serverError('max_daily_reminders'),
      ),
      items: [
        for (var count = 0; count <= maxDailyReminders; count++)
          DropdownMenuItem(value: count, child: Text('$count')),
      ],
      onChanged: _locked ? null : (value) => _changeNotifications(limit: value),
    ),
  ];

  Widget _window(
    String label,
    LocalWindow? value,
    ValueChanged<LocalWindow?> change, {
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(
            value == null
                ? 'Not set'
                : '${_displayTime(value.start)} to ${_displayTime(value.end)}',
          ),
          trailing: const Icon(Icons.schedule),
          onTap: _locked
              ? null
              : () async {
                  final window = await showDialog<LocalWindow>(
                    context: context,
                    builder: (context) =>
                        _WindowDialog(label: label, initial: value),
                  );
                  if (mounted && window != null) change(window);
                },
        ),
        if (value != null)
          TextButton(
            onPressed: _locked ? null : () => change(null),
            child: Text('Clear ${label.toLowerCase()}'),
          ),
        if (error != null) _Status(error),
      ],
    );
  }

  String _displayTime(String value) {
    final parts = value.split(':');
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  void _changeAccessibility({
    bool? reduced,
    bool? sound,
    bool? haptics,
    bool? timer,
    bool? contrast,
  }) {
    final current = _accessibility;
    _editDraft(() {
      _accessibility = (
        reducedMotion: reduced ?? current.reducedMotion,
        soundEnabled: sound ?? current.soundEnabled,
        hapticsEnabled: haptics ?? current.hapticsEnabled,
        timerVisible: timer ?? current.timerVisible,
        highContrast: contrast ?? current.highContrast,
      );
    });
    _controller.previewAccessibility(_accessibility);
  }

  List<Widget> _accessibilityFields() => [
    const Text('Memora follows your device’s text size settings.'),
    _toggle(
      'Reduced motion',
      _accessibility.reducedMotion,
      (value) => _changeAccessibility(reduced: value),
    ),
    _toggle(
      'Sound',
      _accessibility.soundEnabled,
      (value) => _changeAccessibility(sound: value),
    ),
    _toggle(
      'Haptics',
      _accessibility.hapticsEnabled,
      (value) => _changeAccessibility(haptics: value),
    ),
    _toggle(
      'Show elapsed mission time',
      _accessibility.timerVisible,
      (value) => _changeAccessibility(timer: value),
      subtitle: 'This does not affect scoring or progress.',
    ),
    _toggle(
      'High contrast',
      _accessibility.highContrast,
      (value) => _changeAccessibility(contrast: value),
    ),
  ];
}

class _WindowDialog extends StatefulWidget {
  const _WindowDialog({required this.label, required this.initial});

  final String label;
  final LocalWindow? initial;

  @override
  State<_WindowDialog> createState() => _WindowDialogState();
}

class _WindowDialogState extends State<_WindowDialog> {
  final _form = GlobalKey<FormState>();
  late final _start = TextEditingController(text: widget.initial?.start);
  late final _end = TextEditingController(text: widget.initial?.end);

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  String? _validate(String? value) =>
      RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d(\.\d{1,6})?)?$')
          .hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter a time in 24-hour format, such as 22:00.';

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.label),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MemoraTextField(
            label: 'Start time',
            hintText: 'HH:MM',
            controller: _start,
            validator: _validate,
          ),
          const SizedBox(height: 16),
          MemoraTextField(
            label: 'End time',
            hintText: 'HH:MM',
            controller: _end,
            validator: _validate,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.of(context)
                .pop((start: _start.text.trim(), end: _end.text.trim()));
          }
        },
        child: const Text('Set window'),
      ),
    ],
  );
}
