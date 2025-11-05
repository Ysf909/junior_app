// lib/views/main_page.dart
import 'package:flutter/material.dart';
import 'package:junior_app/services/localization_extension.dart';
import 'package:junior_app/view/pages/cloud_page.dart';
import 'package:junior_app/view/pages/listview_page.dart';
import 'package:junior_app/view/pages/photo_library_page.dart';
import 'package:junior_app/view/pages/timer_page.dart';
import 'package:junior_app/view_model/auth_view_model.dart';
import 'package:junior_app/view_model/localization_view_model.dart';
import 'package:junior_app/view_model/navigation_view_model.dart';
import 'package:junior_app/view_model/network_view_model.dart';
import 'package:junior_app/view_model/photo_library_view_model.dart';
import 'package:junior_app/view_model/timer_view_model.dart';
import 'package:provider/provider.dart';
import 'package:junior_app/view_model/theme_view_model.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start timer automatically
    final timerVM = Provider.of<TimerViewModel>(context, listen: false);
    timerVM.startTimer();

    // Start network monitoring
    final networkVM = Provider.of<NetworkViewModel>(context, listen: false);
    networkVM.startMonitoring();

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navVM = Provider.of<NavigationViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final timerVM = Provider.of<TimerViewModel>(context);

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Responsive breakpoint: wide screens get a fixed side menu
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return WillPopScope(
      onWillPop: () async {
        if (!navVM.isTimerScreen) {
          navVM.navigateTo(AppScreen.timer);
          return false;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('exit_app')),
            content: Text(context.tr('exit_confirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.tr('exit')),
              ),
            ],
          ),
        );

        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(navVM.screenTitle),
          // For a permanent sidebar, no hamburger needed
          automaticallyImplyLeading: !isWide,
          actions: [
            // Theme toggle (MVVM)
            IconButton(
              tooltip: 'Toggle Theme',
              onPressed: () => context.read<ThemeViewModel>().toggle(),
              icon: Icon(
                context.watch<ThemeViewModel>().mode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
            ),

            if (navVM.currentScreen == AppScreen.timer)
              Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 16.0),
                child: Text(
                  timerVM.firstLoginDate != null
                      ? 'First login: ${_formatDate(timerVM.firstLoginDate!)}'
                      : '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),

        // Drawer only on narrow screens
        drawer: isWide ? null : _buildDrawer(context, authVM, navVM, timerVM),

        // Body: fixed sidebar + content on wide screens; just content on narrow
        body: Row(
          children: [
            if (isWide)
              _buildSideMenu(context, authVM, navVM, timerVM), // fixed sidebar
            Expanded(child: _buildCurrentScreen(navVM.currentScreen)),
          ],
        ),
      ),
    );
  }

  // ---------- Fixed side menu (for wide screens) ----------
 Widget _buildSideMenu(BuildContext context, AuthViewModel authVM,
    NavigationViewModel navVM, TimerViewModel timerVM) {
  final colorScheme = Theme.of(context).colorScheme;

  return SizedBox(
    width: 260,
    child: Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          // Header fills width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colorScheme.primary,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    (authVM.username?.isNotEmpty == true
                            ? authVM.username!.substring(0, 1)
                            : 'U')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authVM.username ?? 'User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total time: ${timerVM.formattedTotalTime}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Expanded list fills remaining height
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.timer,
                  title: 'Timer',
                  onTap: () => navVM.navigateTo(AppScreen.timer),
                  isSelected: navVM.currentScreen == AppScreen.timer,
                  closeAfterTap: false,
                ),
                _buildDrawerItem(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  onTap: () => context.read<ThemeViewModel>().toggle(),
                  closeAfterTap: false,
                ),
                _buildDrawerItem(
                  icon: Icons.list,
                  title: 'List View',
                  onTap: () => navVM.navigateTo(AppScreen.listView),
                  isSelected: navVM.currentScreen == AppScreen.listView,
                  closeAfterTap: false,
                ),
                _buildDrawerItem(
                  icon: Icons.photo_library,
                  title: 'Gallery',
                  onTap: () => navVM.navigateTo(AppScreen.gallery),
                  isSelected: navVM.currentScreen == AppScreen.gallery,
                  closeAfterTap: false,
                ),
                _buildDrawerItem(
                  icon: Icons.network_check,
                  title: 'Network Service',
                  onTap: () => navVM.navigateTo(AppScreen.network),
                  isSelected: navVM.currentScreen == AppScreen.network,
                  closeAfterTap: false,
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  onTap: () {
                    final loc = context.read<LocalizationViewModel>();
                    final isArabic = loc.locale.languageCode == 'ar';
                    loc.changeLanguage(isArabic ? 'en' : 'ar');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () => _showLogoutDialog(context, authVM),
                  closeAfterTap: false,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  // ---------- Drawer (for narrow screens) ----------
  Widget _buildDrawer(BuildContext context, AuthViewModel authVM,
      NavigationViewModel navVM, TimerViewModel timerVM) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    authVM.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 24, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  authVM.username ?? 'User',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  'Total time: ${timerVM.formattedTotalTime}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.timer,
            title: 'Timer',
            onTap: () {
              navVM.navigateTo(AppScreen.timer);
            },
            isSelected: navVM.currentScreen == AppScreen.timer,
          ),
          _buildDrawerItem(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            onTap: () => context.read<ThemeViewModel>().toggle(),
          ),
          _buildDrawerItem(
            icon: Icons.list,
            title: 'List View',
            onTap: () {
              navVM.navigateTo(AppScreen.listView);
            },
            isSelected: navVM.currentScreen == AppScreen.listView,
          ),
          _buildDrawerItem(
            icon: Icons.photo_library,
            title: 'Gallery',
            onTap: () {
              navVM.navigateTo(AppScreen.gallery);
            },
            isSelected: navVM.currentScreen == AppScreen.gallery,
          ),
          _buildDrawerItem(
            icon: Icons.network_check,
            title: 'Network Service',
            onTap: () {
              navVM.navigateTo(AppScreen.network);
            },
            isSelected: navVM.currentScreen == AppScreen.network,
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            onTap: () {
              final loc = context.read<LocalizationViewModel>();
              final isArabic = loc.locale.languageCode == 'ar';
              loc.changeLanguage(isArabic ? 'en' : 'ar');
              Navigator.pop(context);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _showLogoutDialog(context, authVM),
          ),
        ],
      ),
    );
  }

  // Shared list tile
  ListTile _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool closeAfterTap = true, // true for Drawer; false for fixed sidebar
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue.withOpacity(0.08) : null,
      onTap: () {
        onTap();
        if (closeAfterTap && Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }
      },
    );
  }

  // Content
  Widget _buildCurrentScreen(AppScreen screen) {
    switch (screen) {
      case AppScreen.timer:
        return const TimerPage();
      case AppScreen.listView:
        return const TodoListPage();
      case AppScreen.gallery:
        return const GalleryScreen();
      case AppScreen.network:
        return const CloudPage();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel authVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
            'Are you sure you want to logout? This will clear all saved data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(context, authVM);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, AuthViewModel authVM) async {
    // Clear all data from view models
    final timerVM = Provider.of<TimerViewModel>(context, listen: false);
    final galleryVM = Provider.of<GalleryViewModel>(context, listen: false);
    final networkVM = Provider.of<NetworkViewModel>(context, listen: false);

    await timerVM.clearData();
    galleryVM.clearImage();
    await networkVM.clearData();
    await authVM.logout();

    // Navigate to login screen
    Navigator.pushReplacementNamed(context, '/login');
  }
}
