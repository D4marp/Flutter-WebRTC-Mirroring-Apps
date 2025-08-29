import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class WebRTCViewerScreen extends StatefulWidget {
  const WebRTCViewerScreen({Key? key}) : super(key: key);

  @override
  State<WebRTCViewerScreen> createState() => _WebRTCViewerScreenState();
}

class _WebRTCViewerScreenState extends State<WebRTCViewerScreen> {
  final WebRTCService _webrtcService = WebRTCService();
  List<Map<String, dynamic>> _availableSources = [];
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectionStatus = 'Initializing...';
  Map<String, dynamic>? _connectionStats;

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
        _connectionStatus = 'Ready to discover sources';
      });
      
      // Start discovery
      await _webrtcService.startAsViewer();
      
    } catch (e) {
      setState(() {
        _connectionStatus = 'Initialization failed: $e';
      });
    }
  }

  void _handleWebRTCEvent(Map<String, dynamic> event) {
    setState(() {
      switch (event['type']) {
        case 'viewer_started':
          _connectionStatus = event['message'];
          break;
        case 'source_discovered':
          // Add discovered source to list
          final sourceInfo = {
            'ip': event['sourceIP'],
            'name': event['sourceName'] ?? 'Unknown Device',
            'timestamp': event['timestamp'],
          };
          
          // Remove duplicates and add
          _availableSources.removeWhere((s) => s['ip'] == sourceInfo['ip']);
          _availableSources.add(sourceInfo);
          
          _connectionStatus = 'Found ${_availableSources.length} source(s)';
          break;
        case 'connecting_to_source':
          _isConnecting = true;
          _connectionStatus = 'Connecting to ${event['sourceIP']}...';
          break;
        case 'connection_state_changed':
          _isConnected = event['connected'];
          if (_isConnected) {
            _connectionStatus = 'Connected - WebRTC stream active';
          } else {
            _connectionStatus = 'Connection lost';
          }
          _isConnecting = false;
          break;
        case 'remote_stream_added':
          _connectionStatus = 'Receiving video stream';
          break;
        case 'error':
          _connectionStatus = 'Error: ${event['message']}';
          _isConnecting = false;
          break;
      }
    });
  }

  Future<void> _connectToSource(String sourceIP) async {
    if (_isConnecting) return;
    
    setState(() {
      _isConnecting = true;
    });
    
    try {
      await _webrtcService.connectToSource(sourceIP);
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: $e';
        _isConnecting = false;
      });
    }
  }

  Future<void> _refreshSources() async {
    setState(() {
      _availableSources.clear();
      _connectionStatus = 'Searching for sources...';
    });
    
    try {
      // Restart discovery
      await _webrtcService.startAsViewer();
    } catch (e) {
      setState(() {
        _connectionStatus = 'Refresh failed: $e';
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
        title: const Text('WebRTC Viewer'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshSources,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Sources',
          ),
          IconButton(
            onPressed: _getConnectionStats,
            icon: const Icon(Icons.analytics),
            tooltip: 'Connection Stats',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isConnected 
                  ? Colors.green.shade50 
                  : _isConnecting 
                      ? Colors.orange.shade50 
                      : Colors.blue.shade50,
              border: Border.all(
                color: _isConnected 
                    ? Colors.green 
                    : _isConnecting 
                        ? Colors.orange 
                        : Colors.blue,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isConnected 
                          ? Icons.video_call 
                          : _isConnecting 
                              ? Icons.connecting_airports 
                              : Icons.search,
                      color: _isConnected 
                          ? Colors.green 
                          : _isConnecting 
                              ? Colors.orange 
                              : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _connectionStatus,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_isConnecting)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          
          // Video Renderer
          if (_isConnected)
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(
                    _webrtcService.remoteRenderer!,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ),
                ),
              ),
            ),
          
          // Available Sources
          Expanded(
            flex: _isConnected ? 2 : 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Sources (${_availableSources.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _availableSources.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.devices_other,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No sources found',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Make sure source device is broadcasting',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _availableSources.length,
                            itemBuilder: (context, index) {
                              final source = _availableSources[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.cast,
                                    color: Colors.blue,
                                  ),
                                  title: Text(source['name']),
                                  subtitle: Text('IP: ${source['ip']}'),
                                  trailing: _isConnecting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.arrow_forward_ios),
                                  onTap: () => _connectToSource(source['ip']),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // Connection Stats
          if (_connectionStats != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
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
                    'Local IP: ${_connectionStats!['localIP']}\n'
                    'Stats Count: ${_connectionStats!['statsCount']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshSources,
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
