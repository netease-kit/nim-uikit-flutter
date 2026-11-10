// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../chat_kit_client.dart';
import 'emoji/emoji.dart';
import 'emoji_panel_extension.dart';

class EmojiPanel extends StatefulWidget {
  const EmojiPanel({
    Key? key,
    required this.onEmojiSelected,
    required this.onEmojiSendClick,
    required this.onEmojiDelete,
    this.displayMode = EmojiPanelDisplayMode.mobile,
    this.sendImage,
  }) : super(key: key);

  final ValueChanged<String> onEmojiSelected;
  final Function() onEmojiDelete;
  final Function() onEmojiSendClick;
  final EmojiPanelDisplayMode displayMode;
  final ChatImageMessageSender? sendImage;

  @override
  State<StatefulWidget> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  static const int _pageSize = 20;
  static const String _emojiTabId = 'nim_chatkit_ui.emoji';

  final PageController _mobilePageController = PageController();
  String _selectedTabId = _emojiTabId;
  int _selectedMobilePageIndex = 0;

  @override
  void dispose() {
    _mobilePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extensionTabs = _extensionTabs();
    if (extensionTabs.isEmpty) {
      return _buildEmojiOnlyPanel();
    }
    return _buildExtensiblePanel(extensionTabs);
  }

  List<EmojiPanelTab> _extensionTabs() {
    final tabs = <EmojiPanelTab>[];
    final ids = <String>{_emojiTabId};
    for (final extension in ChatKitClient.instance.emojiPanelExtensions) {
      for (final tab in extension.buildTabs()) {
        final qualifiedId = '${extension.id}.${tab.id}';
        if (extension.id.isEmpty || tab.id.isEmpty || !ids.add(qualifiedId)) {
          continue;
        }
        tabs.add(
          EmojiPanelTab(
            id: qualifiedId,
            iconBuilder: tab.iconBuilder,
            contentBuilder: tab.contentBuilder,
            mobilePageCount: tab.mobilePageCount,
            mobilePageBuilder: tab.mobilePageBuilder,
            semanticsLabel: tab.semanticsLabel,
          ),
        );
      }
    }
    return tabs;
  }

