//
//  Copyright (c) 2014-2016 Actor LLC. <https://actor.im>
//

import Foundation
import AVFoundation

let queue = dispatch_queue_create("My Queue", DISPATCH_QUEUE_SERIAL);

class CocoaWebRTCRuntime: NSObject, ARWebRTCRuntime {
    
    
    
    private var isInited: Bool = false
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var videoSource: RTCVideoSource!
    private var videoSourceLoaded = false
    
    override init() {
        
    }
    
    func getUserMediaWithIsAudioEnabled(isAudioEnabled: jboolean, withIsVideoEnabled isVideoEnabled: jboolean) -> ARPromise {
        
        return ARPromise { (resolver) -> () in
            dispatch_async(queue) {
                
                self.initRTC()
                
                // Unfortinatelly building capture source "on demand" causes some weird internal crashes
                self.initVideo()
                
                let stream = self.peerConnectionFactory.mediaStreamWithLabel("ARDAMSv0")
                
                //
                // Audio
                //
                if isAudioEnabled {
                    let audio = self.peerConnectionFactory.audioTrackWithID("audio0")
                    stream.addAudioTrack(audio)
                }
                
                //
                // Video
                //
                if isVideoEnabled {
                    if self.videoSource != nil {
                        let localVideoTrack = self.peerConnectionFactory.videoTrackWithID("video0", source: self.videoSource)
                        stream.addVideoTrack(localVideoTrack)
                    }
                }
                
                resolver.result(MediaStream(stream:stream))
            }
        }
    }
    
    func createPeerConnectionWithServers(webRTCIceServers: IOSObjectArray!, withSettings settings: ARWebRTCSettings!) -> ARPromise {
        let servers: [ARWebRTCIceServer] = webRTCIceServers.toSwiftArray()
        return ARPromise { (resolver) -> () in
            dispatch_async(queue) {
                self.initRTC()
                resolver.result(CocoaWebRTCPeerConnection(servers: servers, peerConnectionFactory: self.peerConnectionFactory))
            }
        }
    }
    
    func initRTC() {
        if !isInited {
            isInited = true
            RTCPeerConnectionFactory.initializeSSL()
            peerConnectionFactory = RTCPeerConnectionFactory()
        }
    }
    
    func initVideo() {
        if !self.videoSourceLoaded {
            self.videoSourceLoaded = true
            
            var cameraID: String?
            for captureDevice in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
                if captureDevice.position == AVCaptureDevicePosition.Front {
                    cameraID = captureDevice.localizedName
                }
            }
            
            if(cameraID != nil) {
                let videoCapturer = RTCVideoCapturer(deviceName: cameraID)
                self.videoSource = self.peerConnectionFactory.videoSourceWithCapturer(videoCapturer, constraints: RTCMediaConstraints())
            }
        }
    }
    
    func supportsPreConnections() -> jboolean {
        return false
    }
}

@objc class MediaStream: NSObject, ARWebRTCMediaStream {
    
    let stream: RTCMediaStream
    let audioTracks: IOSObjectArray
    let videoTracks: IOSObjectArray
    let allTracks: IOSObjectArray
    
    init(stream: RTCMediaStream) {
        self.stream = stream
        
        self.audioTracks = IOSObjectArray(length: UInt(stream.audioTracks.count), type: ARWebRTCMediaTrack_class_())
        self.videoTracks = IOSObjectArray(length: UInt(stream.videoTracks.count), type: ARWebRTCMediaTrack_class_())
        self.allTracks = IOSObjectArray(length: UInt(stream.audioTracks.count + stream.videoTracks.count), type: ARWebRTCMediaTrack_class_())
        
        for i in 0..<stream.audioTracks.count {
            let track = CocoaAudioTrack(audioTrack: stream.audioTracks[i] as! RTCAudioTrack)
            audioTracks.replaceObjectAtIndex(UInt(i), withObject: track)
            allTracks.replaceObjectAtIndex(UInt(i), withObject: track)
        }
        for i in 0..<stream.videoTracks.count {
            let track = CocoaVideoTrack(videoTrack: stream.videoTracks[i] as! RTCVideoTrack)
            videoTracks.replaceObjectAtIndex(UInt(i), withObject: track)
            allTracks.replaceObjectAtIndex(UInt(i + audioTracks.length()), withObject: track)
        }
    }
    
