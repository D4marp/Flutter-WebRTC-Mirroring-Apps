import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'dart:convert';

enum WebRTCMode { source, viewer }
enum WebRTCConnectionState { disconnected, connecting, connected, error }
enum StreamQuality { ultra, high, medium, low }

class WebRTCServiceAdvanced extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.example.mirroring_app/webrtc');
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCDataChannel? _dataChannel;
  
  WebRTCMode _mode = WebRTCMode.viewer;
  WebRTCConnectionState _connectionState = WebRTCConnectionState.disconnected;
  StreamQuality _streamQuality = StreamQuality.high;
  
  String? _remoteDeviceId;
  String? _localDeviceId;
  
  // Performance metrics
  int _frameRate = 60;
  int _bitrate = 3000000; // 3 Mbps for better quality
  int _latency = 0;
  double _packetLoss = 0.0;
  int _jitter = 0;
  
  // Advanced features
  bool _autoAdjustQuality = true;
  bool _hardwareAcceleration = true;
  bool _adaptiveBitrate = true;
  bool _lowLatencyMode = true;
  bool _echoCancellation = true;
  bool _noiseSuppression = true;
  
  // Connection quality tracking
  String _connectionQuality = 'excellent';
  int _totalBytesTransferred = 0;
  DateTime? _connectionStartTime;
  
  Timer? _metricsTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  
  // ICE Servers untuk konektivitas optimal
  final List<Map<String, String>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];
  
  // Getters
  WebRTCMode get mode => _mode;
  WebRTCConnectionState get connectionState => _connectionState;
  StreamQuality get streamQuality => _streamQuality;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  String? get remoteDeviceId => _remoteDeviceId;
  String? get localDeviceId => _localDeviceId;
  
  // Performance getters
  int get frameRate => _frameRate;
  int get bitrate => _bitrate;
  int get latency => _latency;
  double get packetLoss => _packetLoss;
  int get jitter => _jitter;
  
  // Feature getters
  bool get autoAdjustQuality => _autoAdjustQuality;
  bool get hardwareAcceleration => _hardwareAcceleration;
  bool get adaptiveBitrate => _adaptiveBitrate;
  bool get lowLatencyMode => _lowLatencyMode;
  bool get echoCancellation => _echoCancellation;
  bool get noiseSuppression => _noiseSuppression;
  
  // Quality metrics getters
  String get connectionQuality => _connectionQuality;
  int get totalBytesTransferred => _totalBytesTransferred;
  DateTime? get connectionStartTime => _connectionStartTime;
  int get reconnectAttempts => _reconnectAttempts;

  Future<void> initialize({
    required WebRTCMode mode,
    required StreamQuality quality,
  }) async {
    try {
      _mode = mode;
      _streamQuality = quality;
      _updateConnectionState(WebRTCConnectionState.connecting);

      // Initialize WebRTC
      await _initializePeerConnection();
      
      if (_mode == WebRTCMode.source) {
        await _initializeLocalStream();
      }
      
      // Start broadcasting device availability
      await _startBroadcast();
      
      // Start metrics collection
      _startMetricsCollection();
      
      _updateConnectionState(WebRTCConnectionState.disconnected);
      
    } catch (e) {
      debugPrint('WebRTC initialization error: $e');
      _updateConnectionState(WebRTCConnectionState.error);
      rethrow;
    }
  }

  Future<void> _initializePeerConnection() async {
    final config = {
      'iceServers': _iceServers,
      'iceCandidatePoolSize': 10,
    };

    _peerConnection = await createPeerConnection(config);
    
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _updateConnectionState(WebRTCConnectionState.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          _updateConnectionState(WebRTCConnectionState.connecting);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _updateConnectionState(WebRTCConnectionState.disconnected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _updateConnectionState(WebRTCConnectionState.error);
          break;
        default:
          break;
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // Send ICE candidate via signaling
      _sendSignalingMessage({
        'type': 'ice-candidate',
        'candidate': candidate.toMap(),
      });
    };

    if (_mode == WebRTCMode.viewer) {
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video') {
          _remoteStream = event.streams.first;
          notifyListeners();
        }
      };
    }
  }

  Future<void> _initializeLocalStream() async {
    if (_mode != WebRTCMode.source) return;

    try {
      // Initialize display media for screen sharing
      _localStream = await navigator.mediaDevices.getDisplayMedia({
        'video': {
          'width': _getVideoWidth(),
          'height': _getVideoHeight(),
          'frameRate': _frameRate,
        },
        'audio': true,
      });

      // Add stream to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

    } catch (e) {
      debugPrint('Local stream initialization error: $e');
      rethrow;
    }
  }

  int _getVideoWidth() {
    switch (_streamQuality) {
      case StreamQuality.ultra: return 3840; // 4K
      case StreamQuality.high: return 1920;  // 1080p
      case StreamQuality.medium: return 1280; // 720p
      case StreamQuality.low: return 854;     // 480p
    }
  }

  int _getVideoHeight() {
    switch (_streamQuality) {
      case StreamQuality.ultra: return 2160; // 4K
      case StreamQuality.high: return 1080;  // 1080p
      case StreamQuality.medium: return 720; // 720p
      case StreamQuality.low: return 480;     // 480p
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      _remoteDeviceId = deviceId;
      _updateConnectionState(WebRTCConnectionState.connecting);
      
      if (_mode == WebRTCMode.viewer) {
        // Create offer untuk viewer
        RTCSessionDescription offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        
        // Send offer via signaling
        await _sendSignalingMessage({
          'type': 'offer',
          'sdp': offer.toMap(),
          'targetDevice': deviceId,
        });
      }
      
    } catch (e) {
      debugPrint('Connection error: $e');
      _updateConnectionState(WebRTCConnectionState.error);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      _updateConnectionState(WebRTCConnectionState.disconnected);
      await _peerConnection?.close();
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      
      _stopMetricsCollection();
      _stopBroadcast();
      
    } catch (e) {
      debugPrint('Disconnect error: $e');
      _updateConnectionState(WebRTCConnectionState.error);
      rethrow;
    }
  }

  // ============ WebRTC Screen Capture Methods ============
  
  Future<bool> startWebRTCScreenCapture() async {
    try {
      debugPrint('Starting WebRTC screen capture...');
      
      // Set mode to source
      _mode = WebRTCMode.source;
      _updateConnectionState(WebRTCConnectionState.connecting);
      
      // Call native method to start screen capture
      final result = await _channel.invokeMethod('startWebRTCScreenCapture');
      
      if (result != null && result is Map) {
        final status = result['status'] as String?;
        if (status == 'started') {
          debugPrint('✓ WebRTC screen capture started successfully');
          
          // Start screen capture stream
          await _startScreenCaptureStream();
          
          _updateConnectionState(WebRTCConnectionState.connected);
          notifyListeners();
          return true;
        }
      }
      
      _updateConnectionState(WebRTCConnectionState.error);
      return false;
      
    } catch (e) {
      debugPrint('Error starting WebRTC screen capture: $e');
      _updateConnectionState(WebRTCConnectionState.error);
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> stopWebRTCScreenCapture() async {
    try {
      debugPrint('Stopping WebRTC screen capture...');
      
      // Call native method to stop screen capture
      await _channel.invokeMethod('stopWebRTCScreenCapture');
      
      // Stop local stream
      await _localStream?.dispose();
      _localStream = null;
      
      _updateConnectionState(WebRTCConnectionState.disconnected);
      notifyListeners();
      
      debugPrint('✓ WebRTC screen capture stopped successfully');
      return true;
      
    } catch (e) {
      debugPrint('Error stopping WebRTC screen capture: $e');
      _updateConnectionState(WebRTCConnectionState.error);
      notifyListeners();
      return false;
    }
  }
  
  Future<void> _startScreenCaptureStream() async {
    try {
      // For WebRTC screen capture, we use display media
      _localStream = await navigator.mediaDevices.getDisplayMedia({
        'video': {
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
          'frameRate': {'ideal': _frameRate},
        },
        'audio': false, // Screen audio can be added if needed
      });
      
      if (_localStream != null && _peerConnection != null) {
        // Add tracks to peer connection
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
        
        debugPrint('✓ Screen capture stream added to peer connection');
      }
      
    } catch (e) {
      debugPrint('Error starting screen capture stream: $e');
      throw e;
    }
  }

  Future<void> _startBroadcast() async {
    // Start UDP broadcast for device discovery
    try {
      await _channel.invokeMethod('startBroadcast', {
        'mode': _mode.toString(),
        'quality': _streamQuality.toString(),
      });
    } catch (e) {
      debugPrint('Broadcast start error: $e');
    }
  }

  Future<void> _stopBroadcast() async {
    try {
      await _channel.invokeMethod('stopBroadcast');
    } catch (e) {
      debugPrint('Broadcast stop error: $e');
    }
  }

  Future<void> _sendSignalingMessage(Map<String, dynamic> message) async {
    try {
      await _channel.invokeMethod('sendSignaling', {
        'message': jsonEncode(message),
      });
    } catch (e) {
      debugPrint('Signaling send error: $e');
    }
  }

  void _updateConnectionState(WebRTCConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      notifyListeners();
    }
  }

  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _collectMetrics();
    });
  }

  void _stopMetricsCollection() {
    _metricsTimer?.cancel();
    _metricsTimer = null;
  }

  Future<void> _collectMetrics() async {
    if (_peerConnection == null || _connectionState != WebRTCConnectionState.connected) return;

    try {
      final stats = await _peerConnection!.getStats();
      
      // Process stats to extract metrics
      for (var report in stats) {
        if (report.type == 'inbound-rtp') {
          // Update metrics from stats
          _frameRate = (report.values['framesPerSecond'] as num?)?.toInt() ?? _frameRate;
          _bitrate = (report.values['bytesReceived'] as num?)?.toInt() ?? _bitrate;
          _packetLoss = (report.values['packetsLost'] as num?)?.toDouble() ?? _packetLoss;
          _jitter = (report.values['jitter'] as num?)?.toInt() ?? _jitter;
        }
        
        if (report.type == 'candidate-pair' && report.values['state'] == 'succeeded') {
          _latency = (report.values['currentRoundTripTime'] as num?)?.toInt() ?? _latency;
        }
      }
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Metrics collection error: $e');
    }
  }

  // Quality control methods
  Future<void> setStreamQuality(StreamQuality quality) async {
    if (_streamQuality != quality) {
      _streamQuality = quality;
      notifyListeners();
    }
  }

  void setAutoAdjustQuality(bool enabled) {
    _autoAdjustQuality = enabled;
    notifyListeners();
  }

  void setHardwareAcceleration(bool enabled) {
    _hardwareAcceleration = enabled;
    notifyListeners();
  }

  void setAdaptiveBitrate(bool enabled) {
    _adaptiveBitrate = enabled;
    notifyListeners();
  }

  void setLowLatencyMode(bool enabled) {
    _lowLatencyMode = enabled;
    notifyListeners();
  }
  
  // Advanced optimization methods
  Future<void> optimizeForNetwork() async {
    try {
      if (_autoAdjustQuality && _peerConnection != null) {
        // Auto-adjust quality based on connection stats
        if (_latency > 100 || _packetLoss > 0.05) {
          // Poor connection - reduce quality
          if (_streamQuality == StreamQuality.ultra) {
            await setStreamQuality(StreamQuality.high);
          } else if (_streamQuality == StreamQuality.high) {
            await setStreamQuality(StreamQuality.medium);
          }
          _connectionQuality = 'poor';
        } else if (_latency < 50 && _packetLoss < 0.01) {
          // Excellent connection - increase quality if possible
          if (_streamQuality == StreamQuality.medium) {
            await setStreamQuality(StreamQuality.high);
          } else if (_streamQuality == StreamQuality.high && _bitrate > 3000000) {
            await setStreamQuality(StreamQuality.ultra);
          }
          _connectionQuality = 'excellent';
        } else {
          _connectionQuality = 'good';
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Network optimization error: $e');
    }
  }
  
  Future<void> attemptReconnection() async {
    if (_reconnectAttempts < _maxReconnectAttempts && 
        _connectionState == WebRTCConnectionState.error) {
      
      _reconnectAttempts++;
      debugPrint('Attempting reconnection #$_reconnectAttempts...');
      
      _updateConnectionState(WebRTCConnectionState.connecting);
      
      _reconnectTimer = Timer(Duration(seconds: _reconnectAttempts * 2), () async {
        try {
          // Reinitialize connection
          await _initializePeerConnection();
          
          if (_mode == WebRTCMode.source) {
            await _initializeLocalStream();
          }
          
          _reconnectAttempts = 0;
          _updateConnectionState(WebRTCConnectionState.connected);
          debugPrint('✓ Reconnection successful!');
          
        } catch (e) {
          debugPrint('Reconnection failed: $e');
          if (_reconnectAttempts >= _maxReconnectAttempts) {
            _updateConnectionState(WebRTCConnectionState.error);
          } else {
            attemptReconnection();
          }
        }
      });
    }
  }
  
  void updateConnectionMetrics({
    required int latency,
    required double packetLoss,
    required int bytesTransferred,
  }) {
    _latency = latency;
    _packetLoss = packetLoss;
    _totalBytesTransferred += bytesTransferred;
    
    // Auto-optimize based on metrics
    optimizeForNetwork();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}