  Widget _buildEmojiOnlyPanel() {
    if (widget.displayMode == EmojiPanelDisplayMode.desktopOrWeb) {
      return _DesktopEmojiGrid(
        onEmojiSelected: widget.onEmojiSelected,
        onEmojiDelete: widget.onEmojiDelete,
      );
    }
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xffE9EAEB)),
        Expanded(child: _buildMobileEmojiPages()),
        _buildSendButton(height: 32),
      ],
    );
  }

  Widget _buildExtensiblePanel(List<EmojiPanelTab> extensionTabs) {
    final allIds = <String>{_emojiTabId, ...extensionTabs.map((e) => e.id)};
    final selectedId =
        allIds.contains(_selectedTabId) ? _selectedTabId : _emojiTabId;
    final selectedTab = selectedId == _emojiTabId
        ? null
        : extensionTabs.firstWhere((tab) => tab.id == selectedId);
    final sender = widget.sendImage ?? (_) async => false;
    final tabContext = EmojiPanelTabContext(
      displayMode: widget.displayMode,
      sendImage: sender,
    );
    final mobilePages = widget.displayMode == EmojiPanelDisplayMode.mobile
        ? _buildMobilePanelPages(extensionTabs, tabContext)
        : const <_MobilePanelPage>[];

    return Column(
      children: [
        const Divider(height: 1, color: Color(0xffE9EAEB)),
        Expanded(
          child: widget.displayMode == EmojiPanelDisplayMode.mobile
              ? Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _mobilePageController,
                        allowImplicitScrolling: true,
                        itemCount: mobilePages.length,
                        onPageChanged: (index) {
                          final tabId = mobilePages[index].tabId;
                          setState(() {
                            _selectedTabId = tabId;
                            _selectedMobilePageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) =>
                            mobilePages[index].child,
                      ),
                    ),
                    SizedBox(
                      height: 16,
                      child: selectedTab == null
                          ? null
                          : _buildPageIndicator(
                              mobilePages,
                              _selectedMobilePageIndex,
                            ),
                    ),
                  ],
                )
              : selectedTab == null
                  ? _DesktopEmojiGrid(
                      onEmojiSelected: widget.onEmojiSelected,
                      onEmojiDelete: widget.onEmojiDelete,
                    )
                  : selectedTab.contentBuilder(context, tabContext),
        ),
        SizedBox(
          height: 44,
          child: ColoredBox(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTab(
                          selected: selectedId == _emojiTabId,
                          semanticsLabel: 'emoji',
                          onTap: () => _selectTab(
                            _emojiTabId,
                            mobilePages,
                          ),
                          icon: Image.asset(
                            'emoji/default/emoji_00.png',
                            package: kPackage,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                        ...extensionTabs.map((tab) {
                          final selected = selectedId == tab.id;
                          return _buildTab(
                            selected: selected,
                            semanticsLabel: tab.semanticsLabel,
                            onTap: () => _selectTab(tab.id, mobilePages),
                            icon: tab.iconBuilder(context, selected),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                if (selectedId == _emojiTabId) _buildSendButton(height: 44),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required bool selected,
    required Widget icon,
    required VoidCallback onTap,
    String? semanticsLabel,
  }) {
    return Semantics(
      label: semanticsLabel,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? const Color(0xffEAF2FC) : Colors.transparent,
              border: selected
                  ? const Border(
                      bottom: BorderSide(color: Color(0xff185FA5), width: 2),
                    )
                  : null,
            ),
            child: Center(child: SizedBox.square(dimension: 28, child: icon)),
          ),
        ),
      ),
    );
  }

  void _selectTab(String tabId, List<_MobilePanelPage> mobilePages) {
    if (widget.displayMode != EmojiPanelDisplayMode.mobile) {
      if (_selectedTabId != tabId) {
        setState(() => _selectedTabId = tabId);
      }
      return;
    }
    final pageIndex = mobilePages.indexWhere((page) => page.tabId == tabId);
    if (pageIndex < 0) {
      return;
    }
    setState(() {
      _selectedTabId = tabId;
      _selectedMobilePageIndex = pageIndex;
    });
    if (_mobilePageController.hasClients) {
      _mobilePageController.jumpToPage(pageIndex);
    }
  }

  Widget _buildPageIndicator(
    List<_MobilePanelPage> mobilePages,
    int selectedPageIndex,
  ) {
    if (selectedPageIndex < 0 || selectedPageIndex >= mobilePages.length) {
      return const SizedBox.shrink();
    }
    final page = mobilePages[selectedPageIndex];
    if (page.pageCount <= 1) {
      return const SizedBox.shrink();
    }
    return Center(
      key: const ValueKey<String>('emoji-panel-page-indicator'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(page.pageCount, (index) {
          final selected = index == page.pageIndex;
          return Container(
            key: ValueKey<String>('emoji-panel-page-dot-$index'),
            width: 6,
            height: 6,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? CommonColors.color_337eff
                  : const Color(0xFFFFFFFF),
              border: selected
                  ? null
                  : Border.all(color: const Color(0xFFD8DDE5), width: 0.5),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSendButton({required double height}) {
    return Align(
      alignment: Alignment.topRight,
      child: InkWell(
        onTap: widget.onEmojiSendClick,
        child: Container(
          height: height,
          width: 60,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: CommonColors.color_337eff),
          child: Text(
            S.of(context).chatMessageSend,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileEmojiPages() {
    return PageView(
      children: _buildMobileEmojiPageItems(),
      allowImplicitScrolling: true,
    );
  }

  List<Widget> _buildMobileEmojiPageItems() {
    final pages = <Widget>[];
    final size = (emojiData.length / _pageSize).ceil();
    for (var i = 0; i < size; ++i) {
      int start = i * _pageSize;
      int end = start + _pageSize > emojiData.length
          ? emojiData.length
          : start + _pageSize;
      pages.add(
        EmojiPage(
          start: start,
          end: end,
          emojiTap: widget.onEmojiSelected,
          deleteTap: widget.onEmojiDelete,
        ),
      );
    }
    return pages;
  }

  List<_MobilePanelPage> _buildMobilePanelPages(
    List<EmojiPanelTab> extensionTabs,
    EmojiPanelTabContext tabContext,
  ) {
    final emojiPages = _buildMobileEmojiPageItems();
    final pages = emojiPages
        .asMap()
        .entries
        .map(
          (entry) => _MobilePanelPage(
            tabId: _emojiTabId,
            pageIndex: entry.key,
            pageCount: emojiPages.length,
            child: KeyedSubtree(
              key: ValueKey<String>('$_emojiTabId.${entry.key}'),
              child: entry.value,
            ),
          ),
        )
        .toList();
    for (final tab in extensionTabs) {
      for (var pageIndex = 0; pageIndex < tab.mobilePageCount; pageIndex++) {
        final page = tab.mobilePageBuilder?.call(
              context,
              tabContext,
              pageIndex,
            ) ??
            tab.contentBuilder(context, tabContext);
        pages.add(
          _MobilePanelPage(
            tabId: tab.id,
            pageIndex: pageIndex,
            pageCount: tab.mobilePageCount,
            child: KeyedSubtree(
              key: ValueKey<String>('${tab.id}.$pageIndex'),
              child: page,
            ),
          ),
        );
      }
    }
    return pages;
  }
}

class _MobilePanelPage {
  const _MobilePanelPage({
    required this.tabId,
    required this.pageIndex,
    required this.pageCount,
    required this.child,
  });

  final String tabId;
  final int pageIndex;
  final int pageCount;
  final Widget child;
}

class _DesktopEmojiGrid extends StatelessWidget {
  const _DesktopEmojiGrid({
    required this.onEmojiSelected,
    required this.onEmojiDelete,
  });

  final ValueChanged<String> onEmojiSelected;
  final VoidCallback onEmojiDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: emojiData.length + 1,
        itemBuilder: (context, index) {
          if (index == emojiData.length) {
            return _DesktopEmojiItem(
              onTap: onEmojiDelete,
              child: SvgPicture.asset(
                'images/ic_emoji_del.svg',
                package: kPackage,
                height: 24,
                width: 24,
              ),
            );
          }
          final emoji = emojiData[index];
          final source = emoji['name'] as String;
          final tag = emoji['tag'] as String;
          return _DesktopEmojiItem(
            onTap: () => onEmojiSelected(tag),
            child: Image.asset(
              source,
              package: kPackage,
              height: 28,
              width: 28,
            ),
          );
        },
      ),
    );
  }
}

class _DesktopEmojiItem extends StatefulWidget {
  const _DesktopEmojiItem({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_DesktopEmojiItem> createState() => _DesktopEmojiItemState();
}

class _DesktopEmojiItemState extends State<_DesktopEmojiItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
        child: ColoredBox(
          color: _hovering ? const Color(0x14337EFF) : Colors.transparent,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class EmojiPage extends StatelessWidget {
  const EmojiPage({
    Key? key,
    required this.start,
    required this.end,
    required this.emojiTap,
    required this.deleteTap,
  }) : super(key: key);

  final int start;
  final int end;
  final ValueChanged<String> emojiTap;
  final Function() deleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var w = constraints.maxWidth / 7;
          var h = constraints.maxHeight / 3;
          return GridView.count(
            crossAxisCount: 7,
            childAspectRatio: w / h,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...emojiData.sublist(start, end).map((e) {
                String source = e['name'] as String;
                String tag = e['tag'] as String;
                return InkWell(
                  onTap: () {
                    emojiTap(tag);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                    ),
                    alignment: Alignment.center,
                    height: 30,
                    width: 30,
                    child: Image.asset(
                      source,
                      package: kPackage,
                      height: 24,
                      width: 24,
                    ),
                  ),
                );
              }).toList(),
              ...[
                InkWell(
                  onTap: deleteTap,
                  child: Container(
                    height: 30,
                    width: 30,
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'images/ic_emoji_del.svg',
                      package: kPackage,
                      height: 20,
                      width: 20,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
