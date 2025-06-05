import 'package:flutter/material.dart';

class PharmacyFooter extends StatelessWidget {
  const PharmacyFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 80,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _PharmacyFooterItem(
                  imagePath: 'asset/image/home.png',
                  label: 'Home',
                  route: '/pharmacy_home',
                  width: 30,
                  height: 30,
                ),
                _PharmacyFooterItem(
                  imagePath: 'asset/image/prescription.png',
                  label: 'E-Prescription',
                  route: '/',
                  width: 30,
                  height: 30,
                ),
                _PharmacyFooterItem(
                  imagePath: 'asset/image/messenger.png',
                  label: 'Chat',
                  route: '/',
                  width: 26,
                  height: 26,
                ),
                _PharmacyFooterItem(
                  imagePath: 'asset/image/user.png',
                  label: 'Account',
                  route: '/pharmacy_profile',
                  width: 26,
                  height: 26,
                ),
              ],
            )
        ),
      ),
    );
  }
}

class _PharmacyFooterItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final String route;
  final double width;
  final double height;

  const _PharmacyFooterItem({
    required this.imagePath,
    required this.label,
    required this.route,
    this.width = 24.0,
    this.height = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacementNamed(context, route);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: const Color(0xFF6B4518), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
