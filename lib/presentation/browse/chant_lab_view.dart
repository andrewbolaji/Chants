import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/data/models/chant.dart';
import 'package:chants/data/services/chant_browse.dart';
import 'package:chants/presentation/browse/browse_supporting_notice.dart';
import 'package:chants/presentation/shared/chant_card.dart';
import 'package:chants/presentation/shared/club_signal.dart';
import 'package:chants/presentation/shared/empty_state.dart';
import 'package:chants/presentation/shared/section_eyebrow.dart';
import 'package:flutter/material.dart';

class ChantLabView extends StatefulWidget {
  final List<Chant> chants;
  final Map<String, String> playerNames;
  final bool isFromCache;
  final bool hasRecoverableError;
  final bool canStartChant;
  final String emptyMessage;
  final String signedOutEmptyMessage;
  final DateTime now;
  final ValueChanged<Chant> onChantTap;
  final VoidCallback? onStartChant;
  final Widget? callUp;
  final bool signalAppearance;

  const ChantLabView({
    super.key,
    required this.chants,
    this.playerNames = const {},
    this.isFromCache = false,
    this.hasRecoverableError = false,
    required this.canStartChant,
    required this.emptyMessage,
    required this.signedOutEmptyMessage,
    required this.now,
    required this.onChantTap,
    this.onStartChant,
    this.callUp,
    this.signalAppearance = false,
  });

  @override
  State<ChantLabView> createState() => _ChantLabViewState();
}

class _ChantLabViewState extends State<ChantLabView>
    with AutomaticKeepAliveClientMixin {
  final StableChantOrder _topOrder = StableChantOrder();
  ChantLabSort _sort = ChantLabSort.top;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final top = _topOrder.reconcile(rankBrowseTop(widget.chants));
    final visible = _sort == ChantLabSort.top
        ? top
        : rankBrowseNew(widget.chants);

    final items = <Widget>[
      ?widget.callUp,
      Padding(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.md,
          Spacing.lg,
          Spacing.xs,
        ),
        child: SectionEyebrow(
          text: 'New songs start here',
          gold: true,
          signalAppearance: widget.signalAppearance,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Text(
          'Rising means early community support. It does not mean Terrace Proven.',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            color: widget.signalAppearance
                ? AppColors.signalTextMuted
                : AppColors.textMuted,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.md,
          Spacing.lg,
          Spacing.sm,
        ),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<ChantLabSort>(
            key: const Key('chant-lab-sort'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ChantLabSort.top, label: Text('TOP')),
              ButtonSegment(value: ChantLabSort.newChants, label: Text('NEW')),
            ],
            selected: {_sort},
            onSelectionChanged: (selection) {
              setState(() => _sort = selection.single);
            },
          ),
        ),
      ),
      if (widget.isFromCache)
        BrowseSupportingNotice(
          label: 'DEVICE CACHE',
          message: 'These chants are from this device while Chants reconnects.',
          icon: Icons.offline_pin_outlined,
          signalAppearance: widget.signalAppearance,
        ),
      if (widget.hasRecoverableError)
        BrowseSupportingNotice(
          label: 'LAST LOADED CHANTS',
          message:
              'Fresh updates are unavailable. You can still open these chants.',
          icon: Icons.sync_problem_outlined,
          signalAppearance: widget.signalAppearance,
        ),
    ];

    if (visible.isEmpty) {
      items.add(
        widget.signalAppearance
            ? ClubSignalState(
                headline: 'The lab is open',
                message: widget.canStartChant
                    ? widget.emptyMessage
                    : widget.signedOutEmptyMessage,
                icon: Icons.science_outlined,
                onAction: widget.canStartChant ? widget.onStartChant : null,
                actionLabel: widget.canStartChant ? 'START A CHANT' : null,
              )
            : EmptyState(
                headline: 'THE LAB IS OPEN',
                message: widget.canStartChant
                    ? widget.emptyMessage
                    : widget.signedOutEmptyMessage,
                icon: Icons.science_outlined,
                onAction: widget.canStartChant ? widget.onStartChant : null,
                actionLabel: widget.canStartChant ? 'START A CHANT' : null,
              ),
      );
    } else {
      items.addAll(
        visible.map(
          (chant) => ChantCard(
            key: ValueKey('chant-lab-${chant.id}'),
            chant: chant,
            playerName: chant.playerId == null
                ? null
                : widget.playerNames[chant.playerId],
            rising: isRisingChant(chant, now: widget.now),
            signalAppearance: widget.signalAppearance,
            onTap: () => widget.onChantTap(chant),
          ),
        ),
      );
    }

    return ListView.builder(
      key: const PageStorageKey('chant-lab-list'),
      padding: const EdgeInsets.only(bottom: Spacing.xxxl * 2),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}
