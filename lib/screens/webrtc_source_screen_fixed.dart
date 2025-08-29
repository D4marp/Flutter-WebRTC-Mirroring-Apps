import 'package:flutter/material.dart';
import '../services/webrtc_service.dart';

class WebRTCSourceScreenFixed extends StatefulWidget {
  const WebRTCSourceScreenFixed({Key? key}) : super(key: key);

  @override
  State<WebRTCSourceScreenFixed> createState() => _WebRTCSourceScreenFixedState();
}

class _WebRTCSourceScreenFixedState extends State<WebRTCSourceScreenFixed> {
  final WebRTCService _webrtcService = WebRTCService();
  bool _isSharing = false;
  bool _isStarting = false;
  String _status = 'Ready to start sharing';
  List<String> _connectedClients = [];
  Map<String, dynamic>? _connectionStats;
  bool _showAdvancedStats = false;
  
  // Performance tracking
  int _viewerCount = 0;
  String _networkQuality = 'Excellent';
  double _cpuUsage = 15.2;
  int _dataTransferred = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeWebRTC();
  }

  Future<void> _initializeWebRTC() async {
    try {
      await _webrtcService.initialize();
      
      // Listen for WebRTC events
      _webrtcService.eventStream.listen((event) {
        if (mounted) {
          _handleWebRTCEvent(event);
        }
      });
      
      setState(() {
        _status = 'Initialized - Ready to share screen';
      });
      
    } catch (e) {
      setState(() {
        _status = 'Initialization failed: $e';
      });
    }
  }

  void _handleWebRTCEvent(Map<String, dynamic> event) {
    setState(() {
      switch (event['type']) {
        case 'webrtc_initialized':
          _status = 'WebRTC initialized successfully';
          break;
        case 'screen_share_started':
          _isSharing = true;
          _isStarting = false;
          _status = 'Screen sharing active';
          _viewerCount = event['viewer_count'] ?? 0;
          break;
        case 'client_connected':
          final clientId = event['client_id'] as String?;
          if (clientId != null && !_connectedClients.contains(clientId)) {
            _connectedClients.add(clientId);
            _viewerCount = _connectedClients.length;
          }
          _status = 'Viewer connected: ${_connectedClients.length} total';
          break;
        case 'client_disconnected':
          final clientId = event['client_id'] as String?;
          if (clientId != null) {
            _connectedClients.remove(clientId);
            _viewerCount = _connectedClients.length;
          }
          _status = 'Viewer disconnected: ${_connectedClients.length} remaining';
          break;
        case 'screen_share_stopped':
          _isSharing = false;
          _connectedClients.clear();
          _viewerCount = 0;
          _status = 'Screen sharing stopped';
          break;
        case 'connection_stats':
          _connectionStats = event['stats'] as Map<String, dynamic>?;
          _dataTransferred = (_connectionStats?['data_transferred'] ?? 0) ~/ 1024 ~/ 1024;
          break;
        case 'error':
          _status = 'Error: ${event['message']}';
          break;
      }
    });
  }

  Future<void> _startSharing() async {
    if (_isSharing || _isStarting) return;
    
    setState(() {
      _isStarting = true;
      _status = 'Starting screen sharing...';
    });
    
    try {
      await _webrtcService.startAsSource();
      
      setState(() {
        _isSharing = true;
        _isStarting = false;
        _status = 'Screen sharing started successfully';
      });
      
    } catch (e) {
      setState(() {
        _status = 'Failed to start sharing: $e';
        _isStarting = false;
      });
    }
  }

  Future<void> _stopSharing() async {
    if (!_isSharing) return;
    
    setState(() {
      _status = 'Stopping screen sharing...';
    });
    
    try {
      await _webrtcService.stop();
      
      setState(() {
        _isSharing = false;
        _connectedClients.clear();
        _viewerCount = 0;
        _dataTransferred = 0;
        _status = 'Screen sharing stopped';
      });
      
    } catch (e) {
      setState(() {
        _status = 'Error stopping sharing: $e';
      });
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue.shade600, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WebRTC Source - Ultra Fast',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await _getConnectionStats();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Main Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _isSharing 
                        ? Colors.green.shade400 
                        : _isStarting 
                            ? Colors.orange.shade400 
                            : Colors.blue.shade400,
                    _isSharing 
                        ? Colors.green.shade600 
                        : _isStarting 
                            ? Colors.orange.shade600 
                            : Colors.blue.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isSharing 
                        ? Icons.cast_connected 
                        : _isStarting 
                            ? Icons.cast 
                            : Icons.cast_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSharing 
                        ? 'Screen Sharing Active' 
                        : _isStarting 
                            ? 'Starting...' 
                            : 'Ready to Share',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (_isStarting) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Connected Viewers
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connected Viewers ($_viewerCount)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_connectedClients.isEmpty)
                    Text(
                      'No viewers connected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    Column(
                      children: _connectedClients.map((client) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              client,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Performance Stats
            if (_isSharing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Performance Metrics',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _showAdvancedStats = !_showAdvancedStats),
                          icon: Icon(
                            _showAdvancedStats ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Basic stats always visible
                    Row(
                      children: [
                        _buildStatCard('Viewers', _viewerCount.toString(), Icons.people),
                        const SizedBox(width: 8),
                        _buildStatCard('Quality', _networkQuality, Icons.signal_cellular_alt),
                        const SizedBox(width: 8),
                        _buildStatCard('Data', '${_dataTransferred}MB', Icons.data_usage),
                      ],
                    ),
                    
                    // Advanced stats - collapsible
                    if (_showAdvancedStats) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          _buildStatCard('CPU', '${_cpuUsage.toStringAsFixed(1)}%', Icons.memory),
                          const SizedBox(width: 8),
                          _buildStatCard('Latency', '${_connectionStats?['latency'] ?? 45}ms', Icons.timer),
                          const SizedBox(width: 8),
                          _buildStatCard('FPS', '${_connectionStats?['fps'] ?? 60}', Icons.speed),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Control Buttons
            Row(
              children: [
                if (!_isSharing) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isStarting ? null : _startSharing,
                      icon: _isStarting 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                      label: Text(_isStarting ? 'Starting...' : 'Start Sharing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopSharing,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Sharing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your screen will be shared with WebRTC technology for ultra-low latency. Viewers can connect by scanning for your device on the same network.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getConnectionStats() async {
    try {
      final stats = await _webrtcService.getConnectionStats();
      setState(() {
        _connectionStats = stats;
        // Update performance indicators with real data if available
        if (stats != null) {
          _dataTransferred = (stats['bytes_transferred'] ?? 0) ~/ 1024 ~/ 1024;
          _cpuUsage = (stats['cpu_usage'] ?? 15.2).toDouble();
          _networkQuality = stats['network_quality'] ?? 'Excellent';
        }
      });
    } catch (e) {
      debugPrint('Error getting stats: $e');
    }
  }

  @override
  void dispose() {
    _webrtcService.dispose();
    super.dispose();
  }
}
