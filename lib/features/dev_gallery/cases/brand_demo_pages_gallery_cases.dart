import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/widgets/blocks/before_after.dart';
import 'package:starter/shared/widgets/blocks/code_block.dart';
import 'package:starter/shared/widgets/blocks/code_lines.dart';
import 'package:starter/shared/widgets/blocks/confirm_action.dart';
import 'package:starter/shared/widgets/blocks/data_table.dart';
import 'package:starter/shared/widgets/blocks/detail_list.dart';
import 'package:starter/shared/widgets/blocks/detail_section.dart';
import 'package:starter/shared/widgets/blocks/empty_note.dart';
import 'package:starter/shared/widgets/blocks/endpoint_card.dart';
import 'package:starter/shared/widgets/blocks/line_tabs.dart';
import 'package:starter/shared/widgets/blocks/link_bar.dart';
import 'package:starter/shared/widgets/blocks/metric_trend.dart';
import 'package:starter/shared/widgets/blocks/page_intro.dart';
import 'package:starter/shared/widgets/blocks/person_card.dart';
import 'package:starter/shared/widgets/blocks/release_card.dart';
import 'package:starter/shared/widgets/blocks/ring_stats.dart';
import 'package:starter/shared/widgets/blocks/section_block.dart';
import 'package:starter/shared/widgets/blocks/segmented.dart';
import 'package:starter/shared/widgets/blocks/stat_card.dart';
import 'package:starter/shared/widgets/blocks/stat_grid.dart';
import 'package:starter/shared/widgets/blocks/terminal_window.dart';
import 'package:starter/shared/widgets/blocks/toc.dart';
import 'package:starter/shared/widgets/blocks/topic_chips.dart';
import 'package:starter/shared/widgets/blocks/usage_meter.dart';
import 'package:starter/shared/widgets/brand/app_notice.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';
import 'package:starter/shared/widgets/rings/ring_meter.dart';

/// Whole product pages composed end-to-end from the brand kit (APP-BLOCKS.md
/// "The demo app" is the shape of truth): an analytics overview, a developer
/// API reference, a release log and a team page. Each page is one realistic
/// signed-in surface — page intro, working controls, sections in the app's
/// own rhythm — instead of a specimen row. Dev-only surface, so the labels
/// are literal English.
enum BrandDemoPagesGalleryKind { overview, apiDocs, releases, team }

/// Builds the "Demo pages" gallery cases, one per whole page.
List<GalleryCase> buildBrandDemoPagesGalleryCases() {
  return <GalleryCase>[
    for (final kind in BrandDemoPagesGalleryKind.values)
      TypedGalleryCase<BrandDemoPagesGalleryKind>(
        id: 'brandDemoPages.${kind.name}',
        screenId: 'brandDemoPages',
        screenLabelBuilder: (_) => 'Demo pages',
        caseLabelBuilder: (_) => _pagesCaseLabel(kind),
        stateFactory: (_) => kind,
        pageFactory: (_, state) => _DemoPageScaffold(page: _pageFor(kind)),
      ),
  ];
}

String _pagesCaseLabel(BrandDemoPagesGalleryKind kind) => switch (kind) {
  BrandDemoPagesGalleryKind.overview => 'Overview page',
  BrandDemoPagesGalleryKind.apiDocs => 'API reference page',
  BrandDemoPagesGalleryKind.releases => 'Releases page',
  BrandDemoPagesGalleryKind.team => 'Team page',
};

Widget _pageFor(BrandDemoPagesGalleryKind kind) => switch (kind) {
  BrandDemoPagesGalleryKind.overview => const _OverviewPage(),
  BrandDemoPagesGalleryKind.apiDocs => const _ApiDocsPage(),
  BrandDemoPagesGalleryKind.releases => const _ReleasesPage(),
  BrandDemoPagesGalleryKind.team => const _TeamPage(),
};

