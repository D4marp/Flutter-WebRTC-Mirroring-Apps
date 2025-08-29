import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service_advanced.dart';

class WebRTCViewerScreenAdvanced extends StatefulWidget {
  const WebRTCViewerScreenAdvanced({super.key});

  @override
  State<WebRTCViewerScreenAdvanced> createState() => _WebRTCViewerScreenAdvancedState();
}

class _WebRTCViewerScreenAdvancedState extends State<WebRTCViewerScreenAdvanced> {
  late WebRTCServiceAdvanced _webrtcService;
  RTCVideoRenderer? _remoteRenderer;
  bool _isConnecting = false;
  bool _showStats = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  StreamQuality _selectedQuality = StreamQuality.high;

  @override
  void initState() {
    super.initState();
    _webrtcService = WebRTCServiceAdvanced();
    _initializeRenderer();
    _initializeWebRTC();
  }

  Future<void> _initializeRenderer() async {
    _remoteRenderer = RTCVideoRenderer();
    await _remoteRenderer!.initialize();
  }

  Future<void> _initializeWebRTC() async {
    try {
      setState(() => _isConnecting = true);
      
      await _webrtcService.initialize(
        mode: WebRTCMode.viewer,
        quality: StreamQuality.high,
      );
      
      _webrtcService.addListener(_onWebRTCUpdate);
      setState(() => _isConnecting = false);
      
    } catch (e) {
      setState(() => _isConnecting = false);
      _showErrorDialog('Initialization Error', e.toString());
    }
  }

  void _onWebRTCUpdate() {
    if (mounted) {
      setState(() {});
      
      // Update remote renderer when stream is available
      if (_webrtcService.remoteStream != null && _remoteRenderer != null) {
        _remoteRenderer!.srcObject = _webrtcService.remoteStream;
      }
    }
  }

  Future<void> _connectToSource() async {
    try {
      setState(() => _isConnecting = true);
      
      // In real implementation, this would show device discovery
      // For now, we'll use a placeholder device ID
      await _webrtcService.connectToDevice('source_device_123');
      
      setState(() => _isConnecting = false);
      
    } catch (e) {
      setState(() => _isConnecting = false);
      _showErrorDialog('Connection Error', e.toString());
    }
  }

