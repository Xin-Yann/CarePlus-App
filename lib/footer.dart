import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

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
              _FooterItem(
                imagePath: 'asset/image/home.png',
                label: 'Home',
                route: '/home',
                width: 30,
                height: 30,
              ),
              _FooterItem(
                imagePath: 'asset/image/drug.png',
                label: 'Product',
                route: '/product_category',
                width: 30,
                height: 30,
              ),
              _FooterItem(
                imagePath: 'asset/image/messenger.png',
                label: 'Message',
                route: '/chat_with_doctor',
                width: 26,
                height: 26,
              ),
              _FooterItem(
                imagePath: 'asset/image/user.png',
                label: 'Account',
                route: '/profile',
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

class _FooterItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final String route;
  final double width;
  final double height;

  const _FooterItem({
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
