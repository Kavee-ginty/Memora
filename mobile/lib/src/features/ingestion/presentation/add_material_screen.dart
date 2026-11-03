import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/app_header.dart';
import '../../../design_system/components/banner.dart';
import '../../../design_system/components/bottom_nav.dart';
import '../../../design_system/components/bottom_sheet.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/dialog.dart';
import '../../../design_system/components/scaffold.dart';
import '../../../design_system/components/text_field.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../../auth/domain/bootstrap_state.dart';
import '../../common/presentation/authorized_placeholder_screen.dart';
import '../application/ingestion_flow_controller.dart';
import '../data/source_picker.dart';
import 'widgets/source_tile.dart';

/// Add learning material destination (UI/UX §9.9).
///
/// The screen is reachable from a subject's learning path. It keeps manual text
/// in a protected local draft, uploads temporary sources directly to object
/// storage, and never promises that uploading earns XP.
class AddMaterialScreen extends ConsumerWidget {
  const AddMaterialScreen({
    super.key,
    this.subjectId,
    this.controller,
    this.onClose,
  });

  /// Route subject. Null when a test injects [controller].
  final String? subjectId;

  /// Test seam: a pre-built controller with a seeded repository or draft.
  final IngestionFlowController? controller;

  /// Test seam for navigation; production uses the router.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injected = controller;
    if (injected != null) {
      return _AddMaterialBody(controller: injected, onClose: onClose);
    }

    final id = subjectId;
    if (id == null || id.isEmpty) return const NotFoundScreen();

    final provider = ingestionFlowControllerProvider(id);
    final flowController = ref.watch(provider.notifier);
    return _AddMaterialBody(controller: flowController, onClose: onClose);
  }
}

class _AddMaterialBody extends StatefulWidget {
  const _AddMaterialBody({required this.controller, this.onClose});

  final IngestionFlowController controller;
  final VoidCallback? onClose;

  @override
  State<_AddMaterialBody> createState() => _AddMaterialBodyState();
}

class _AddMaterialBodyState extends State<_AddMaterialBody> {
  late IngestionFlowState _state;
  late final TextEditingController _textController;
  late int _lastRestoredRevision;
  VoidCallback? _removeFlowListener;

  @override
  void initState() {
    super.initState();
    _state = widget.controller.currentState;
    _lastRestoredRevision = _state.restoredRevision;
    _textController = TextEditingController(text: _state.manualText);
    _listenToController();
  }

