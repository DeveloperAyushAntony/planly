import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.read<Connectivity>();
    return StreamBuilder<List<ConnectivityResult>>(
      stream: connectivity.onConnectivityChanged,
      builder: (context, snapshot) {
        final connectivityResult = snapshot.data;
        final isOffline =
            connectivityResult != null &&
            connectivityResult.contains(ConnectivityResult.none);

        if (isOffline) {
          return Container(
            color: Colors.redAccent,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'You are offline. Showing cached tasks.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