    func getAudioTracks() -> IOSObjectArray! {
        return audioTracks
    }
    
    func getVideoTracks() -> IOSObjectArray! {
        return videoTracks
    }
    
    func getTracks() -> IOSObjectArray! {
        return allTracks
    }
    
    func close() {
        for i in stream.audioTracks {
            (i as! RTCAudioTrack).setEnabled(false)
            stream.removeAudioTrack(i as! RTCAudioTrack)
        }
        for i in stream.videoTracks {
            (i as! RTCVideoTrack).setEnabled(false)
            stream.removeVideoTrack(i as! RTCVideoTrack)
        }
    }
}

public class CocoaAudioTrack: NSObject, ARWebRTCMediaTrack {
    
    public let audioTrack: RTCAudioTrack
    
    public init(let audioTrack: RTCAudioTrack) {
        self.audioTrack = audioTrack
    }
    
    public func getTrackType() -> jint {
        return ARWebRTCTrackType_AUDIO
    }
    
    public func setEnabledWithBoolean(isEnabled: jboolean) {
        audioTrack.setEnabled(isEnabled)
    }
    
    public func isEnabled() -> jboolean {
        return audioTrack.isEnabled()
    }
}

public class CocoaVideoTrack: NSObject, ARWebRTCMediaTrack {
    
    public let videoTrack: RTCVideoTrack
    
    public init(let videoTrack: RTCVideoTrack) {
        self.videoTrack = videoTrack
    }
    
    public func getTrackType() -> jint {
        return ARWebRTCTrackType_VIDEO
    }
    
    public func setEnabledWithBoolean(isEnabled: jboolean) {
        videoTrack.setEnabled(isEnabled)
    }
    
    public func isEnabled() -> jboolean {
        return videoTrack.isEnabled()
    }
}

class CocoaWebRTCPeerConnection: NSObject, ARWebRTCPeerConnection, RTCPeerConnectionDelegate {
    
    private var peerConnection: RTCPeerConnection!
    private var callbacks = [ARWebRTCPeerConnectionCallback]()
    private let peerConnectionFactory: RTCPeerConnectionFactory
    private var ownStreams = [ARCountedReference]()
    
    init(servers: [ARWebRTCIceServer], peerConnectionFactory: RTCPeerConnectionFactory) {
        self.peerConnectionFactory = peerConnectionFactory
        super.init()
        
        let iceServers = servers.map { (src) -> RTCICEServer in
            if (src.username == nil || src.credential == nil) {
                return RTCICEServer(URI: NSURL(string: src.url), username: "", password: "")
            } else {
                return RTCICEServer(URI: NSURL(string: src.url), username: src.username, password: src.credential)
            }
        }
        
        peerConnection = peerConnectionFactory.peerConnectionWithICEServers(iceServers, constraints: RTCMediaConstraints(), delegate: self)
        AAAudioManager.sharedAudio().peerConnectionStarted()
    }
    
    func addCallback(callback: ARWebRTCPeerConnectionCallback) {
        
        if !callbacks.contains({ callback.isEqual($0) }) {
            callbacks.append(callback)
        }
    }
    
    func removeCallback(callback: ARWebRTCPeerConnectionCallback) {
        let index = callbacks.indexOf({ callback.isEqual($0) })
        if index != nil {
            callbacks.removeAtIndex(index!)
        }
    }
    func addCandidateWithIndex(index: jint, withId id_: String, withSDP sdp: String) {
        peerConnection.addICECandidate(RTCICECandidate(mid: id_, index: Int(index), sdp: sdp))
    }
    