  @override
  void didUpdateWidget(covariant _AddMaterialBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _removeFlowListener?.call();
      _state = widget.controller.currentState;
      _lastRestoredRevision = _state.restoredRevision;
      _textController.value = TextEditingValue(
        text: _state.manualText,
        selection: TextSelection.collapsed(offset: _state.manualText.length),
      );
      _listenToController();
    }
  }

  void _listenToController() {
    _removeFlowListener = widget.controller.addListener(
      _handleFlowChange,
      fireImmediately: false,
    );
  }

  void _handleFlowChange(IngestionFlowState next) {
    if (!mounted) return;
    if (next.restoredRevision != _lastRestoredRevision) {
      _lastRestoredRevision = next.restoredRevision;
      _textController.value = TextEditingValue(
        text: next.manualText,
        selection: TextSelection.collapsed(offset: next.manualText.length),
      );
    }
    setState(() => _state = next);
  }

  @override
  void dispose() {
    _removeFlowListener?.call();
    _textController.dispose();
    super.dispose();
  }

  SubjectSummaryDomain? get _selectedSubject {
    for (final subject in _state.subjects) {
      if (subject.id == _state.subjectId) return subject;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _state.stage == IngestionFlowStage.submitted;
    final canDiscard =
        _state.hasContent ||
        _state.sources.isNotEmpty ||
        _state.updateId != null;

    return MemoraScaffold(
      appBar: MemoraHeader.detail(
        title: 'Add learning material',
        onBackPressed: _confirmClose,
        contextualAction: canDiscard
            ? TextButton(
                onPressed: _confirmDiscard,
                child: Text(
                  'Discard',
                  style: MemoraTypography.button.copyWith(
                    color: MemoraColors.feedbackCritical,
                  ),
                ),
              )
            : null,
      ),
      offlineBanner: _state.isOffline
          ? MemoraBanner(
              variant: MemoraBannerVariant.offline,
              title: "You're offline",
              message:
                  _state.failure?.message ??
                  'Reconnect to upload material and extract concepts.',
              actionLabel: 'Try again',
              onAction: widget.controller.retryAfterFailure,
            )
          : null,
      bottomNavigationBar: MemoraBottomNavigationBar(
        currentIndex: 1,
        onTap: _navigate,
      ),
      body: submitted ? _buildSubmitted(context) : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(
              top: MemoraSpacing.space16,
              bottom: MemoraSpacing.space24,
            ),
            children: <Widget>[
              _subjectSelector(),
              const SizedBox(height: MemoraSpacing.space16),
              _uploadZone(context),
              const SizedBox(height: MemoraSpacing.space16),
              _textSection(),
              if (_state.sources.isNotEmpty) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space16),
                Text('Sources', style: MemoraTypography.cardTitle),
                const SizedBox(height: MemoraSpacing.space8),
                for (final source in _state.sources) ...<Widget>[
                  SourceTile(
                    source: source,
                    onRetry:
                        source.status == LocalSourceState.failed &&
                            source.bytes != null
                        ? () => widget.controller.retrySource(source.id)
                        : null,
                    onRemove: _state.canRemoveSource
                        ? () => widget.controller.removeSource(source.id)
                        : null,
                  ),
                  const SizedBox(height: MemoraSpacing.space8),
                ],
              ],
              if (_state.failure != null && !_state.isOffline) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space8),
                _failureBanner(),
              ],
              const SizedBox(height: MemoraSpacing.space16),
              _privacyNote(),
            ],
          ),
        ),
        _actionArea(),
      ],
    );
  }

  Widget _subjectSelector() {
    final subject = _selectedSubject;
    return MemoraCard(
      onTap: _state.canSelectSubject ? () => _showSubjectSheet(context) : null,
      semanticLabel: subject == null
          ? 'Subject, none selected'
          : 'Subject, ${subject.name}',
      child: Row(
        children: <Widget>[
          const ExcludeSemantics(
            child: Icon(
              Icons.menu_book_outlined,
              color: MemoraColors.brandBlue,
            ),
          ),
          const SizedBox(width: MemoraSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Subject', style: MemoraTypography.metadata),
                const SizedBox(height: MemoraSpacing.space4),
                Text(
                  subject?.name ?? 'Choose a subject',
                  style: MemoraTypography.cardTitle,
                ),
              ],
            ),
          ),
          if (_state.canSelectSubject)
            const ExcludeSemantics(
              child: Icon(Icons.expand_more, color: MemoraColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _uploadZone(BuildContext context) {
    final enabled = _state.canAddSource;
    final atLimit = _state.sources.length >= maxSourceCount;

    return Semantics(
      button: enabled,
      label: 'Upload material',
      hint: 'Choose a PDF, take a photo, or choose a photo.',
      child: InkWell(
        onTap: enabled ? () => _showSourceSheet(context) : null,
        borderRadius: MemoraRadii.primaryCard,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space16,
            vertical: MemoraSpacing.space24,
          ),
          decoration: BoxDecoration(
            color: enabled
                ? MemoraColors.surfaceOcean
                : MemoraColors.surfaceSoft,
            borderRadius: MemoraRadii.primaryCard,
            border: Border.all(
              color: enabled
                  ? MemoraColors.controlRest
                  : MemoraColors.borderDefault,
              width: 1.5,
            ),
          ),
          child: Column(
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  Icons.upload_file,
                  size: 40,
                  color: enabled
                      ? MemoraColors.brandBlue
                      : MemoraColors.textMuted,
                ),
              ),
              const SizedBox(height: MemoraSpacing.space8),
              Text(
                'Upload material',
                style: MemoraTypography.cardTitle.copyWith(
                  color: enabled
                      ? MemoraColors.textPrimary
                      : MemoraColors.textMuted,
                ),
              ),
              const SizedBox(height: MemoraSpacing.space4),
              Text(
                'PDF, PNG, or JPEG · up to 25 MB each',
                textAlign: TextAlign.center,
                style: MemoraTypography.metadata,
              ),
              if (atLimit) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space4),
                Text(
                  'You can add up to 5 files.',
                  textAlign: TextAlign.center,
                  style: MemoraTypography.metadata.copyWith(
                    color: MemoraColors.feedbackAttention,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _textSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MemoraTextField(
          label: 'Paste your notes',
          hintText: 'Type or paste what you learned…',
          controller: _textController,
          maxLines: 6,
          enabled: _state.canEditText,
          onChanged: widget.controller.onManualTextChanged,
          errorText: _state.isOverTextLimit ? 'Your notes are too long.' : null,
          helperText: _state.isOverTextLimit
              ? 'Keep your notes under 20,000 characters.'
              : '${_state.manualText.length} of 20,000 characters',
        ),
        const SizedBox(height: MemoraSpacing.space8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _state.savedLocally
                    ? 'Saved on this device'
                    : 'Draft saves as you type',
                style: MemoraTypography.metadata,
              ),
            ),
            MemoraButton(
              label: 'Save draft',
              variant: MemoraButtonVariant.tertiary,
              isFullWidth: false,
              isLoading: _state.isSaving,
              onPressed: _state.canSaveDraft
                  ? () => widget.controller.saveDraft()
                  : null,
            ),
          ],
        ),
        if (_state.isLocked) ...<Widget>[
          const SizedBox(height: MemoraSpacing.space4),
          Text(
            'This material has been sent. Retry the failed upload or discard '
            'it to make changes.',
            style: MemoraTypography.metadata.copyWith(
              color: MemoraColors.feedbackAttention,
            ),
          ),
        ],
      ],
    );
  }

  Widget _failureBanner() {
    final failure = _state.failure!;
    final message = failure.nextAction == null
        ? failure.message
        : '${failure.message} ${failure.nextAction}';
    return MemoraBanner(
      variant: MemoraBannerVariant.critical,
      title: 'Could not finish this step',
      message: message,
      actionLabel: failure.retryable ? 'Try again' : null,
      onAction: failure.retryable ? widget.controller.retryAfterFailure : null,
    );
  }

  Widget _privacyNote() {
    return Container(
      padding: const EdgeInsets.all(MemoraSpacing.space12),
      decoration: const BoxDecoration(
        color: MemoraColors.surfaceMint,
        borderRadius: MemoraRadii.compactCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ExcludeSemantics(
            child: Icon(
              Icons.lock_outline,
              size: 20,
              color: MemoraColors.feedbackPositive,
            ),
          ),
          const SizedBox(width: MemoraSpacing.space8),
          Expanded(
            child: Text(
              'Your files are temporary. Memora removes the source after your '
              'concepts are added and keeps only what you approve.',
              style: MemoraTypography.metadata,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionArea() {
    final reason = _disabledReason;
    return Container(
      padding: const EdgeInsets.only(
        top: MemoraSpacing.space12,
        bottom: MemoraSpacing.space12,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: MemoraColors.borderDefault)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (reason != null) ...<Widget>[
            Text(
              reason,
              textAlign: TextAlign.center,
              style: MemoraTypography.metadata,
            ),
            const SizedBox(height: MemoraSpacing.space8),
          ],
          MemoraButton(
            label: _state.primaryActionLabel,
            icon: const Icon(Icons.auto_awesome_outlined),
            isLoading: _state.stage == IngestionFlowStage.submitting,
            onPressed: _state.canExtract ? _onPrimary : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitted(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: MemoraSpacing.space24,
            ),
            children: <Widget>[
              MemoraCard(
                child: Column(
                  children: <Widget>[
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.check_circle,
                        size: 48,
                        color: MemoraColors.feedbackPositive,
                      ),
                    ),
                    const SizedBox(height: MemoraSpacing.space12),
                    Text(
                      'Material received',
                      textAlign: TextAlign.center,
                      style: MemoraTypography.sectionTitle,
                    ),
                    const SizedBox(height: MemoraSpacing.space8),
                    Text(
                      'Memora is extracting concepts from your material. This '
                      'can take a moment.',
                      textAlign: TextAlign.center,
                      style: MemoraTypography.body.copyWith(
                        color: MemoraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: MemoraSpacing.space12),
          child: MemoraButton(label: 'Back to Learning', onPressed: _close),
        ),
      ],
    );
  }

  String? get _disabledReason {
    if (_state.stage == IngestionFlowStage.submitting) return null;
    if (_state.isOffline) return 'Reconnect to extract concepts.';
    if (_state.isOverTextLimit) {
      return 'Keep your notes under 20,000 characters.';
    }
    if (_state.hasBlockingSource) {
      return 'Remove or retry the failed file to continue.';
    }
    if (_state.isServerDraft) {
      return 'Save this draft, then start a new update to extract concepts.';
    }
    if (!_state.hasContent) return 'Add a file or paste text to continue.';
    return null;
  }

  Future<void> _onPrimary() async {
    if (_state.isLocked) {
      await widget.controller.retrySubmission();
    } else {
      await widget.controller.extractConcepts();
    }
  }

  Future<void> _showSubjectSheet(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MemoraBottomSheet(
          title: 'Choose subject',
          subtitle: 'Material is added to this learning path.',
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              for (final subject in _state.subjects)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(subject.name, style: MemoraTypography.bodyStrong),
                  subtitle: Text(
                    subject.code,
                    style: MemoraTypography.metadata,
                  ),
                  trailing: subject.id == _state.subjectId
                      ? const Icon(Icons.check, color: MemoraColors.brandBlue)
                      : null,
                  selected: subject.id == _state.subjectId,
                  onTap: () => Navigator.of(sheetContext).pop(subject.id),
                ),
            ],
          ),
        );
      },
    );
    if (chosen != null) widget.controller.selectSubject(chosen);
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    final choice = await showModalBottomSheet<_SourceChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MemoraBottomSheet(
          title: 'Add a source',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Choose a PDF or document'),
                subtitle: const Text('PDF, PNG, or JPEG'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_SourceChoice.document),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_SourceChoice.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from photos'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_SourceChoice.gallery),
              ),
            ],
          ),
        );
      },
    );

    switch (choice) {
      case _SourceChoice.document:
        await widget.controller.addDocument();
      case _SourceChoice.camera:
        await widget.controller.addCamera();
      case _SourceChoice.gallery:
        await widget.controller.addGallery();
      case null:
        break;
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MemoraDialog(
          title: 'Discard this material?',
          message:
              'Your draft and selected files will be removed. This cannot be '
              'undone.',
          primaryActionLabel: 'Discard',
          isDestructive: true,
          onPrimaryAction: () => Navigator.of(dialogContext).pop(true),
          secondaryActionLabel: 'Keep editing',
          onSecondaryAction: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );
    if (discard != true) return;

    final cleared = await widget.controller.discard();
    if (!mounted || !cleared) return;
    _close();
  }

  Future<void> _confirmClose() async {
    if (_state.sources.isEmpty && !_state.isLocked) {
      await widget.controller.flushDraft();
      if (!mounted) return;
      _close();
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MemoraDialog(
          title: 'Leave this material?',
          message: _state.isLocked
              ? 'Your material is already being processed by Memora. You can '
                    'leave this screen.'
              : 'Your text is saved on this device. Selected files are not '
                    'saved and will need to be added again.',
          primaryActionLabel: 'Leave',
          isDestructive: true,
          onPrimaryAction: () => Navigator.of(dialogContext).pop(true),
          secondaryActionLabel: 'Stay',
          onSecondaryAction: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );
    if (leave != true) return;

    await widget.controller.flushDraft();
    if (!mounted) return;
    _close();
  }

  Future<void> _navigate(int index) async {
    await widget.controller.flushDraft();
    if (!mounted) return;
    final path = switch (index) {
      0 => AppRoutes.home,
      1 => AppRoutes.learning,
      2 => AppRoutes.progress,
      3 => AppRoutes.profile,
      _ => AppRoutes.learning,
    };
    context.go(path);
  }

  void _close() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.learning);
    }
  }
}

enum _SourceChoice { document, camera, gallery }
