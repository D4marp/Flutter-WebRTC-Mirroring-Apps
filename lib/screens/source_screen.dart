import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mirroring_service.dart';
import '../services/network_service.dart';

class SourceScreen extends StatefulWidget {
  const SourceScreen({super.key});

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSource();
    });
  }

  Future<void> _initializeSource() async {
    final networkService = context.read<NetworkService>();
    await networkService.startAsSource();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Share Screen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<NetworkService, MirroringService>(
        builder: (context, networkService, mirroringService, child) {
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Status Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _getStatusColor(networkService, mirroringService).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(networkService, mirroringService),
                    size: 64,
                    color: _getStatusColor(networkService, mirroringService),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  _isStarted ? 'Screen Sharing Active' : 'Ready to Share',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Status
                Text(
                  _getStatusText(networkService, mirroringService),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Connection Info
                if (networkService.isConnected) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wifi, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Server IP Address:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          networkService.localIpAddress,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.screen_share, color: Colors.green[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Entire Screen Capture Ready\nShare this IP with viewer devices',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 🚀 DYNAMIC BROADCAST STATUS
                        const SizedBox(height: 12),
                        Consumer<NetworkService>(
                          builder: (context, service, child) {
                            final quality = service.networkQuality;
                            final rssi = service.rssi;
                            final linkSpeed = service.linkSpeed;
                            final broadcastInterval = service.broadcastInterval;
                            
                            if (quality != 'UNKNOWN') {
                              final qualityColor = quality == 'EXCELLENT' 
                                  ? Colors.green 
                                  : quality == 'GOOD' 
                                      ? Colors.blue 
                                      : quality == 'FAIR' 
                                          ? Colors.orange 
                                          : Colors.red;
                              
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: qualityColor[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: qualityColor[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.broadcast_on_personal, color: qualityColor[600], size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Broadcasting: $quality',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: qualityColor[700],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Signal: ${rssi.toInt()} dBm',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Speed: ${linkSpeed.toInt()} Mbps',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Auto-discovery every ${(broadcastInterval / 1000).toStringAsFixed(1)}s',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: qualityColor[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.broadcast_on_personal, color: Colors.grey[600], size: 16),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Broadcast discovery initializing...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        
                        // 🚀 SUPER APP STATUS PANEL 🚀
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple[700]!, Colors.indigo[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SUPER APP STATUS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'AI-Powered Intelligence Active',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Status indicators
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatusIndicator('🛡️', 'Ultra Stable', true),
                                  ),
                                  Expanded(
                                    child: _buildStatusIndicator('🧠', 'AI Learning', true),
                                  ),
                                  Expanded(
                                    child: _buildStatusIndicator('⚡', 'Turbo Ready', false),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        if (networkService.connectedClientIp.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.devices, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              const Text(
                                'Connected Client:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            networkService.connectedClientIp,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Screen Sharing Instructions
                if (!_isStarted && networkService.isConnected) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[700]),
                        const SizedBox(height: 8),
                        Text(
                          'Super Apps Screen Sharing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Start Sharing" and grant permission to capture entire screen. Your complete display will be shared in high quality.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Error Display
                if (networkService.errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Screen Sharing Error',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          networkService.errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => networkService.clearError(),
                          child: Text(
                            'Try Again',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Main Action Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _getButtonEnabled(networkService, mirroringService) 
                        ? () => _toggleEntireScreenSharing(networkService)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isStarted ? Colors.red[600] : Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isStarted ? Icons.stop_screen_share : Icons.screen_share),
                        const SizedBox(width: 8),
                        Text(
                          _isStarted ? 'Stop Entire Screen' : 'Share Entire Screen',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Secondary Button
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _disconnect(networkService, mirroringService),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                
                // Performance Stats
                if (_isStarted) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.speed, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Streaming Performance',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPerformanceItem(
                              'FPS Out',
                              '${networkService.stats.framesSentPerSec}',
                              Icons.upload,
                            ),
                            _buildPerformanceItem(
                              'Clients',
                              '${networkService.stats.connectedClients}',
                              Icons.devices,
                            ),
                            _buildPerformanceItem(
                              'Status',
                              _isStarted ? 'Active' : 'Idle',
                              _isStarted ? Icons.play_circle : Icons.pause_circle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Instructions
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Instructions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Share your IP address with the viewer\n'
                        '2. Wait for them to connect\n'
                        '3. Press "Start Sharing" to begin\n'
                        '4. Grant screen capture permission when prompted',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ), // Column
          ), // Container
        ); // SingleChildScrollView
        }, // builder
      ), // Consumer2
    );
  }

  Color _getStatusColor(NetworkService networkService, MirroringService mirroringService) {
    if (networkService.status == ConnectionStatus.error) return Colors.red;
    if (_isStarted && mirroringService.isCapturing) return Colors.green;
    if (networkService.isConnected) return Colors.blue;
    return Colors.orange;
  }

  IconData _getStatusIcon(NetworkService networkService, MirroringService mirroringService) {
    if (networkService.status == ConnectionStatus.error) return Icons.error;
    if (_isStarted && mirroringService.isCapturing) return Icons.cast_connected;
    if (networkService.isConnected) return Icons.wifi;
    return Icons.wifi_off;
  }

  String _getStatusText(NetworkService networkService, MirroringService mirroringService) {
    if (networkService.status == ConnectionStatus.error) {
      return 'Error: ${networkService.errorMessage}';
    }
    if (_isStarted && mirroringService.isCapturing) {
      return 'Your screen is being shared';
    }
    if (networkService.connectedClientIp.isNotEmpty) {
      return 'Client connected - Ready to share';
    }
    if (networkService.isConnected) {
      return 'Waiting for client to connect...';
    }
    return 'Setting up server...';
  }

  bool _getButtonEnabled(NetworkService networkService, MirroringService mirroringService) {
    if (_isStarted) return true; // Always allow stopping
    return networkService.isConnected && networkService.connectedClientIp.isNotEmpty;
  }

  Future<void> _toggleEntireScreenSharing(NetworkService networkService) async {
    if (_isStarted) {
      // Stop entire screen sharing
      try {
        await networkService.stopScreenCapture();
        setState(() {
          _isStarted = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entire screen sharing stopped'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error stopping screen sharing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Start entire screen sharing
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Requesting screen capture permission...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        await networkService.startScreenCapture();
        setState(() {
          _isStarted = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screen capture permission granted! Starting entire screen capture...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isStarted = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start screen capture: $e\n\nPlease ensure:\n• App has screen recording permission\n• No other apps are using screen capture'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _disconnect(NetworkService networkService, MirroringService mirroringService) async {
    if (_isStarted) {
      await mirroringService.stopScreenCapture();
      setState(() {
        _isStarted = false;
      });
    }
    await networkService.disconnect();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildPerformanceItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusIndicator(String emoji, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 16,
              color: isActive ? Colors.white : Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