    func addOwnStream(stream: ARCountedReference) {
        stream.acquire()
        let ms = (stream.get() as! MediaStream)
        ownStreams.append(stream)
        peerConnection.addStream(ms.stream)
    }
    
    func removeOwnStream(stream: ARCountedReference) {
        if ownStreams.contains(stream) {
            let ms = (stream.get() as! MediaStream)
            peerConnection.removeStream(ms.stream)
            stream.release__()
        }
    }
    
    func createAnswer() -> ARPromise {
        return ARPromise(closure: { (resolver) -> () in
            let constraints = RTCMediaConstraints(mandatoryConstraints: [RTCPair(key: "OfferToReceiveAudio", value: "true"),
                RTCPair(key: "OfferToReceiveVideo", value: "true")], optionalConstraints: [])
            self.peerConnection.createAnswer(constraints, didCreate: { (desc, error) -> () in
                if error == nil {
                    resolver.result(ARWebRTCSessionDescription(type: "answer", withSDP: desc.description))
                } else {
                    resolver.error(JavaLangException(NSString: "Error \(error.description)"))
                }
            })
        })
    }
    
    func creteOffer() -> ARPromise {
        return ARPromise(closure: { (resolver) -> () in
            let constraints = RTCMediaConstraints(mandatoryConstraints: [RTCPair(key: "OfferToReceiveAudio", value: "true"),
                RTCPair(key: "OfferToReceiveVideo", value: "true")], optionalConstraints: [])
            self.peerConnection.createOffer(constraints, didCreate: { (desc, error) -> () in
                if error == nil {
                    resolver.result(ARWebRTCSessionDescription(type: "offer", withSDP: desc.description))
                } else {
                    resolver.error(JavaLangException(NSString: "Error \(error.description)"))
                }
            })
        })
    }
    
    func setRemoteDescription(description_: ARWebRTCSessionDescription) -> ARPromise {
        return ARPromise(executor: AAPromiseFunc(closure: { (resolver) -> () in
            self.peerConnection.setRemoteDescription(RTCSessionDescription(type: description_.type, sdp: description_.sdp), didSet: { (error) -> () in
                if (error == nil) {
                    resolver.result(description_)
                } else {
                    resolver.error(JavaLangException(NSString: "Error \(error.description)"))
                }
            })
        }))
    }
    
    func setLocalDescription(description_: ARWebRTCSessionDescription) -> ARPromise {
        return ARPromise(executor: AAPromiseFunc(closure: { (resolver) -> () in
            self.peerConnection.setLocalDescription(RTCSessionDescription(type: description_.type, sdp: description_.sdp), didSet: { (error) -> () in
                if (error == nil) {
                    resolver.result(description_)
                } else {
                    resolver.error(JavaLangException(NSString: "Error \(error.description)"))
                }
            })
        }))
        
    }
    
    func close() {
        for s in ownStreams {
            let ms = s.get() as! MediaStream
            peerConnection.removeStream(ms.stream)
            s.release__()
        }
        ownStreams.removeAll()
        peerConnection.close()
        AAAudioManager.sharedAudio().peerConnectionEnded()
    }
    
    //
    // RTCPeerConnectionDelegate
    //
    
    
    func peerConnection(peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        for c in callbacks {
            c.onStreamAdded(MediaStream(stream: stream!))
        }
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        for c in callbacks {
            c.onStreamRemoved(MediaStream(stream: stream!))
        }
    }
    
    func peerConnectionOnRenegotiationNeeded(peerConnection: RTCPeerConnection!) {
        for c in callbacks {
            c.onRenegotiationNeeded()
        }
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
        for c in callbacks {
            c.onCandidateWithLabel(jint(candidate.sdpMLineIndex), withId: candidate.sdpMid, withCandidate: candidate.sdp)
        }
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
        
    }
    
    func peerConnection(peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
        
    }

    func peerConnection(peerConnection: RTCPeerConnection!, didOpenDataChannel dataChannel: RTCDataChannel!) {
        
    }
}