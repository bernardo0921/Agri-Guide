import 'package:flutter/material.dart';


// App Drawer
class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Farmer John',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'john@harvestanalytics.com',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          // Menu Items
          ListTile(
            leading: Icon(
              Icons.home,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Home',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.store,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Marketplace',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.shopping_cart,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'My Orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.person,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.help,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Help & Support',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: Text(
              'Logout',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                  ),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}