/// The page frame every demo page hangs in: the brand accent pinned to oxide
/// (BRAND.md s4 — the primary is the orange), the app's screen padding and a
/// scrolling column whose sections stretch edge to edge.
class _DemoPageScaffold extends ConsumerWidget {
  const _DemoPageScaffold({required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final brandTheme = ForuiThemeFactory.build(
      brightness: theme.colors.brightness,
      accent: AppAccent.oxide,
      fontScale: 1,
      interactionPolicy: ref.watch(interactionPolicyProvider),
      responsiveFontScale: context.appUnit.typographyScale,
      presentationPolicy: ref.watch(presentationPolicyProvider),
    );
    return FTheme(
      data: brandTheme,
      child: SingleChildScrollView(
        padding: context.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[page],
        ),
      ),
    );
  }
}

/// The page's section gap (`gap-10`, 40dp) — the same air AppSectionBlock
/// puts between a section head and its content, used between sections.
Widget _sectionGap(BuildContext context) =>
    SizedBox(height: context.spacing.xl2 + context.spacing.sm);

/// One ruled panel (the app's outline box): a rounded hairline border around
/// [children], each separated by a 1px line — the demo app's meters panel.
class _RuledPanel extends StatelessWidget {
  const _RuledPanel({required this.children, this.destructive = false});

  final List<Widget> children;

  /// Draws the outline in the destructive color at 40% — the settings page's
  /// "Delete this workspace" tone.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final borderColor = destructive
        ? theme.brand.destructive.withValues(alpha: 0.4)
        : theme.colors.border;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: borderColor, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < children.length; index++) ...<Widget>[
            if (index > 0) Container(height: 1, color: borderColor),
            // The divide-y panel's own row padding (px-4 sm:px-6 py-4).
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.lg + context.spacing.sm,
                vertical: context.spacing.lg,
              ),
              child: children[index],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview — the analytics dashboard (APP-BLOCKS.md "The overview page"):
// page intro, range segmented, four stat cards, the usage meters in one ruled
// panel, ring shares, and the top-pages table.
// ---------------------------------------------------------------------------

class _OverviewPage extends StatefulWidget {
  const _OverviewPage();

