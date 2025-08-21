import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunny_snuggles/features/weather/viewmodel/weather_provider.dart';

class LocationInput extends ConsumerWidget {
  const LocationInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(locationProvider);
    final controller = TextEditingController(text: loc);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Enter city name or coordinates...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // Get current location logic
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onSubmitted: (val) {
          final v = val.trim();
          if (v.isNotEmpty) {
            ref.read(locationProvider.notifier).state = v;
            ref.refresh(weatherBundleProvider);
          }
        },
      ),
    );
  }
}
