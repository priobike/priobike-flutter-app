import 'package:flutter/material.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String headerTitle;
  SettingsSectionHeader(this.headerTitle);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Text(
        headerTitle,
        style: TextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
