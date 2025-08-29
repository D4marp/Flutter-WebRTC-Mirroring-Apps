import 'package:flutter/material.dart';
import '../services/webrtc_service.dart';

class WebRTCSourceScreen extends StatefulWidget {
  const WebRTCSourceScreen({Key? key}) : super(key: key);

  @override
  State<WebRTCSourceScreen> createState() => _WebRTCSourceScreenState();
}

class _WebRTCSource                      )).toList(),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard('Viewers', _viewerCount.toString(), Icons.people),
                        _buildStatCard('Quality', _networkQuality, Icons.signal_cellular_alt),
                        _buildStatCard('Data', '${_dataTransferred}MB', Icons.data_usage),
                      ],
                    ),
                    
                    // Advanced stats - collapsible
                    if (_showAdvancedStats) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard('CPU', '${_cpuUsage.toStringAsFixed(1)}%', Icons.memory),
                          _buildStatCard('Latency', '${_connectionStats?['latency'] ?? 0}ms', Icons.timer),
                          _buildStatCard('FPS', '${_connectionStats?['fps'] ?? 60}', Icons.speed),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
            ],tate extends State<WebRTCSourceScreen> {
  final WebRTCService _webrtcService = WebRTCService();
  bool _isSharing = false;
  bool _isStarting = false;
  String _status = 'Ready to start sharing';
  List<String> _connectedClients = [];
  Map<String, dynamic>? _connectionStats;
  bool _showAdvancedStats = false;
  
  // Performance tracking
  int _viewerCount = 0;
  String _networkQuality = 'Unknown';
  double _cpuUsage = 0.0;
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
          _status = 'WebRTC initialized';
          break;
        case 'source_started':
          _status = event['message'];
          break;
        case 'webrtc_screen_capture_started':
          _status = 'Screen capture started - Broadcasting...';
          break;
        case 'connection_state_changed':
          if (event['connected']) {
            _status = 'Client connected - Streaming active';
            if (event.containsKey('clientIP')) {
              final clientIP = event['clientIP'];
              if (!_connectedClients.contains(clientIP)) {
                _connectedClients.add(clientIP);
              }
            }
          } else {
            _status = 'Client disconnected';
            if (event.containsKey('clientIP')) {
              _connectedClients.remove(event['clientIP']);
            }
          }
          break;
        case 'service_stopped':
          _status = 'Sharing stopped';
          _isSharing = false;
          _connectedClients.clear();
          break;
        case 'error':
          _status = 'Error: ${event['message']}';
          _isStarting = false;
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
        _status = 'Screen sharing stopped';
      });
      
    } catch (e) {
      setState(() {
        _status = 'Error stopping sharing: $e';
      });
    }
  }

  Future<void> _getConnectionStats() async {
    try {
      final stats = await _webrtcService.getConnectionStats();
      setState(() {
        _connectionStats = stats;
      });
    } catch (e) {
      print('Error getting stats: $e');
    }
  }

  @override
  void dispose() {
    _webrtcService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC Source'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _getConnectionStats,
            icon: const Icon(Icons.analytics),
            tooltip: 'Connection Stats',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isSharing 
                    ? Colors.green.shade50 
                    : _isStarting 
                        ? Colors.orange.shade50 
                        : Colors.blue.shade50,
                border: Border.all(
                  color: _isSharing 
                      ? Colors.green 
                      : _isStarting 
                          ? Colors.orange 
                          : Colors.blue,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
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
                    color: _isSharing 
                        ? Colors.green 
                        : _isStarting 
                            ? Colors.orange 
                            : Colors.blue,
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
                      color: _isSharing 
                          ? Colors.green.shade700 
                          : _isStarting 
                              ? Colors.orange.shade700 
                              : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (_isStarting)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Connected Clients
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
                        'Connected Viewers (${_connectedClients.length})',
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
            
            const SizedBox(height: 24),
            
            // Control Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isStarting 
                    ? null 
                    : _isSharing 
                        ? _stopSharing 
                        : _startSharing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSharing ? Colors.red.shade600 : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isStarting 
                      ? 'Starting...' 
                      : _isSharing 
                          ? 'Stop Sharing' 
                          : 'Start Screen Sharing',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // WebRTC Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'WebRTC High-Performance Streaming',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Ultra-low latency peer-to-peer streaming\n'
                    '• Automatic quality adaptation\n'
                    '• NAT traversal with STUN servers\n'
                    '• Efficient bandwidth usage',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Connection Stats
            if (_connectionStats != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Statistics',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connected: ${_connectionStats!['connected']}\n'
                      'Is Source: ${_connectionStats!['isSource']}\n'
                      'Local IP: ${_connectionStats!['localIP']}\n'
                      'Stats Count: ${_connectionStats!['statsCount']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
