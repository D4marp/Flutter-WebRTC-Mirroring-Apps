import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/webrtc_service_advanced.dart';
import 'webrtc_source_screen_fixed.dart';
import 'webrtc_viewer_screen_advanced.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: Consumer<WebRTCServiceAdvanced>(
        builder: (context, webrtcService, child) {
          return CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0F1419),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'WebRTC MirrorLink Pro',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A73E8),
                          Color(0xFF4285F4),
                          Color(0xFF34A853),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 100,
                          right: 20,
                          child: Icon(
                            Icons.cast_connected,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Text(
                            'Ultra-Fast WebRTC Streaming',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Connection Status
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2328),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getConnectionStatusColor(webrtcService.connectionState),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getConnectionStatusColor(webrtcService.connectionState),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getConnectionStatusText(webrtcService.connectionState),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.wifi,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ),
                      if (webrtcService.connectionState == WebRTCConnectionState.connected) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.speed,
                                color: Color(0xFF34A853),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Connected - Ultra Low Latency',
                                style: TextStyle(
                                  color: const Color(0xFF34A853),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Main Action Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildListDelegate([
                    // Share Screen Card
                    _buildActionCard(
                      context,
                      title: 'Share Screen',
                      subtitle: 'Share your screen via WebRTC',
                      icon: Icons.screen_share,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
                      ),
                      onTap: () => _navigateToWebRTCSource(context),
                    ),

                    // View Screen Card
                    _buildActionCard(
                      context,
                      title: 'View Screen',
                      subtitle: 'Connect to shared screen',
                      icon: Icons.cast,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
                      ),
                      onTap: () => _navigateToWebRTCViewer(context),
                    ),
                  ]),
                ),
              ),

              // WebRTC Features Section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WebRTC Features',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Feature List
                      ..._buildFeatureList(),
                    ],
                  ),
                ),
              ),

              // Connection Guide
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2328),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF4285F4),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Quick Start Guide',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildGuideStep('1', 'Ensure both devices are on the same WiFi network'),
                      _buildGuideStep('2', 'One device chooses "Share Screen"'),
                      _buildGuideStep('3', 'Other device chooses "View Screen"'),
                      _buildGuideStep('4', 'Devices will auto-discover via WebRTC signaling'),
                      _buildGuideStep('5', 'Enjoy ultra-low latency screen sharing!'),
                    ],
                  ),
                ),
              ),

              // Bottom Spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getConnectionStatusColor(WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.connected:
        return const Color(0xFF34A853);
      case WebRTCConnectionState.connecting:
        return const Color(0xFFFFA726);
      case WebRTCConnectionState.error:
        return const Color(0xFFEA4335);
      case WebRTCConnectionState.disconnected:
      default:
        return const Color(0xFF9AA0A6);
    }
  }

  String _getConnectionStatusText(WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.connected:
        return 'Connected';
      case WebRTCConnectionState.connecting:
        return 'Connecting...';
      case WebRTCConnectionState.error:
        return 'Connection Failed';
      case WebRTCConnectionState.disconnected:
      default:
        return 'Ready to Connect';
    }
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeatureList() {
    final features = [
      {'icon': Icons.speed, 'title': 'Ultra Low Latency', 'desc': 'Real-time streaming with WebRTC'},
      {'icon': Icons.security, 'title': 'Secure P2P', 'desc': 'End-to-end encrypted connections'},
      {'icon': Icons.auto_awesome, 'title': 'Adaptive Quality', 'desc': 'Auto-adjusts based on network'},
      {'icon': Icons.wifi, 'title': 'Auto Discovery', 'desc': 'Automatic device discovery on WiFi'},
    ];

    return features.map((feature) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2328),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            feature['icon'] as IconData,
            color: const Color(0xFF4285F4),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  feature['desc'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )).toList();
  }

  Widget _buildGuideStep(String step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF4285F4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWebRTCSource(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebRTCSourceScreenFixed(),
      ),
    );
  }

  void _navigateToWebRTCViewer(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebRTCViewerScreenAdvanced(),
      ),
    );
  }
}