  @override
  State<_OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<_OverviewPage> {
  String _range = '30';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppPageIntro(
          kicker: 'Paperplane',
          title: 'Overview',
          description: 'Traffic and plan usage for the last $_range days.',
        ),
        _sectionGap(context),
        Row(
          children: <Widget>[
            Flexible(
              child: AppSegmented<String>(
                options: const <AppSegmentOption<String>>[
                  (value: '7', label: '7 days', key: null),
                  (value: '30', label: '30 days', key: null),
                  (value: '90', label: '90 days', key: null),
                ],
                value: _range,
                onChanged: (value) => setState(() => _range = value),
              ),
            ),
            SizedBox(width: context.spacing.md),
            FButton.icon(
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              onPress: () {},
              child: const Icon(FLucideIcons.rotateCcw, semanticLabel: 'Refresh'),
            ),
          ],
        ),
        SizedBox(height: context.spacing.xl),
        // The cards' trends carry no comparison string — the kit's stat-card
        // recipe keeps the trend to its signed change, because on a narrow
        // card the comparison would run past the border (the range lives in
        // the intro sentence instead).
        const AppStatGrid(
          children: <Widget>[
            AppStatCard(
              label: 'Visitors',
              value: '48,210',
              trend: AppMetricTrend(change: 0.12),
            ),
            AppStatCard(
              label: 'Sign-ups',
              value: '1,284',
              trend: AppMetricTrend(change: 0.082),
            ),
            AppStatCard(
              label: 'Bounce rate',
              value: '42.1%',
              trend: AppMetricTrend(
                change: -0.03,
                good: AppTrendGood.down,
                format: AppTrendFormat.points,
              ),
            ),
            AppStatCard(
              label: 'Page load',
              value: '1.8 s',
              hint: 'Median across all pages.',
              trend: AppMetricTrend(change: 0.09, good: AppTrendGood.down),
            ),
          ],
        ),
        _sectionGap(context),
        const AppSectionBlock(
          title: 'Usage',
          description: 'What the plan covers this month.',
          child: _RuledPanel(
            children: <Widget>[
              AppUsageMeter(
                label: 'Events this month',
                used: 7420,
                limit: 10000,
                unit: 'events',
                valueText: '7,420 of 10,000 events',
                resetsOn: 'Resets on 1 November',
              ),
              AppUsageMeter(
                label: 'Seats',
                used: 9,
                limit: 10,
                unit: 'seats',
                valueText: '9 of 10 seats',
              ),
              AppUsageMeter(
                label: 'Data kept',
                used: 12,
                limit: 13,
                unit: 'months',
                valueText: '12 of 13 months',
              ),
            ],
          ),
        ),
        _sectionGap(context),
        const AppSectionBlock(
          title: 'Where visits land',
          description: 'Share of the month’s page views, per section.',
          child: AppRingStats(
            stats: <AppRingStat>[
              (value: '62%', label: 'Dashboards', share: 0.62, count: null),
              (value: '21%', label: 'Alerts', share: 0.21, count: null),
              (value: '17%', label: 'Reports', share: 0.17, count: null),
            ],
          ),
        ),
        _sectionGap(context),
        const AppSectionBlock(
          title: 'Top pages',
          description: 'The five pages people see most, for the chosen range.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppDataTable(
              columns: <String>['Page', 'Views', 'Avg. time'],
              rows: <List<String>>[
                <String>['/dashboards', '18,204', '4:12'],
                <String>['/alerts', '9,881', '1:47'],
                <String>['/reports/weekly', '6,130', '6:03'],
                <String>['/settings', '3,554', '2:20'],
                <String>['/billing', '1,441', '1:12'],
              ],
              accentColumn: 1,
            ),
          ),
        ),
        SizedBox(height: context.spacing.xl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// API reference — the developer docs page: sub-nav line tabs, a table of
// contents beside the detail sections, credentials, code, a webhook card and
// a terminal replay of a build.
// ---------------------------------------------------------------------------

class _ApiDocsPage extends StatefulWidget {
  const _ApiDocsPage();

  @override
  State<_ApiDocsPage> createState() => _ApiDocsPageState();
}

class _ApiDocsPageState extends State<_ApiDocsPage> {
  int _activeSection = 0;
  int _surface = 0;

  static const _sectionTitles = <String>[
    'Credentials',
    'Install the client',
    'First request',
    'Webhooks',
    'Watch a build',
  ];

  @override
  Widget build(BuildContext context) {
    final toc = AppToc(
      entries: <AppTocEntry>[
        for (final (index, label) in _sectionTitles.indexed)
          AppTocEntry(label: label, active: index == _activeSection),
      ],
      onSelected: (index) => setState(() => _activeSection = index),
      semanticLabel: 'On this page',
    );
    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _credentialsSection(context),
        for (final builder in <Widget Function(BuildContext)>[
          _installSection,
          _firstRequestSection,
          _webhooksSection,
          _watchBuildSection,
        ]) ...<Widget>[
          _sectionGap(context),
          builder(context),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppPageIntro(
          kicker: 'Developers',
          title: 'API reference',
          description: 'Everything the starter API accepts, and how to call it.',
        ),
        _sectionGap(context),
        AppLineTabs(
          tabs: const <String>['REST', 'Webhooks', 'CLI'],
          counts: const <int?>[12, 4, null],
          selectedIndex: _surface,
          onSelected: (index) => setState(() => _surface = index),
          semanticLabel: 'API surfaces',
        ),
        _sectionGap(context),
        // From 720 the contents rail sits beside the sections; below it the
        // rail stacks on top, like the docs layout folding to one column.
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 720) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 192, child: toc),
                  SizedBox(width: context.spacing.xl3),
                  Expanded(child: sections),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(alignment: AlignmentDirectional.centerStart, child: toc),
                _sectionGap(context),
                sections,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _credentialsSection(BuildContext context) {
    return const AppSectionBlock(
      title: 'Credentials',
      description: 'Every request names the workspace and carries its key.',
      child: AppDetailSection(
        title: 'Workspace credentials',
        description: 'Rotate the key any time; the old one works for an hour.',
        items: <AppDetailItem>[
          AppDetailItem(label: 'Base URL', value: 'https://api.starter.dev/v1', mono: true),
          AppDetailItem(
            label: 'API key',
            value: 'sk_live_9f2c',
            mono: true,
            copyable: true,
          ),
          AppDetailItem(label: 'Region', value: 'eu-central'),
          AppDetailItem(label: 'Rate limit', value: '600 requests a minute'),
          AppDetailItem(label: 'Legacy endpoint'),
        ],
        copyLabel: 'Copy the key',
      ),
    );
  }

  Widget _installSection(BuildContext context) {
    return const AppSectionBlock(
      title: 'Install the client',
      description: 'One package, no peer dependencies.',
      child: AppCodeBlock(
        copyLabel: 'Copy the install command',
        files: <AppCodeFile>[
          AppCodeFile(label: 'npm', source: 'npm install @starter/sdk'),
          AppCodeFile(label: 'pnpm', source: 'pnpm add @starter/sdk'),
          AppCodeFile(label: 'bun', source: 'bun add @starter/sdk'),
        ],
      ),
    );
  }

  Widget _firstRequestSection(BuildContext context) {
    const source = '''
import { Starter } from '@starter/sdk';

const starter = new Starter(process.env.STARTER_KEY);

const workspaces = await starter.workspaces.list();
for (const workspace of workspaces) {
  console.log(workspace.name, workspace.plan);
}''';
    return const AppSectionBlock(
      title: 'First request',
      description: 'List the workspaces the key can see.',
      child: _EditorPanel(child: AppCodeLines(source: source, lineNumbers: true)),
    );
  }

  Widget _webhooksSection(BuildContext context) {
    // Example day: green means delivered on the first try, the two amber days
    // needed retries, the red day failed.
    return const AppSectionBlock(
      title: 'Webhooks',
      description: 'The build-finished hook, over the last 30 days.',
      child: AppEndpointCard(
        url: 'https://api.starter.dev/hooks/builds',
        startLabel: 'Sep 14',
        days: <double>[
          1, 1, 1, 1, 0.97, 1, 1, 1, 1, 1, 1, 0.5, 1, 1, 1, 1, 1, 1, 1, 1, //
          1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        ],
        metrics: <AppEndpointMetric>[
          (label: 'First try', value: '99.4%'),
          (label: 'Median time', value: '182 ms'),
          (label: 'Retried', value: '41'),
        ],
        deliveries: <AppEndpointDelivery>[
          (event: 'build.finished', status: 200, at: '12:04:31'),
          (event: 'build.failed', status: 200, at: '12:03:58'),
          (event: 'build.started', status: 503, at: '12:01:12'),
        ],
        primaryLabel: 'Send a test event',
        secondaryLabel: 'Pause',
      ),
    );
  }

  Widget _watchBuildSection(BuildContext context) {
    return AppSectionBlock(
      title: 'Watch a build',
      description: 'The same stream the CLI prints, in the page.',
      child: AppTerminalWindow(
        title: 'starter dev.log',
        actions: <Widget>[
          FButton.icon(
            variant: FButtonVariant.ghost,
            size: FButtonSizeVariant.sm,
            onPress: () {},
            child: const Icon(FLucideIcons.rotateCcw, semanticLabel: 'Replay the log'),
          ),
        ],
        lines: const <AppTerminalLine>[
          AppTerminalLine.command('starter deploy --workspace paperplane'),
          AppTerminalLine.note('production config'),
          AppTerminalLine.step('compiled 128 files', answer: '4 targets'),
          AppTerminalLine.result('built in 74.3s'),
          AppTerminalLine.keyValue('Binary', 'build/macos/Release.app'),
        ],
      ),
    );
  }
}

/// The editor frame around [AppCodeLines]: the kit's outline box, clipped so
/// the gutter and the hovered row stay inside the radius.
class _EditorPanel extends StatelessWidget {
  const _EditorPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Releases — the changelog page: filter chips over release cards, the
// upgrade before/after, an archive notice, and the unpublish action behind a
// typed confirmation.
// ---------------------------------------------------------------------------

/// One release on the page: its card data plus the channel the chips filter.
class _ReleaseData {
  const _ReleaseData({
    required this.version,
    required this.date,
    required this.channel,
    required this.groups,
    this.latestLabel,
    this.installs = const <AppReleaseInstall>[],
  });

  final String version;
  final String date;
  final String channel;
  final String? latestLabel;
  final List<AppReleaseGroup> groups;
  final List<AppReleaseInstall> installs;
}

const _releaseInstalls = <AppReleaseInstall>[
  (manager: 'npm', command: 'npm install -g starter-cli'),
  (manager: 'bun', command: 'bun add -g starter-cli'),
  (manager: 'deno', command: 'deno install -g starter-cli'),
];

const _releases = <_ReleaseData>[
  _ReleaseData(
    version: '0.13.0-beta.1',
    date: 'October 28, 2026',
    channel: 'Beta',
    groups: <AppReleaseGroup>[
      (
        kind: AppReleaseChangeKind.added,
        lines: <String>[
          'Doctor explains environment drift in plain words.',
          'The deploy summary names every target it skipped.',
        ],
      ),
    ],
    installs: _releaseInstalls,
  ),
  _ReleaseData(
    version: '0.12.0',
    date: 'August 26, 2026',
    channel: 'Stable',
    latestLabel: 'Latest',
    groups: <AppReleaseGroup>[
      (
        kind: AppReleaseChangeKind.changed,
        lines: <String>[
          'Templates resolve to the current model tier on new instances.',
        ],
      ),
    ],
    installs: _releaseInstalls,
  ),
  _ReleaseData(
    version: '0.11.1',
    date: 'August 22, 2026',
    channel: 'Stable',
    groups: <AppReleaseGroup>[
      (
        kind: AppReleaseChangeKind.fixed,
        lines: <String>[
          'Existing instances pick up provider template changes.',
          'Provider detection accepts endpoints with a trailing slash.',
        ],
      ),
      (
        kind: AppReleaseChangeKind.changed,
        lines: <String>[
          'Migrations and the instance sync share one environment loader.',
        ],
      ),
    ],
    installs: _releaseInstalls,
  ),
];

class _ReleasesPage extends StatefulWidget {
  const _ReleasesPage();

  @override
  State<_ReleasesPage> createState() => _ReleasesPageState();
}

class _ReleasesPageState extends State<_ReleasesPage> {
  int _channel = 0;

  static const _channels = <String>['All', 'Stable', 'Beta', 'Archived'];

  List<_ReleaseData> get _visibleReleases {
    final channel = _channels[_channel];
    if (channel == 'All') {
      return _releases;
    }
    return _releases.where((release) => release.channel == channel).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final visible = _visibleReleases;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppPageIntro(
          kicker: 'starter-cli',
          title: 'Releases',
          description: 'What shipped, and what it changed.',
        ),
        _sectionGap(context),
        // The channel colors ride the chips' markers (one color per kind,
        // everywhere it appears).
        AppTopicChips(
          chips: <AppTopicChip>[
            const (label: 'All', tone: null),
            (label: 'Stable', tone: theme.brand.green),
            (label: 'Beta', tone: theme.brand.yellow),
            const (label: 'Archived', tone: null),
          ],
          selectedIndex: _channel,
          onSelected: (index) => setState(() => _channel = index),
        ),
        SizedBox(height: context.spacing.xl),
        if (visible.isEmpty)
          const AppEmptyNote(
            'No archived releases yet. Old versions stay installable for a year.',
          )
        else
          for (final (index, release) in visible.indexed) ...<Widget>[
            if (index > 0) SizedBox(height: context.spacing.lg),
            AppReleaseCard(
              version: release.version,
              date: release.date,
              product: 'starter-cli',
              symbol: 'St',
              symbolLabel: 'starter-cli mark',
              latestLabel: release.latestLabel,
              groups: release.groups,
              installs: release.installs,
              notesLabel: 'All release notes',
            ),
          ],
        _sectionGap(context),
        const AppNotice(
          title: '0.10.x and earlier are archived',
          body: 'Install them with starter-cli@<version> until December 1, 2026.',
          role: AppStatusRole.warning,
        ),
        _sectionGap(context),
        const AppSectionBlock(
          title: 'The upgrade, with and without the tool',
          description: 'The same release, done by hand and done by starter-cli.',
          child: AppBeforeAfter(
            beforeLabel: 'By hand',
            afterLabel: 'With the tool',
            rows: <AppBeforeAfterRow>[
              AppBeforeAfterRow(
                what: 'Changelog',
                before: 'Paste notes into three stores.',
                after: 'Write once in RELEASE.md; every store follows.',
              ),
              AppBeforeAfterRow(
                what: 'Versioning',
                before: 'Bump three files and hope they match.',
                after: 'One bump, stamped into every build.',
              ),
              AppBeforeAfterRow(
                what: 'Rollback',
                before: 'Rebuild the old tag from memory.',
                after: 'starter rollback re-pins the last good build.',
              ),
            ],
          ),
        ),
        _sectionGap(context),
        AppSectionBlock(
          title: 'Unpublish a release',
          description: 'The destructive step, behind a typed confirmation.',
          child: _RuledPanel(
            destructive: true,
            children: <Widget>[
              Wrap(
                spacing: context.spacing.lg,
                runSpacing: context.spacing.lg,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      'Unpublishing 0.12.0 removes it from the registry. '
                      'Installs already pinned keep working; loose ranges break.',
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                  AppConfirmAction(
                    title: 'Unpublish 0.12.0?',
                    description:
                        'Downloads break for anyone not pinned to an exact '
                        'version. This cannot be undone.',
                    confirmLabel: 'Unpublish release',
                    cancelLabel: 'Cancel',
                    confirmText: 'starter-cli',
                    confirmPrompt: 'Type starter-cli to confirm',
                    triggerLabel: 'Unpublish release',
                    onConfirm: () async => null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Team — the account page: an invite action, role chips filtering the person
// cards, the workspace facts, the plan's ring meters and the share link.
// ---------------------------------------------------------------------------

/// One member row of the page: card data plus the role the chips filter.
class _MemberData {
  const _MemberData({
    required this.name,
    required this.role,
    this.bio,
    this.links = const <String>[],
    this.trailing,
  });

  final String name;
  final String role;
  final String? bio;
  final List<String> links;
  final Widget? trailing;
}

class _TeamPage extends StatefulWidget {
  const _TeamPage();

  @override
  State<_TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<_TeamPage> {
  int _roleFilter = 0;

  static const _filters = <String>['All', 'Owner', 'Admin', 'Member', 'Invited'];

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final members = <_MemberData>[
      const _MemberData(
        name: 'Hmziq Rs',
        role: 'Owner',
        bio: 'Keeps the starter honest: tokens in, brand out.',
        links: <String>['github.com/hmziqrs'],
        trailing: AppStatusTag(label: '2-step on', role: AppStatusRole.success),
      ),
      const _MemberData(
        name: 'Ada Byron',
        role: 'Admin',
        bio: 'Reviews every proposal and closes the loops.',
        trailing: AppStatusTag(label: '2-step on', role: AppStatusRole.success),
      ),
      const _MemberData(
        name: 'Grace Murray',
        role: 'Member',
        bio: 'Ships the compiler notes and the samples.',
      ),
      const _MemberData(
        name: 'Lin Uno',
        role: 'Invited',
        bio: 'Invite sent October 24; expires in six days.',
        trailing: AppStatusTag(
          label: 'Invite sent',
          role: AppStatusRole.warning,
          showMarker: true,
        ),
      ),
    ];
    final filter = _filters[_roleFilter];
    final visibleMembers = filter == 'All'
        ? members
        : members.where((member) => member.role == filter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppPageIntro(
          kicker: 'Paperplane',
          title: 'Team',
          description: 'People who can see this workspace.',
        ),
        _sectionGap(context),
        Wrap(
          spacing: context.spacing.lg,
          runSpacing: context.spacing.lg,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FButton(
              size: FButtonSizeVariant.sm,
              mainAxisSize: MainAxisSize.min,
              onPress: () {},
              child: const Text('Invite people'),
            ),
            AppTopicChips(
              chips: <AppTopicChip>[
                const (label: 'All roles', tone: null),
                (label: 'Owner', tone: theme.brand.oxide),
                (label: 'Admin', tone: theme.brand.teal),
                (label: 'Member', tone: theme.brand.blue),
                const (label: 'Invited', tone: null),
              ],
              selectedIndex: _roleFilter,
              onSelected: (index) => setState(() => _roleFilter = index),
            ),
          ],
        ),
        SizedBox(height: context.spacing.xl),
        if (visibleMembers.isEmpty)
          const AppEmptyNote('No members carry this role yet.')
        else
          for (final (index, member) in visibleMembers.indexed) ...<Widget>[
            if (index > 0) SizedBox(height: context.spacing.lg),
            AppPersonCard(
              name: member.name,
              role: member.role,
              bio: member.bio,
              links: member.links,
              trailing: member.trailing,
            ),
          ],
        _sectionGap(context),
        const AppSectionBlock(
          title: 'Workspace facts',
          description: 'What every member of this workspace shares.',
          child: AppDetailSection(
            title: 'Paperplane',
            description: 'The workspace every build and dashboard belongs to.',
            items: <AppDetailItem>[
              AppDetailItem(label: 'Name', value: 'Paperplane'),
              AppDetailItem(label: 'Address', value: 'sightline.app/paperplane', mono: true),
              AppDetailItem(label: 'Region', value: 'eu-central'),
              AppDetailItem(label: 'API key', value: 'sk_live_9f2c', mono: true, copyable: true),
              AppDetailItem(label: 'Legacy id'),
            ],
            copyLabel: 'Copy the key',
          ),
        ),
        _sectionGap(context),
        const AppSectionBlock(
          title: 'Seats and storage',
          description: 'What the Team plan covers this month.',
          child: RingMeter(
            label: 'Plan usage',
            items: <RingMeterItem>[
              RingMeterItem(label: 'Seats', value: 0.9, detail: '9 of 10'),
              RingMeterItem(label: 'Storage', value: 0.72, detail: '7.2 of 10 GB'),
              RingMeterItem(label: 'Backups', value: 0.4, detail: '1,200 of 3,000 runs'),
            ],
            semanticsLabel: 'Plan usage',
          ),
        ),
        _sectionGap(context),
        const AppSectionBlock(
          title: 'Pending invites',
          description: 'Invitations that have not been accepted yet.',
          child: AppEmptyNote(
            'Nothing waiting — every invitation has been accepted.',
          ),
        ),
        _sectionGap(context),
        AppSectionBlock(
          title: 'Share the workspace',
          description: 'The address your teammates open to join.',
          child: AppLinkBar(
            url: 'https://sightline.app/paperplane',
            copyLabel: 'Copy link',
            actions: <AppLinkAction>[
              AppLinkAction(
                icon: FLucideIcons.link,
                label: 'Open the workspace address',
                onPressed: () {},
              ),
              AppLinkAction(
                icon: FLucideIcons.share,
                label: 'Share the workspace address',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
