import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  // WebRTC Components
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  MediaStream? _localStream;
  
  // Native platform channel
  static const MethodChannel _channel = MethodChannel('com.example.mirroring_app/webrtc');
  
  // Connection state
  bool _isConnected = false;
  bool _isSource = false;
  String? _localIP;
  
  // Stream controllers
  final StreamController<Map<String, dynamic>> _eventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Uint8List> _frameController = 
      StreamController<Uint8List>.broadcast();
  
  // Getters
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<Uint8List> get frameStream => _frameController.stream;
  bool get isConnected => _isConnected;
  bool get isSource => _isSource;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
  
  // WebRTC Configuration
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      },
    ]
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  // Initialize WebRTC
  Future<void> initialize() async {
    try {
      // Initialize renderers
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
      
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
      
      // Get local IP
      _localIP = await _channel.invokeMethod('getLocalIPAddress');
      
      // Set up method channel handler to receive messages from native
      _channel.setMethodCallHandler(_handleNativeMessage);
      
      _eventController.add({
        'type': 'webrtc_initialized',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'localIP': _localIP,
      });
      
      print('WebRTC Service initialized');
    } catch (e) {
      print('WebRTC initialization error: $e');
      _eventController.add({
        'type': 'error',
        'message': 'WebRTC initialization failed: $e',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // Handle messages from native Android code
  Future<void> _handleNativeMessage(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onWebRTCSignalingMessage':
          final Map<String, dynamic> message = Map<String, dynamic>.from(call.arguments);
          await handleSignalingMessage(message);
          break;
        case 'onWebRTCSourceDiscovered':
          final Map<String, dynamic> sourceInfo = Map<String, dynamic>.from(call.arguments);
          _eventController.add({
            'type': 'source-discovered',
            'sourceIP': sourceInfo['ip'],
            'sourceName': sourceInfo['name'],
            'port': sourceInfo['port'],
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;
        case 'onWebRTCError':
          final String error = call.arguments['error'] ?? 'Unknown WebRTC error';
          _eventController.add({
            'type': 'error',
            'message': error,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;
      }
    } catch (e) {
      print('Error handling native message: $e');
    }
  }

  // Start as source (screen sharing)
  Future<void> startAsSource() async {
    try {
      _isSource = true;
      
      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration, _constraints);
      
      // Set up peer connection event handlers
      _setupPeerConnectionHandlers();
      
      // Create data channel for control messages
      RTCDataChannelInit dataChannelDict = RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmitTime = -1
        ..maxRetransmits = -1
        ..protocol = 'sctp'
        ..negotiated = false
        ..id = 1;
        
      _dataChannel = await _peerConnection!.createDataChannel('control', dataChannelDict);
      _setupDataChannelHandlers();
      
      // Start screen capture via native method
      await _channel.invokeMethod('startWebRTCScreenCapture');
      
      // Start broadcast server for discovery
      await _channel.invokeMethod('startWebRTCBroadcastServer');
      
      _eventController.add({
        'type': 'source_started',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'message': 'WebRTC screen sharing started',
      });
      
      print('WebRTC source started');
    } catch (e) {
      print('Error starting WebRTC source: $e');
      _eventController.add({
        'type': 'error',
        'message': 'Failed to start screen sharing: $e',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // Start as viewer (receiving stream)
  Future<void> startAsViewer() async {
    try {
      _isSource = false;
      
      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration, _constraints);
      
      // Set up peer connection event handlers
      _setupPeerConnectionHandlers();
      
      // Start discovery client
      await _channel.invokeMethod('startWebRTCDiscoveryClient');
      
      _eventController.add({
        'type': 'viewer_started',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'message': 'WebRTC viewer started - discovering sources...',
      });
      
      print('WebRTC viewer started');
    } catch (e) {
      print('Error starting WebRTC viewer: $e');
      _eventController.add({
        'type': 'error',
        'message': 'Failed to start viewer: $e',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // Connect to discovered source
  Future<void> connectToSource(String sourceIP) async {
    try {
      if (!_isSource && _peerConnection != null) {
        // Create offer
        RTCSessionDescription description = await _peerConnection!.createOffer(_constraints);
        await _peerConnection!.setLocalDescription(description);
        
        // Send offer to source via native channel
        await _channel.invokeMethod('sendWebRTCOffer', {
          'targetIP': sourceIP,
          'offer': description.toMap(),
        });
        
        _eventController.add({
          'type': 'connecting_to_source',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sourceIP': sourceIP,
        });
        
        print('Connecting to WebRTC source: $sourceIP');
      }
    } catch (e) {
      print('Error connecting to source: $e');
      _eventController.add({
        'type': 'error',
        'message': 'Failed to connect to source: $e',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // Handle WebRTC signaling from native layer
  Future<void> handleSignalingMessage(Map<String, dynamic> message) async {
    try {
      if (_peerConnection == null) return;
      
      String type = message['type'];
      
      switch (type) {
        case 'offer':
          await _handleOffer(message['data']);
          break;
        case 'answer':
          await _handleAnswer(message['data']);
          break;
        case 'ice-candidate':
          await _handleIceCandidate(message['data']);
          break;
        case 'source-discovered':
          _eventController.add({
            'type': 'source_discovered',
            'sourceIP': message['sourceIP'],
            'sourceName': message['sourceName'],
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;
      }
    } catch (e) {
      print('Error handling signaling message: $e');
    }
  }

  // Set up peer connection event handlers
  void _setupPeerConnectionHandlers() {
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _channel.invokeMethod('sendWebRTCIceCandidate', {
        'candidate': candidate.toMap(),
      });
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      if (_remoteRenderer != null) {
        _remoteRenderer!.srcObject = stream;
        _eventController.add({
          'type': 'remote_stream_added',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      _isConnected = (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected);
      
      _eventController.add({
        'type': 'connection_state_changed',
        'state': state.toString(),
        'connected': _isConnected,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      if (_isConnected) {
        print('WebRTC peer connection established');
      }
    };

    _peerConnection!.onDataChannel = (RTCDataChannel channel) {
      _dataChannel = channel;
      _setupDataChannelHandlers();
    };
  }

  // Set up data channel handlers
  void _setupDataChannelHandlers() {
    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      try {
        Map<String, dynamic> data = jsonDecode(message.text);
        _handleControlMessage(data);
      } catch (e) {
        print('Error parsing control message: $e');
      }
    };

    _dataChannel!.onDataChannelState = (RTCDataChannelState state) {
      print('Data channel state: $state');
    };
  }

  // Handle WebRTC offer
  Future<void> _handleOffer(Map<String, dynamic> offerData) async {
    try {
      RTCSessionDescription offer = RTCSessionDescription(
        offerData['sdp'],
        offerData['type'],
      );
      
      await _peerConnection!.setRemoteDescription(offer);
      
      // Create answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer(_constraints);
      await _peerConnection!.setLocalDescription(answer);
      
      // Send answer back via native channel
      await _channel.invokeMethod('sendWebRTCAnswer', {
        'answer': answer.toMap(),
      });
      
    } catch (e) {
      print('Error handling offer: $e');
    }
  }

  // Handle WebRTC answer
  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    try {
      RTCSessionDescription answer = RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );
      
      await _peerConnection!.setRemoteDescription(answer);
      
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  // Handle ICE candidate
  Future<void> _handleIceCandidate(Map<String, dynamic> candidateData) async {
    try {
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      
      await _peerConnection!.addCandidate(candidate);
      
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }

  // Handle control messages via data channel
  void _handleControlMessage(Map<String, dynamic> message) {
    _eventController.add({
      'type': 'control_message',
      'data': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Send control message
  Future<void> sendControlMessage(Map<String, dynamic> message) async {
    try {
      if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
        String jsonMessage = jsonEncode(message);
        RTCDataChannelMessage dataChannelMessage = RTCDataChannelMessage(jsonMessage);
        await _dataChannel!.send(dataChannelMessage);
      }
    } catch (e) {
      print('Error sending control message: $e');
    }
  }

  // Stop WebRTC service
  Future<void> stop() async {
    try {
      // Stop native components
      await _channel.invokeMethod('stopWebRTCService');
      
      // Close data channel
      if (_dataChannel != null) {
        _dataChannel!.close();
        _dataChannel = null;
      }
      
      // Close peer connection
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }
      
      // Stop local stream
      if (_localStream != null) {
        _localStream!.dispose();
        _localStream = null;
      }
      
      // Clear renderers
      if (_localRenderer != null) {
        _localRenderer!.srcObject = null;
      }
      if (_remoteRenderer != null) {
        _remoteRenderer!.srcObject = null;
      }
      
      _isConnected = false;
      _isSource = false;
      
      _eventController.add({
        'type': 'service_stopped',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('WebRTC service stopped');
    } catch (e) {
      print('Error stopping WebRTC service: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _eventController.close();
    _frameController.close();
    
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    
    stop();
  }

  // Get connection stats
  Future<Map<String, dynamic>> getConnectionStats() async {
    try {
      if (_peerConnection != null) {
        List<StatsReport> stats = await _peerConnection!.getStats();
        
        Map<String, dynamic> result = {
          'connected': _isConnected,
          'isSource': _isSource,
          'localIP': _localIP,
          'statsCount': stats.length,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        
        // Extract useful stats
        for (StatsReport report in stats) {
          if (report.type == 'outbound-rtp' || report.type == 'inbound-rtp') {
            result['${report.type}_stats'] = report.values;
          }
        }
        
        return result;
      }
    } catch (e) {
      print('Error getting connection stats: $e');
    }
    
    return {
      'connected': _isConnected,
      'error': 'No connection available',
    };
  }
}
