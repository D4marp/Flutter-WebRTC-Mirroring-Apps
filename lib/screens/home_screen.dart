import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';
import 'source_screen.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: Consumer<NetworkService>(
        builder: (context, networkService, child) {
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
                    'MirrorLink Apps',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1A73E8),
                          const Color(0xFF4285F4),
                          const Color(0xFF34A853),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 60,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1E293B),
                              const Color(0xFF334155),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cast_connected,
                              size: 48,
                              color: const Color(0xFF4285F4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Professional Screen Sharing',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'High-quality, real-time screen mirroring with enterprise-grade security',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                
                      // Mode Selection Title
                      Text(
                        'Choose Your Role',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Source Mode Card
                      _buildProfessionalModeCard(
                        context: context,
                        title: 'Share My Screen',
                        subtitle: 'Broadcast your device screen to viewers',
                        icon: Icons.mobile_screen_share,
                        gradientColors: [const Color(0xFF4285F4), const Color(0xFF1A73E8)],
                        iconColor: Colors.white,
                        onTap: () => _navigateToSourceMode(context, networkService),
                      ),
                      const SizedBox(height: 20),
                      
                      // Viewer Mode Card
                      _buildProfessionalModeCard(
                        context: context,
                        title: 'View Remote Screen',
                        subtitle: 'Connect to and watch another device',
                        icon: Icons.tv,
                        gradientColors: [const Color(0xFF34A853), const Color(0xFF0F9D58)],
                        iconColor: Colors.white,
                        onTap: () => _navigateToViewerMode(context, networkService),
                      ),
                      const SizedBox(height: 32),
                      
                      // Network Status Card
                      if (networkService.localIpAddress.isNotEmpty) ...[
                        _buildNetworkStatusCard(networkService),
                        const SizedBox(height: 24),
                      ],
                      
                      // Features Section
                      _buildFeaturesSection(),
                      const SizedBox(height: 24),
                      
                      // Debug info for connection issues
                      if (_isDebugMode() && networkService.errorMessage.isNotEmpty) ...[
                        _buildDebugSection(networkService),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfessionalModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard(NetworkService networkService) {
    final bool hasError = networkService.localIpAddress.contains('Error') || 
        networkService.localIpAddress.contains('Unknown') ||
        networkService.localIpAddress.contains('Check');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasError 
            ? [const Color(0xFF2D1B69), const Color(0xFF3730A3)]
            : [const Color(0xFF1E293B), const Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (hasError ? Colors.red : Colors.blue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasError ? Icons.wifi_off : Icons.wifi,
                  color: hasError ? Colors.red[300] : Colors.blue[300],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasError ? 'Connection Issue' : 'Ready to Connect',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your IP Address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      networkService.localIpAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (hasError ? Colors.red : Colors.green).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasError ? 'ERROR' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasError ? Colors.red[300] : Colors.green[300],
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isDebugMode()) ...[
            const SizedBox(height: 12),
            Text(
              'Status: ${networkService.status.name}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enterprise Features',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(Icons.security, 'End-to-End Encryption'),
          _buildFeatureItem(Icons.hd, 'HD Quality Streaming'),
          _buildFeatureItem(Icons.speed, 'Low Latency Connection'),
          _buildFeatureItem(Icons.devices, 'Multi-Device Support'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF4285F4),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection(NetworkService networkService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red[300], size: 16),
              const SizedBox(width: 8),
              Text(
                'Debug Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[200],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            networkService.errorMessage,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[100],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => networkService.clearError(),
            icon: Icon(Icons.clear, size: 14, color: Colors.red[200]),
            label: Text(
              'Clear Error',
              style: TextStyle(fontSize: 12, color: Colors.red[200]),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: Colors.red.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSourceMode(BuildContext context, NetworkService networkService) {
    networkService.setConnectionType(ConnectionType.source);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SourceScreen(),
      ),
    );
  }

  void _navigateToViewerMode(BuildContext context, NetworkService networkService) {
    networkService.setConnectionType(ConnectionType.viewer);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ViewerScreen(),
      ),
    );
  }

  // Debug & status helpers
  bool _isDebugMode() {
    return kDebugMode;
  }
}
