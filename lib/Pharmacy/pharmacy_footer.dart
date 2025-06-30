import 'package:careplusapp/Pharmacy/pharmacy_history.dart';
import 'package:careplusapp/Pharmacy/pharmacy_home.dart';
import 'package:careplusapp/Pharmacy/pharmacy_profile.dart';
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
              children: [
                _PharmacyFooterItem(
                  imagePath: 'asset/image/home.png',
                  label: 'Home',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => PharmacyHome()),
                    );
                  },
                  //route: '/pharmacy_home',
                  width: 30,
                  height: 30,
                ),
               _PharmacyFooterItem(
                  imagePath: 'asset/image/order.png',
                  label: 'Orders',
                  //route: '/',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => PharmacyHistory()),
                    );
                  },
                  width: 31,
                  height: 31,
                ),
                // _PharmacyFooterItem(
                //   imagePath: 'asset/image/order_history.png',
                //   label: 'Transaction',
                //
                //   width: 31,
                //   height: 31,
                // ),
                _PharmacyFooterItem(
                  imagePath: 'asset/image/user.png',
                  label: 'Account',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => PharmacyProfile()),
                    );
                  },
                  //route: '/pharmacy_profile',
                  width: 30,
                  height: 30,
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
  //final String route;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _PharmacyFooterItem({
    required this.imagePath,
    required this.label,
    // required this.route,
    this.width = 24.0,
    this.height = 24.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        // onTap: () {
        //   Navigator.pushReplacementNamed(context, route);
        // },
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
