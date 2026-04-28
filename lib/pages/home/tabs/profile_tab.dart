import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/routes/app_routes.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['我喜欢', '本地/云盘', '已购买', '全部'];

  // Mock data
  final String _userName = 'Oliver Nicolai';
  final String _location = 'Singapore, SG';
  final int _followers = 13;
  final int _following = 7;
  final int _activities = 109;
  final int _saved = 4;

  final List<Map<String, dynamic>> _feedItems = [
    {
      'avatar': 'https://i.pravatar.cc/100?img=1',
      'name': 'Sarah Miller',
      'date': 'Sep 1',
      'activity': 'Hiking',
      'time': '2h ago',
    },
    {
      'avatar': 'https://i.pravatar.cc/100?img=2',
      'name': 'John Doe',
      'date': 'Aug 28',
      'activity': 'Cycling',
      'time': '1d ago',
    },
    {
      'avatar': 'https://i.pravatar.cc/100?img=3',
      'name': 'Emma Wilson',
      'date': 'Aug 25',
      'activity': 'Swimming',
      'time': '3d ago',
    },
    {
      'avatar': 'https://i.pravatar.cc/100?img=4',
      'name': 'Mike Chen',
      'date': 'Aug 20',
      'activity': 'Running',
      'time': '1w ago',
    },
    {
      'avatar': 'https://i.pravatar.cc/100?img=5',
      'name': 'Lisa Park',
      'date': 'Aug 15',
      'activity': 'Yoga',
      'time': '2w ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2D5016);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Get.toNamed(Routes.settings);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with plus badge
            Container(
              margin: const EdgeInsets.only(left: 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/200?img=10'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Plus badge
                  Positioned(
                    bottom: 0,
                    right: -4,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.only(left: 16),
              child: Text(
                _userName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Location
            Container(
              margin: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _location,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // User info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatText('$_followers Followers', isDark),
                  _buildDivider(isDark),
                  _buildStatText('$_following Following', isDark),
                  Expanded(child: Container()),
                  SizedBox(
                    width: 140,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '编辑资料',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats cards row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      context,
                      icon: Icons.analytics_outlined,
                      title: '$_activities 累计听歌',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsCard(
                      context,
                      icon: Icons.bookmark_border,
                      title: '$_saved Saved',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tab navigation
            _buildTabNavigation(context, isDark),

            const SizedBox(height: 8),

            // Feed list
            ..._feedItems.map((item) => _buildFeedItem(context, item, isDark)),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatText(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white70 : Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 16,
      color: isDark ? Colors.white24 : Colors.grey[400],
    );
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: isDark ? Colors.white38 : Colors.grey[500],
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation(BuildContext context, bool isDark) {
    const primaryColor = Color(0xFF2D5016);
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTabIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _tabs[index],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? primaryColor
                                : (isDark ? Colors.white54 : Colors.grey[500]),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2,
                          width: isSelected ? 24 : 0,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
            onPressed: () => _showAllTabs(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey[200]!,
                width: 1,
              ),
              image: DecorationImage(
                image: NetworkImage(item['avatar']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['date']} · ${item['activity']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            item['time'],
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllTabs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ..._tabs.map(
              (tab) => ListTile(
                title: Text(tab),
                trailing: _tabs.indexOf(tab) == _selectedTabIndex
                    ? const Icon(Icons.check, color: Color(0xFF2D5016))
                    : null,
                onTap: () {
                  setState(() => _selectedTabIndex = _tabs.indexOf(tab));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
