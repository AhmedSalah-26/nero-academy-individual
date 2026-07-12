import 'package:flutter/material.dart';
import 'dashboard_sidebar.dart';
import 'dashboard_header.dart';
import 'dashboard_nav_item.dart';

/// Dashboard Scaffold - Main layout structure for dashboards
/// Provides responsive layout with collapsible sidebar
class DashboardScaffold extends StatefulWidget {
  final String title;
  final String titleAr;
  final List<DashboardNavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onNavItemSelected;
  final Widget content;
  final Widget? headerActions;
  final bool initiallyCollapsed;

  const DashboardScaffold({
    super.key,
    required this.title,
    required this.titleAr,
    required this.navItems,
    required this.selectedIndex,
    required this.onNavItemSelected,
    required this.content,
    this.headerActions,
    this.initiallyCollapsed = false,
  });

  @override
  State<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<DashboardScaffold> {
  late bool _isCollapsed;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  // Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initiallyCollapsed;
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  void _toggleSidebar() {
    setState(() => _isCollapsed = !_isCollapsed);
  }

  void _openDrawer() {
    setState(() => _isDrawerOpen = true);
  }

  void _closeDrawer() {
    setState(() => _isDrawerOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);

    // Auto-collapse on tablet
    if (isTablet && !_isCollapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isCollapsed = true);
      });
    }

    // Get current tab title
    final currentNavItem = widget.navItems[widget.selectedIndex];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currentTitle =
        isArabic ? currentNavItem.labelAr : currentNavItem.label;

    if (isMobile) {
      return PopScope(
        // If drawer is open → close it. If not on home → go home. Else → allow exit.
        canPop: widget.selectedIndex == 0 && !_isDrawerOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_isDrawerOpen) {
            _closeDrawer();
          } else if (widget.selectedIndex != 0) {
            widget.onNavItemSelected(0);
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(currentTitle),
            actions:
                widget.headerActions != null ? [widget.headerActions!] : null,
            leading: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: animation,
                    child: child,
                  );
                },
                child: Icon(
                  _isDrawerOpen ? Icons.close : Icons.menu,
                  key: ValueKey<bool>(_isDrawerOpen),
                ),
              ),
              onPressed: () {
                if (_isDrawerOpen) {
                  _closeDrawer();
                } else {
                  _openDrawer();
                }
              },
            ),
          ),
          body: Stack(
            children: [
              // Main content
              widget.content,
              // Custom drawer that starts below AppBar
              if (_isDrawerOpen) ...[
                // Overlay with fade animation
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isDrawerOpen ? 1.0 : 0.0,
                  child: GestureDetector(
                    onTap: _closeDrawer,
                    child: Container(
                      color: Colors.black54,
                    ),
                  ),
                ),
                // Drawer with slide animation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  left: isArabic ? null : (_isDrawerOpen ? 0 : -280),
                  right: isArabic ? (_isDrawerOpen ? 0 : -280) : null,
                  top: 0,
                  bottom: 0,
                  child: Material(
                    elevation: 16,
                    color: Theme.of(context).appBarTheme.backgroundColor ??
                        Theme.of(context).primaryColor,
                    child: SizedBox(
                      width: 280,
                      child: DashboardSidebar(
                        items: widget.navItems,
                        selectedIndex: widget.selectedIndex,
                        onItemSelected: (index) {
                          widget.onNavItemSelected(index);
                          _closeDrawer();
                        },
                        isCollapsed: false,
                        onToggleCollapse: () {},
                        headerTitle: widget.title,
                        headerTitleAr: widget.titleAr,
                        showCollapseButton: false,
                        showHeader: false,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Desktop/Tablet layout
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          DashboardSidebar(
            items: widget.navItems,
            selectedIndex: widget.selectedIndex,
            onItemSelected: widget.onNavItemSelected,
            isCollapsed: _isCollapsed,
            onToggleCollapse: _toggleSidebar,
            headerTitle: widget.title,
            headerTitleAr: widget.titleAr,
          ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  DashboardHeader(
                    title: currentTitle,
                    onMenuPressed: null,
                    actions: widget.headerActions,
                  ),
                  Expanded(child: widget.content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
