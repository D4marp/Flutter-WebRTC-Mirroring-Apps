package com.example.mirroring_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper
import android.content.Intent
import android.content.Context
import android.os.Build
import android.util.Log
import android.net.wifi.WifiManager
import android.net.wifi.WifiInfo
import android.net.NetworkInfo
import android.net.ConnectivityManager
import java.net.DatagramSocket
import java.net.DatagramPacket
import java.net.InetAddress
import java.net.NetworkInterface
import java.util.Timer
import java.util.TimerTask
import kotlin.concurrent.thread
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.ConcurrentHashMap
import org.json.JSONObject
import java.util.concurrent.Executors
import java.util.concurrent.ExecutorService

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.mirroring_app/webrtc"
    private val EVENT_CHANNEL = "com.example.mirroring_app/webrtc_events"
    
    // WebRTC Configuration
    private val WEBRTC_SIGNALING_PORT = 9999
    private val DISCOVERY_PORT = 7777
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    
    // WebRTC Discovery and Signaling
    private var discoverySocket: DatagramSocket? = null
    private var signalingSocket: DatagramSocket? = null
    private val isDiscovering = AtomicBoolean(false)
    private val isSignalingActive = AtomicBoolean(false)
    private val discoveredPeers = ConcurrentHashMap<String, String>()
    private val webrtcExecutor: ExecutorService = Executors.newCachedThreadPool()
    
    // Network info
    private var deviceId: String = ""
    private var localIP: String = ""
    
    companion object {
        private const val TAG = "WebRTCMirroringApp"
        private const val DEFAULT_SIGNALING_PORT = 9999
        private const val DEFAULT_DISCOVERY_PORT = 7777
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize device info
        initializeDeviceInfo()
        
        // Method Channel for WebRTC operations
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeWebRTC" -> {
                    initializeWebRTC(result)
                }
                "startDiscovery" -> {
                    startPeerDiscovery(result)
                }
                "stopDiscovery" -> {
                    stopPeerDiscovery(result)
                }
                "startSignaling" -> {
                    val isOfferer = call.argument<Boolean>("isOfferer") ?: false
                    startSignaling(isOfferer, result)
                }
                "stopSignaling" -> {
                    stopSignaling(result)
                }
                "sendSignalingMessage" -> {
                    val message = call.argument<String>("message") ?: ""
                    val targetIP = call.argument<String>("targetIP") ?: ""
                    sendSignalingMessage(message, targetIP, result)
                }
                "getLocalNetworkInfo" -> {
                    getLocalNetworkInfo(result)
                }
                "getDiscoveredPeers" -> {
                    getDiscoveredPeers(result)
                }
                "startWebRTCScreenCapture" -> {
                    startWebRTCScreenCapture(result)
                }
                "stopWebRTCScreenCapture" -> {
                    stopWebRTCScreenCapture(result)
                }
                "connectToWebRTCPeer" -> {
                    val peerIP = call.argument<String>("peerIP") ?: ""
                    connectToWebRTCPeer(peerIP, result)
                }
                "startWebRTCBroadcastServer" -> {
                    startWebRTCBroadcastServer(result)
                }
                "stopWebRTCBroadcastServer" -> {
                    stopWebRTCBroadcastServer(result)
                }
                "startWebRTCDiscoveryClient" -> {
                    startWebRTCDiscoveryClient(result)
                }
                "getLocalIPAddress" -> {
                    result.success(getLocalIPAddress())
                }
                "sendSignaling" -> {
                    val message = call.argument<String>("message") ?: ""
                    val targetIP = call.argument<String>("targetIP") ?: ""
                    sendSignalingMessage(message, targetIP, result)
                }
                "startBroadcast" -> {
                    startWebRTCBroadcastServer(result)
                }
                "stopBroadcast" -> {
                    stopWebRTCBroadcastServer(result)
                }
                "stopWebRTCService" -> {
                    stopWebRTCService(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Event Channel for WebRTC events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(TAG, "WebRTC Event channel listening started")
                
                // Send initialization event
                sendWebRTCEvent("webrtc_initialized", mapOf(
                    "deviceId" to deviceId,
                    "localIP" to localIP
                ))
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(TAG, "WebRTC Event channel listening stopped")
            }
        })
    }
    
    private fun initializeDeviceInfo() {
        try {
            // Generate unique device ID
            deviceId = "${Build.MODEL}_${System.currentTimeMillis() % 10000}"
            
            // Get local IP address
            localIP = getLocalIPAddress()
            
            Log.d(TAG, "Device initialized - ID: $deviceId, IP: $localIP")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing device info", e)
        }
    }
    
    private fun getLocalIPAddress(): String {
        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = wifiManager.connectionInfo
            val ipAddress = wifiInfo.ipAddress
            
            return if (ipAddress != 0) {
                "${ipAddress and 0xFF}.${ipAddress shr 8 and 0xFF}.${ipAddress shr 16 and 0xFF}.${ipAddress shr 24 and 0xFF}"
            } else {
                // Fallback to network interface method
                NetworkInterface.getNetworkInterfaces()
                    .toList()
                    .flatMap { it.inetAddresses.toList() }
                    .find { !it.isLoopbackAddress && it.address.size == 4 }
                    ?.hostAddress ?: "192.168.1.100"
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting local IP", e)
            return "192.168.1.100"
        }
    }
    
    private fun initializeWebRTC(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Initializing WebRTC system...")
            
            // Initialize network components
            initializeDeviceInfo()
            
            handler.post {
                result.success(mapOf(
                    "deviceId" to deviceId,
                    "localIP" to localIP,
                    "initialized" to true
                ))
                
                sendWebRTCEvent("webrtc_ready", mapOf(
                    "deviceId" to deviceId,
                    "localIP" to localIP,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
            
            Log.d(TAG, "WebRTC system initialized successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing WebRTC", e)
            handler.post {
                result.error("WEBRTC_INIT_ERROR", e.message, null)
            }
        }
    }
    
    private fun startPeerDiscovery(result: MethodChannel.Result) {
        try {
            if (isDiscovering.get()) {
                result.success(true)
                return
            }
            
            Log.d(TAG, "Starting WebRTC peer discovery...")
            
            discoverySocket = DatagramSocket(DISCOVERY_PORT)
            discoverySocket?.broadcast = true
            isDiscovering.set(true)
            
            // Start discovery listener thread
            webrtcExecutor.execute {
                try {
                    val buffer = ByteArray(1024)
                    val packet = DatagramPacket(buffer, buffer.size)
                    
                    while (isDiscovering.get() && discoverySocket != null && !discoverySocket!!.isClosed) {
                        try {
                            discoverySocket?.receive(packet)
                            
                            val message = String(packet.data, 0, packet.length)
                            val senderIP = packet.address.hostAddress ?: "unknown"
                            
                            if (message.startsWith("WEBRTC_PEER:") && senderIP != localIP) {
                                val peerInfo = message.substring("WEBRTC_PEER:".length)
                                val peerData = JSONObject(peerInfo)
                                val peerId = peerData.getString("deviceId")
                                
                                discoveredPeers[peerId] = senderIP
                                
                                handler.post {
                                    sendWebRTCEvent("peer_discovered", mapOf(
                                        "peerId" to peerId,
                                        "peerIP" to senderIP,
                                        "timestamp" to System.currentTimeMillis()
                                    ))
                                }
                                
                                Log.d(TAG, "Discovered WebRTC peer: $peerId at $senderIP")
                            }
                        } catch (e: Exception) {
                            if (isDiscovering.get()) {
                                Log.w(TAG, "Discovery packet receive error: ${e.message}")
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Discovery listener error", e)
                }
            }
            
            // Start broadcasting our presence
            webrtcExecutor.execute {
                val timer = Timer()
                val broadcastTask = object : TimerTask() {
                    override fun run() {
                        if (!isDiscovering.get()) {
                            cancel()
                            return
                        }
                        
                        try {
                            val peerInfo = JSONObject().apply {
                                put("deviceId", deviceId)
                                put("type", "webrtc_peer")
                                put("timestamp", System.currentTimeMillis())
                            }
                            
                            val message = "WEBRTC_PEER:$peerInfo"
                            val broadcastAddress = InetAddress.getByName("255.255.255.255")
                            val packet = DatagramPacket(
                                message.toByteArray(),
                                message.length,
                                broadcastAddress,
                                DISCOVERY_PORT
                            )
                            
                            discoverySocket?.send(packet)
                            
                        } catch (e: Exception) {
                            Log.w(TAG, "Broadcast error: ${e.message}")
                        }
                    }
                }
                
                timer.scheduleAtFixedRate(broadcastTask, 0, 3000) // Broadcast every 3 seconds
            }
            
            result.success(true)
            Log.d(TAG, "WebRTC peer discovery started")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting peer discovery", e)
            result.error("DISCOVERY_ERROR", e.message, null)
        }
    }
    
    private fun stopPeerDiscovery(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Stopping WebRTC peer discovery...")
            
            isDiscovering.set(false)
            discoverySocket?.close()
            discoverySocket = null
            discoveredPeers.clear()
            
            handler.post {
                sendWebRTCEvent("discovery_stopped", mapOf(
                    "timestamp" to System.currentTimeMillis()
                ))
            }
            
            result.success(true)
            Log.d(TAG, "WebRTC peer discovery stopped")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping peer discovery", e)
            result.error("DISCOVERY_STOP_ERROR", e.message, null)
        }
    }
    
    private fun startSignaling(isOfferer: Boolean, result: MethodChannel.Result) {
        try {
            if (isSignalingActive.get()) {
                result.success(true)
                return
            }
            
            Log.d(TAG, "Starting WebRTC signaling server (isOfferer: $isOfferer)...")
            
            signalingSocket = DatagramSocket(WEBRTC_SIGNALING_PORT)
            isSignalingActive.set(true)
            
            // Start signaling listener
            webrtcExecutor.execute {
                try {
                    val buffer = ByteArray(4096) // Larger buffer for signaling messages
                    val packet = DatagramPacket(buffer, buffer.size)
                    
                    while (isSignalingActive.get() && signalingSocket != null && !signalingSocket!!.isClosed) {
                        try {
                            signalingSocket?.receive(packet)
                            
                            val message = String(packet.data, 0, packet.length)
                            val senderIP = packet.address.hostAddress ?: "unknown"
                            
                            if (message.startsWith("WEBRTC_SIGNAL:") && senderIP != localIP) {
                                val signalData = message.substring("WEBRTC_SIGNAL:".length)
                                
                                handler.post {
                                    sendWebRTCEvent("signaling_message", mapOf(
                                        "message" to signalData,
                                        "fromIP" to senderIP,
                                        "timestamp" to System.currentTimeMillis()
                                    ))
                                }
                                
                                Log.d(TAG, "Received WebRTC signaling from $senderIP")
                            }
                        } catch (e: Exception) {
                            if (isSignalingActive.get()) {
                                Log.w(TAG, "Signaling receive error: ${e.message}")
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Signaling listener error", e)
                }
            }
            
            result.success(true)
            
            handler.post {
                sendWebRTCEvent("signaling_started", mapOf(
                    "isOfferer" to isOfferer,
                    "port" to WEBRTC_SIGNALING_PORT,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
            
            Log.d(TAG, "WebRTC signaling started")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting signaling", e)
            result.error("SIGNALING_ERROR", e.message, null)
        }
    }
    
    private fun stopSignaling(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Stopping WebRTC signaling...")
            
            isSignalingActive.set(false)
            signalingSocket?.close()
            signalingSocket = null
            
            handler.post {
                sendWebRTCEvent("signaling_stopped", mapOf(
                    "timestamp" to System.currentTimeMillis()
                ))
            }
            
            result.success(true)
            Log.d(TAG, "WebRTC signaling stopped")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping signaling", e)
            result.error("SIGNALING_STOP_ERROR", e.message, null)
        }
    }
    
    private fun sendSignalingMessage(message: String, targetIP: String, result: MethodChannel.Result) {
        try {
            webrtcExecutor.execute {
                try {
                    val signalMessage = "WEBRTC_SIGNAL:$message"
                    val targetAddress = InetAddress.getByName(targetIP)
                    val packet = DatagramPacket(
                        signalMessage.toByteArray(),
                        signalMessage.length,
                        targetAddress,
                        WEBRTC_SIGNALING_PORT
                    )
                    
                    signalingSocket?.send(packet)
                    
                    handler.post {
                        result.success(true)
                        sendWebRTCEvent("signaling_sent", mapOf(
                            "targetIP" to targetIP,
                            "timestamp" to System.currentTimeMillis()
                        ))
                    }
                    
                    Log.d(TAG, "Sent WebRTC signaling to $targetIP")
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending signaling message", e)
                    handler.post {
                        result.error("SIGNALING_SEND_ERROR", e.message, null)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in sendSignalingMessage", e)
            result.error("SIGNALING_SEND_ERROR", e.message, null)
        }
    }
    
    private fun getLocalNetworkInfo(result: MethodChannel.Result) {
        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = wifiManager.connectionInfo
            
            val networkInfo = mapOf(
                "deviceId" to deviceId,
                "localIP" to localIP,
                "ssid" to (wifiInfo.ssid ?: "unknown"),
                "rssi" to wifiInfo.rssi,
                "linkSpeed" to wifiInfo.linkSpeed,
                "networkId" to wifiInfo.networkId,
                "isConnected" to (wifiInfo.networkId != -1)
            )
            
            result.success(networkInfo)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting network info", e)
            result.error("NETWORK_INFO_ERROR", e.message, null)
        }
    }
    
    private fun getDiscoveredPeers(result: MethodChannel.Result) {
        try {
            val peers = discoveredPeers.map { (peerId, peerIP) ->
                mapOf(
                    "peerId" to peerId,
                    "peerIP" to peerIP
                )
            }
            
            result.success(peers)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting discovered peers", e)
            result.error("PEERS_ERROR", e.message, null)
        }
    }
    
    private fun sendWebRTCEvent(eventType: String, data: Map<String, Any> = emptyMap()) {
        handler.post {
            eventSink?.success(mapOf(
                "type" to eventType,
                "data" to data,
                "timestamp" to System.currentTimeMillis()
            ))
        }
    }
    
    // ============ WebRTC Screen Capture Methods ============
    
    private fun startWebRTCScreenCapture(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Starting WebRTC screen capture...")
            
            // For WebRTC screen capture, we need to integrate with flutter_webrtc plugin
            // Since we're using pure WebRTC approach, this method will:
            // 1. Initialize screen capture capability
            // 2. Signal to peers that screen sharing is available
            // 3. Start broadcasting availability
            
            // Send success immediately since WebRTC screen capture is handled by flutter_webrtc
            result.success(mapOf(
                "status" to "started",
                "message" to "WebRTC screen capture initialized",
                "deviceId" to deviceId,
                "localIP" to localIP
            ))
            
            // Broadcast screen sharing availability
            broadcastScreenSharingAvailability(true)
            
            // Send event to Flutter
            sendWebRTCEvent("screen_capture_started", mapOf(
                "deviceId" to deviceId,
                "localIP" to localIP,
                "ready" to true
            ))
            
            Log.d(TAG, "✓ WebRTC screen capture started successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting WebRTC screen capture", e)
            result.error("WEBRTC_SCREEN_CAPTURE_ERROR", e.message, null)
            
            sendWebRTCEvent("screen_capture_failed", mapOf(
                "error" to (e.message ?: "Unknown error")
            ))
        }
    }
    
    private fun stopWebRTCScreenCapture(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Stopping WebRTC screen capture...")
            
            // Stop broadcasting availability
            broadcastScreenSharingAvailability(false)
            
            result.success(mapOf(
                "status" to "stopped",
                "message" to "WebRTC screen capture stopped"
            ))
            
            sendWebRTCEvent("screen_capture_stopped", mapOf(
                "deviceId" to deviceId
            ))
            
            Log.d(TAG, "✓ WebRTC screen capture stopped successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping WebRTC screen capture", e)
            result.error("WEBRTC_SCREEN_CAPTURE_STOP_ERROR", e.message, null)
        }
    }
    
    private fun connectToWebRTCPeer(peerIP: String, result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Connecting to WebRTC peer: $peerIP")
            
            // Send connection request to peer
            val connectionMessage = JSONObject().apply {
                put("type", "connection_request")
                put("from", deviceId)
                put("fromIP", localIP)
                put("timestamp", System.currentTimeMillis())
            }
            
            sendSignalingMessage(connectionMessage.toString(), peerIP, result)
            
            sendWebRTCEvent("peer_connection_initiated", mapOf(
                "peerIP" to peerIP,
                "deviceId" to deviceId
            ))
            
            Log.d(TAG, "✓ Connection request sent to peer: $peerIP")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting to WebRTC peer", e)
            result.error("WEBRTC_PEER_CONNECTION_ERROR", e.message, null)
        }
    }
    
    private fun broadcastScreenSharingAvailability(isAvailable: Boolean) {
        webrtcExecutor.submit {
            try {
                val socket = DatagramSocket()
                socket.broadcast = true
                
                val message = JSONObject().apply {
                    put("type", "screen_share_availability")
                    put("deviceId", deviceId)
                    put("localIP", localIP)
                    put("available", isAvailable)
                    put("timestamp", System.currentTimeMillis())
                }
                
                val messageBytes = message.toString().toByteArray()
                val packet = DatagramPacket(
                    messageBytes,
                    messageBytes.size,
                    InetAddress.getByName("255.255.255.255"),
                    DISCOVERY_PORT
                )
                
                socket.send(packet)
                socket.close()
                
                Log.d(TAG, "Broadcasted screen sharing availability: $isAvailable")
                
            } catch (e: Exception) {
                Log.e(TAG, "Error broadcasting screen sharing availability", e)
            }
        }
    }
    
    // ============ WebRTC Broadcast and Discovery Methods ============
    
    private fun startWebRTCBroadcastServer(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Starting WebRTC broadcast server...")
            
            // Stop any existing broadcast server first
            stopWebRTCBroadcastServer(object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                override fun notImplemented() {}
            })
            
            // Start broadcasting WebRTC availability
            webrtcExecutor.submit {
                try {
                    // Close existing socket if any
                    discoverySocket?.close()
                    
                    discoverySocket = DatagramSocket(DISCOVERY_PORT)
                    discoverySocket?.broadcast = true
                    discoverySocket?.reuseAddress = true
                    isSignalingActive.set(true)
                    
                    while (isSignalingActive.get() && discoverySocket?.isClosed == false) {
                        val message = JSONObject().apply {
                            put("type", "webrtc_source_available")
                            put("deviceId", deviceId)
                            put("localIP", localIP)
                            put("signalingPort", WEBRTC_SIGNALING_PORT)
                            put("timestamp", System.currentTimeMillis())
                        }
                        
                        val messageBytes = message.toString().toByteArray()
                        val packet = DatagramPacket(
                            messageBytes,
                            messageBytes.size,
                            InetAddress.getByName("255.255.255.255"),
                            DISCOVERY_PORT
                        )
                        
                        discoverySocket?.send(packet)
                        Thread.sleep(3000) // Broadcast every 3 seconds
                    }
                    
                    discoverySocket?.close()
                    Log.d(TAG, "WebRTC broadcast server stopped")
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Error in WebRTC broadcast server", e)
                }
            }
            
            result.success(mapOf("status" to "started", "port" to DISCOVERY_PORT))
            
            sendWebRTCEvent("broadcast_server_started", mapOf(
                "port" to DISCOVERY_PORT,
                "deviceId" to deviceId
            ))
            
            Log.d(TAG, "✓ WebRTC broadcast server started on port $DISCOVERY_PORT")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting WebRTC broadcast server", e)
            result.error("WEBRTC_BROADCAST_ERROR", e.message, null)
        }
    }
    
    private fun stopWebRTCBroadcastServer(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Stopping WebRTC broadcast server...")
            
            isSignalingActive.set(false)
            
            // Close discovery socket
            discoverySocket?.close()
            discoverySocket = null
            
            result.success(mapOf("status" to "stopped"))
            
            sendWebRTCEvent("broadcast_server_stopped", mapOf(
                "deviceId" to deviceId
            ))
            
            Log.d(TAG, "✓ WebRTC broadcast server stopped")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping WebRTC broadcast server", e)
            result.error("WEBRTC_BROADCAST_STOP_ERROR", e.message, null)
        }
    }
    
    private fun startWebRTCDiscoveryClient(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Starting WebRTC discovery client...")
            
            webrtcExecutor.submit {
                try {
                    val socket = DatagramSocket()
                    socket.broadcast = true
                    socket.soTimeout = 5000 // 5 second timeout
                    
                    // Send discovery request
                    val discoveryMessage = JSONObject().apply {
                        put("type", "webrtc_discovery_request")
                        put("deviceId", deviceId)
                        put("localIP", localIP)
                        put("timestamp", System.currentTimeMillis())
                    }
                    
                    val messageBytes = discoveryMessage.toString().toByteArray()
                    val packet = DatagramPacket(
                        messageBytes,
                        messageBytes.size,
                        InetAddress.getByName("255.255.255.255"),
                        DISCOVERY_PORT
                    )
                    
                    socket.send(packet)
                    
                    // Listen for responses
                    val buffer = ByteArray(1024)
                    val responsePacket = DatagramPacket(buffer, buffer.size)
                    
                    try {
                        socket.receive(responsePacket)
                        val response = String(responsePacket.data, 0, responsePacket.length)
                        val responseJson = JSONObject(response)
                        
                        if (responseJson.getString("type") == "webrtc_source_available") {
                            val sourceIP = responseJson.getString("localIP")
                            val sourceDeviceId = responseJson.getString("deviceId")
                            
                            handler.post {
                                sendWebRTCEvent("webrtc_source_discovered", mapOf(
                                    "sourceIP" to sourceIP,
                                    "sourceDeviceId" to sourceDeviceId,
                                    "signalingPort" to responseJson.getInt("signalingPort")
                                ))
                            }
                        }
                        
                    } catch (timeoutException: Exception) {
                        Log.d(TAG, "Discovery timeout - no sources found")
                    }
                    
                    socket.close()
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Error in WebRTC discovery client", e)
                }
            }
            
            result.success(mapOf("status" to "started"))
            
            sendWebRTCEvent("discovery_client_started", mapOf(
                "deviceId" to deviceId
            ))
            
            Log.d(TAG, "✓ WebRTC discovery client started")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting WebRTC discovery client", e)
            result.error("WEBRTC_DISCOVERY_ERROR", e.message, null)
        }
    }
    
    private fun stopWebRTCService(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Stopping WebRTC service...")
            
            // Stop all WebRTC components
            stopWebRTCScreenCapture(object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                override fun notImplemented() {}
            })
            
            stopWebRTCBroadcastServer(object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                override fun notImplemented() {}
            })
            
            stopPeerDiscovery(object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                override fun notImplemented() {}
            })
            
            stopSignaling(object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                override fun notImplemented() {}
            })
            
            Log.d(TAG, "✓ WebRTC service stopped")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping WebRTC service", e)
            result.error("WEBRTC_SERVICE_STOP_ERROR", e.message, null)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // Clean up WebRTC resources
        try {
            isDiscovering.set(false)
            isSignalingActive.set(false)
            
            discoverySocket?.close()
            signalingSocket?.close()
            
            webrtcExecutor.shutdown()
            
            Log.d(TAG, "WebRTC resources cleaned up")
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up WebRTC resources", e)
        }
    }
}
