import 'package:chants/app/colors.dart';
import 'package:chants/app/spacing.dart';
import 'package:chants/presentation/browse/competition_screen.dart';
import 'package:chants/presentation/create/create_hub_screen.dart';
import 'package:chants/presentation/feed/chant_stage_screen.dart';
import 'package:chants/presentation/profile/creator_profile_screen.dart';
import 'package:chants/presentation/saved/saved_songbook_screen.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  final String uid;
  final int initialIndex;

  const AppShell({super.key, required this.uid, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex;
  late final Set<int> _visited;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _visited = {widget.initialIndex};
  }

  void _select(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
  }

  Widget _screen(int index) {
    return switch (index) {
      0 => ChantStageScreen(
        onCreate: () => _select(2),
        onBrowseClubs: () => _select(1),
      ),
      1 => const CompetitionScreen(
        competitionId: 'premier-league',
        competitionName: 'Clubs',
      ),
      2 => CreateHubScreen(onChooseClub: () => _select(1)),
      3 => SavedSongbookScreen(uid: widget.uid),
      4 => CreatorProfileScreen(uid: widget.uid),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    _visited.add(_selectedIndex);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          5,
          (index) => _visited.contains(index)
              ? KeyedSubtree(
                  key: PageStorageKey<String>('primary-tab-$index'),
                  child: _screen(index),
                )
              : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: ChantsBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _select,
      ),
    );
  }
}

class ChantsBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ChantsBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    (
      label: 'Stage',
      icon: Icons.play_circle_outline,
      selected: Icons.play_circle,
    ),
    (label: 'Clubs', icon: Icons.shield_outlined, selected: Icons.shield),
    (label: 'Create', icon: Icons.add, selected: Icons.add),
    (
      label: 'Songbook',
      icon: Icons.menu_book_outlined,
      selected: Icons.menu_book,
    ),
    (label: 'You', icon: Icons.person_outline, selected: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.stageChrome,
        border: Border(top: BorderSide(color: AppColors.stageRule, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = selectedIndex == index;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: InkResponse(
                    key: ValueKey<String>('primary-nav-${item.label}'),
                    onTap: () => onSelected(index),
                    containedInkWell: true,
                    highlightShape: BoxShape.rectangle,
                    child: ExcludeSemantics(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (selected)
                            const Positioned(
                              top: 0,
                              left: 14,
                              right: 14,
                              child: SizedBox(
                                height: 2,
                                child: ColoredBox(color: AppColors.gold),
                              ),
                            ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 34,
                                child: index == 2
                                    ? DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.gold
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: selected
                                                ? AppColors.gold
                                                : AppColors.textFaint,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            Radii.sm,
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: 36,
                                          child: Icon(
                                            Icons.add,
                                            color: selected
                                                ? AppColors.goldOnDark
                                                : AppColors.textBody,
                                            size: 24,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        selected ? item.selected : item.icon,
                                        color: selected
                                            ? AppColors.gold
                                            : AppColors.textMuted,
                                        size: 22,
                                      ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: selected
                                      ? AppColors.textHeadline
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
