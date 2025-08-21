// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:sunny_snuggles/features/weather/model/weather_bundle.dart';

class TomorrowPreviewCard extends StatelessWidget {
  const TomorrowPreviewCard({super.key, required this.bundle});
  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context) {
    final tomorrow = bundle.tomorrow;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.8),
            const Color(0xFF764ba2).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.network(
              _fixIconUrl(tomorrow.conditionIcon),
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tomorrow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${tomorrow.conditionText} • ${tomorrow.maxTempC.toInt()}°C',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  String _fixIconUrl(String icon) =>
      icon.startsWith('//') ? 'https:$icon' : icon;
}