  void _disconnect() async {
    try {
      await _webrtcService.disconnect();
    } catch (e) {
      _showErrorDialog('Disconnect Error', e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WebRTC Ultra-Fast Viewer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Connection Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getConnectionStatusColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getConnectionStatusText(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Connect/Disconnect Button
          if (_webrtcService.connectionState == WebRTCConnectionState.disconnected)
            ElevatedButton.icon(
              onPressed: _isConnecting ? null : _connectToSource,
              icon: _isConnecting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cast),
              label: Text(_isConnecting ? 'Connecting...' : 'Connect to Source'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            
          if (_webrtcService.connectionState == WebRTCConnectionState.connected)
            ElevatedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.cast_connected),
              label: const Text('Disconnect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            
          const SizedBox(height: 12),
          
          // Quality Controls
          if (_webrtcService.connectionState == WebRTCConnectionState.connected) ...[
            const Text(
              'Stream Quality',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SegmentedButton<StreamQuality>(
              selected: {_selectedQuality},
              onSelectionChanged: (Set<StreamQuality> selection) {
                setState(() {
                  _selectedQuality = selection.first;
                });
                _webrtcService.setStreamQuality(selection.first);
              },
              segments: const [
                ButtonSegment(
                  value: StreamQuality.low,
                  label: Text('Low', style: TextStyle(fontSize: 10)),
                ),
                ButtonSegment(
                  value: StreamQuality.medium,
                  label: Text('Med', style: TextStyle(fontSize: 10)),
                ),
                ButtonSegment(
                  value: StreamQuality.high,
                  label: Text('High', style: TextStyle(fontSize: 10)),
                ),
                ButtonSegment(
                  value: StreamQuality.ultra,
                  label: Text('Ultra', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Advanced Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Fullscreen Toggle
                IconButton(
                  onPressed: _toggleFullscreen,
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  tooltip: 'Toggle Fullscreen',
                ),
                
                // Stats Toggle
                IconButton(
                  onPressed: () => setState(() => _showStats = !_showStats),
                  icon: Icon(
                    _showStats ? Icons.analytics : Icons.analytics_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Show Stats',
                ),
                
                // Controls Toggle
                IconButton(
                  onPressed: () => setState(() => _showControls = !_showControls),
                  icon: Icon(
                    _showControls ? Icons.settings : Icons.settings_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Toggle Controls',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceStats() {
    if (!_showStats || _webrtcService.connectionState != WebRTCConnectionState.connected) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatRow('Frame Rate', '${_webrtcService.frameRate} fps'),
          _buildStatRow('Bitrate', '${(_webrtcService.bitrate / 1000000).toStringAsFixed(1)} Mbps'),
          _buildStatRow('Latency', '${_webrtcService.latency} ms'),
          _buildStatRow('Packet Loss', '${_webrtcService.packetLoss.toStringAsFixed(2)}%'),
          _buildStatRow('Jitter', '${_webrtcService.jitter} ms'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.network_check,
                size: 16,
                color: _getNetworkQualityColor(),
              ),
              const SizedBox(width: 4),
              Text(
                _getNetworkQualityText(),
                style: TextStyle(
                  color: _getNetworkQualityColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Advanced Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          
          // Auto Adjust Quality
          SwitchListTile(
            title: const Text('Auto Adjust Quality', style: TextStyle(color: Colors.white, fontSize: 12)),
            subtitle: const Text('Automatically adjust quality based on network', style: TextStyle(color: Colors.white70, fontSize: 10)),
            value: _webrtcService.autoAdjustQuality,
            onChanged: _webrtcService.setAutoAdjustQuality,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          
          // Hardware Acceleration
          SwitchListTile(
            title: const Text('Hardware Acceleration', style: TextStyle(color: Colors.white, fontSize: 12)),
            subtitle: const Text('Use GPU acceleration for better performance', style: TextStyle(color: Colors.white70, fontSize: 10)),
            value: _webrtcService.hardwareAcceleration,
            onChanged: _webrtcService.setHardwareAcceleration,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          
          // Low Latency Mode
          SwitchListTile(
            title: const Text('Low Latency Mode', style: TextStyle(color: Colors.white, fontSize: 12)),
            subtitle: const Text('Optimize for minimal delay', style: TextStyle(color: Colors.white70, fontSize: 10)),
            value: _webrtcService.lowLatencyMode,
            onChanged: _webrtcService.setLowLatencyMode,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Color _getConnectionStatusColor() {
    switch (_webrtcService.connectionState) {
      case WebRTCConnectionState.connected:
        return Colors.green;
      case WebRTCConnectionState.connecting:
        return Colors.orange;
      case WebRTCConnectionState.error:
        return Colors.red;
      case WebRTCConnectionState.disconnected:
        return Colors.grey;
    }
  }

  String _getConnectionStatusText() {
    switch (_webrtcService.connectionState) {
      case WebRTCConnectionState.connected:
        return 'CONNECTED';
      case WebRTCConnectionState.connecting:
        return 'CONNECTING';
      case WebRTCConnectionState.error:
        return 'ERROR';
      case WebRTCConnectionState.disconnected:
        return 'DISCONNECTED';
    }
  }

  Color _getNetworkQualityColor() {
    if (_webrtcService.latency < 50 && _webrtcService.packetLoss < 1.0) {
      return Colors.green;
    } else if (_webrtcService.latency < 150 && _webrtcService.packetLoss < 3.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getNetworkQualityText() {
    if (_webrtcService.latency < 50 && _webrtcService.packetLoss < 1.0) {
      return 'Excellent';
    } else if (_webrtcService.latency < 150 && _webrtcService.packetLoss < 3.0) {
      return 'Good';
    } else {
      return 'Poor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('WebRTC Ultra-Fast Viewer'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.assessment : Icons.assessment_outlined),
            onPressed: () => setState(() => _showStats = !_showStats),
            tooltip: 'Toggle Performance Stats',
          ),
          IconButton(
            icon: Icon(_showControls ? Icons.settings : Icons.settings_outlined),
            onPressed: () => setState(() => _showControls = !_showControls),
            tooltip: 'Toggle Controls',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main video view
          Center(
            child: _webrtcService.remoteStream != null && _remoteRenderer != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: RTCVideoView(
                      _remoteRenderer!,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: false,
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[900]!, Colors.grey[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cast,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _webrtcService.connectionState == WebRTCConnectionState.connecting
                              ? 'Connecting to source...'
                              : 'No video stream',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                        if (_webrtcService.connectionState == WebRTCConnectionState.connecting) ...[
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(),
                        ],
                      ],
                    ),
                  ),
          ),
          
          // Performance Stats Overlay
          if (_showStats)
            Positioned(
              top: 16,
              right: 16,
              child: _buildPerformanceStats(),
            ),
          
          // Connection Controls
          if (_showControls && _webrtcService.connectionState != WebRTCConnectionState.connected)
            Center(
              child: _buildConnectionControls(),
            ),
          
          // Advanced Controls
          if (_showControls && _webrtcService.connectionState == WebRTCConnectionState.connected)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildAdvancedControls(),
            ),
        ],
      ),
      floatingActionButton: _webrtcService.connectionState == WebRTCConnectionState.connected
          ? FloatingActionButton(
              onPressed: () => _webrtcService.disconnect(),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Restart Connection',
            )
          : null,
    );
  }
  
  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    // Add fullscreen logic here if needed
  }

  @override
  void dispose() {
    _webrtcService.removeListener(_onWebRTCUpdate);
    _webrtcService.dispose();
    _remoteRenderer?.dispose();
    super.dispose();
  }
}
