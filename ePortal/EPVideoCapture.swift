//
//  EPVideoCapture.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/17/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//
/*

Video Capture For Manipulating Video 
Might use this later for more fine grained control

import AVFoundation
import AVKit
import UIKit
import CoreVideo
import OpenTok


class EPVideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate, OTVideoCapture {
  
  private var _capture_queue: dispatch_queue_t
  
  private var _videoCaptureConsumer: OTVideoCaptureConsumer
  private var _videoFrame: OTVideoFrame
  
  private var _captureSession: AVCaptureSession!
  private var _videoInput: AVCaptureDeviceInput?
  private var _videoOutput: AVCaptureVideoDataOutput?
  
  private var _captureWidth: UInt32
  private var _captureHeight: UInt32
  private var _capturePreset: String
  private var _capturing: Bool
  
  var availableCaptureSessionPresets: [AnyObject]
  var cameraPosition: AVCaptureDevicePosition
  
  var captureSession: AVCaptureSession {
    get {
      return _captureSession
    }
    set(session) {
      _captureSession = session
    }
  }
  
  var captureSessionPreset: String {
    get {
      return _captureSession.sessionPreset
    }
    set(preset) {
      self.setCaptureSessionPreset(preset)
    }
  }
  
  
  var videoInput: AVCaptureDeviceInput? {
    get {
      return _videoInput
    }
    set(input) {
      _videoInput = input
    }
  }
  
  var videoOutput: AVCaptureVideoDataOutput? {
    get {
      return _videoOutput
    }
    set(output) {
      _videoOutput = output
    }
  }
  
  var videoCaptureConsumer: OTVideoCaptureConsumer {
    get {
      return _videoCaptureConsumer
    }
    set(consumer) {
      _videoCaptureConsumer = consumer
    }
  }
  
  var activeFrameRate: Double {
    get {
      return self.getActiveFrameRate()
    }
    set(rate) {
      self.setActiveFrameRate(rate)
    }
  }
  
  init() {
    availableCaptureSessionPresets = []
    
    _capturePreset = AVCaptureSessionPreset640x480
    (_captureWidth, _captureHeight) = EPVideoCapture.dimensionsForCapturePreset(_capturePreset)
    
    _capture_queue = dispatch_queue_create("com.eportal.EPVideoCapture", DISPATCH_QUEUE_SERIAL)
    _videoFrame = OTVideoFrame(format: OTVideoFormat(NV12WithWidth: _captureWidth, height: _captureHeight))
    
  }
  
  deinit {
    //self.stopCapture
    //self.releaseCapture??
    //_videoFrame release??
    
    //don't think I need any of these anymore
  }
  
  func captureSettings(videoFormat: OTVideoFormat!) -> Int32 {
    videoFormat.pixelFormat = OTPixelFormat.NV12
    videoFormat.imageWidth = _captureWidth
    videoFormat.imageHeight = _captureHeight
  }
  
  func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
    let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
    for device in devices {
      if device.position == position {
        return device
      }
    }
    
    return nil
  }
  
  func frontFacingCamera() -> AVCaptureDevice? {
    return self.cameraWithPosition(AVCaptureDevicePosition.Front)
  }
  
  func backFacingCamera() -> AVCaptureDevice? {
    return self.cameraWithPosition(AVCaptureDevicePosition.Back)
  }
  
  func hasMultipleCameras() -> Bool {
    return (AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)).count > 1
  }
  
  func hasTorch() -> Bool {
    if let input = _videoInput {
      return input.device.hasTorch
    }
  }
  
  func torchMode() -> AVCaptureTorchMode {
    if let input = _videoInput {
      return input.device.torchMode
    }
  }
  
  func setTorchMode(torchMode: AVCaptureTorchMode) {
    if let device = _videoInput?.device {
      if ( device.isTorchModeSupported(torchMode) && device.torchMode != torchMode) {
        if (device.lockForConfiguration(nil) ) {
          device.torchMode = torchMode
          device.unlockForConfiguration()
        } else {
          //handle error
        }
      }
    }
  }
  
  func maxSupportedFrameRate() -> Double {
    let firstRange = _videoInput!.device.activeFormat.videoSupportedFrameRateRanges[0] as! AVFrameRateRange
    
    var bestDuration = firstRange.minFrameDuration as CMTime
    //TODO: Double(UInt32 / UInt64), what does UInt and Double do to them?  Does this work properly?
    var bestFrameRate = Double( UInt64(bestDuration.timescale) / UInt64(bestDuration.value) )
    var currentDuration: CMTime
    var currentFrameRate: Double
    
    let ranges = _videoInput!.device.activeFormat.videoSupportedFrameRateRanges as! [AVFrameRateRange]
    for range in ranges {
      currentDuration = range.minFrameDuration
      //TODO: Double(UInt32 / UInt64), what does UInt and Double do to them?  Does this work properly?
      currentFrameRate = Double( UInt(currentDuration.timescale) / UInt(currentDuration.value) )
      if (currentFrameRate > bestFrameRate) {
        bestFrameRate = currentFrameRate
      }
    }
    
    return bestFrameRate
  }
  
  func isAvailableActiveFrameRate(frameRate: Double) -> Bool {
    return (nil != self.frameRateRangeForFrameRate(frameRate))
  }
  
  func getActiveFrameRate() -> Double {
    let minFrameDuration: CMTime = _videoInput!.device.activeVideoMinFrameDuration
    let framesPerSecond: Double = Double( UInt(minFrameDuration.timescale) / UInt(minFrameDuration.value))
    
    return framesPerSecond
  }
  
  func frameRateRangeForFrameRate(frameRate: Double) -> AVFrameRateRange? {
    let ranges = _videoInput!.device.activeFormat.videoSupportedFrameRateRanges as! [AVFrameRateRange]
    for range in ranges {
      if (range.minFrameRate <= frameRate && frameRate <= range.maxFrameRate) {
        return range
      }
    }
    return nil
  }
  
  func setActiveFrameRate(frameRate: Double) {
    if (_videoInput == nil || _videoOutput == nil) {
      return
    }
    
    let frameRateRange = self.frameRateRangeForFrameRate(frameRate)
    if (frameRateRange == nil) {
      println("unsupported frameRate %f", frameRate)
      return
    }
    
    let desiredMinFrameDuration = CMTimeMake(Int64(1), Int32(frameRate))
    let desiredMaxFrameDuration = CMTimeMake(Int64(1), Int32(frameRate))
    
    _captureSession.beginConfiguration()
    
    var error: NSError?
    if ((_videoInput?.device.lockForConfiguration(&error)) == true) {
      _videoInput?.device.activeVideoMinFrameDuration = desiredMinFrameDuration
      _videoInput?.device.activeVideoMaxFrameDuration = desiredMaxFrameDuration
      _videoInput?.device.unlockForConfiguration()
    }
    else {
      println("Error: %@")
    }
    
    _captureSession.commitConfiguration()
  }
  
  class func dimensionsForCapturePreset(preset: String) -> (UInt32, UInt32) {
    var width: UInt32
    var height: UInt32
    
    switch preset {
    case AVCaptureSessionPreset352x288:
      (width, height) = (352, 288)
    case AVCaptureSessionPreset640x480:
      (width, height) = (640, 480)
    case AVCaptureSessionPreset1280x720:
      (width, height) = (1280, 720)
    case AVCaptureSessionPreset1920x1080:
      (width, height) = (1920, 1080)
    case AVCaptureSessionPresetPhoto:
      // see AVCaptureSessionPresetLow
      (width, height) = (1920, 1080)
    case AVCaptureSessionPresetHigh:
      (width, height) = (640, 480)
    case AVCaptureSessionPresetMedium:
      (width, height) = (480, 360)
    case AVCaptureSessionPresetLow:
      //WARNING: This is a guess, could be wrong for certain devices
      // We will use updateCaptureFormatWithWidth:height if actual output
      // differs from expected value
      (width, height) = (192, 144)
    }
    
    return (width, height)
  }
  
  class func keyPathsForValuesAffectingAvailableCaptureSessionPresets() -> Set<String> {
    let keyPaths: Set = ["captureSession", "videoInput"]
    return keyPaths
  }
  
  func availableCapturePresets() -> [String] {
    var allSessionPresets = [AVCaptureSessionPreset352x288,
                             AVCaptureSessionPreset640x480,
                             AVCaptureSessionPreset1280x720,
                             AVCaptureSessionPreset1920x1080,
                             AVCaptureSessionPresetPhoto,
                             AVCaptureSessionPresetHigh,
                             AVCaptureSessionPresetMedium,
                             AVCaptureSessionPresetLow]
    
    var availableSessionPresets: [String]
    for preset in allSessionPresets {
      if (self.captureSession.canSetSessionPreset(preset)) {
        availableSessionPresets.append(preset)
      }
    }
    
    return availableSessionPresets
  }
  
  func updateCaptureFormatWithWidth(width: UInt32, height: UInt32) {
    _captureWidth = width
    _captureHeight = height
    _videoFrame.format = OTVideoFormat(NV12WithWidth: _captureWidth, height: _captureHeight)
  }
  
  
  func setCaptureSessionPreset(preset: String) {
    let session = self.captureSession
    
    if (session.canSetSessionPreset(preset) && preset != session.sessionPreset) {
      _captureSession.beginConfiguration()
      _captureSession.sessionPreset = preset
      _capturePreset = preset
      
      _videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
      
      _captureSession.commitConfiguration()
    }
  }
  
  func toggleCameraPosition() -> Bool {
    let currentPosition = _videoInput?.device.position
    let newPosition: AVCaptureDevicePosition = (currentPosition == .Back) ? .Front : .Back
    self.setCameraPosition(newPosition)
    
    //TODO: check for success
    return true
  }
  
  func availableCameraPositions() -> [Int] {
    let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
    var result = Set<Int>()
    for device in devices {
      result.insert(device.position.rawValue)
    }
    
    return Array(result)
  }
  
  func setCameraPosition(position: AVCaptureDevicePosition) {
    var success = false
    
    let preset = self.captureSession.sessionPreset
    
    if (self.hasMultipleCameras()) {
      var newVideoInput: AVCaptureDeviceInput?
      var error: NSError?
      
      if (position == AVCaptureDevicePosition.Back) {
        newVideoInput = AVCaptureDeviceInput(device: backFacingCamera(), error: &error)
        self.setTorchMode(AVCaptureTorchMode.Off)
        _videoOutput?.alwaysDiscardsLateVideoFrames = true
      }
      else if (position == AVCaptureDevicePosition.Front) {
        newVideoInput = AVCaptureDeviceInput(device: frontFacingCamera(), error: &error)
        _videoOutput?.alwaysDiscardsLateVideoFrames = true
      } else {
        return
      }
      
      let session = self.captureSession
      if (newVideoInput != nil) {
        session.beginConfiguration()
        session.removeInput(_videoInput)
        if (session.canAddInput(newVideoInput)) {
          session.addInput(newVideoInput)
          _videoInput = newVideoInput
        } else {
          success = false
          session.addInput(_videoInput)
        }
        session.commitConfiguration()
        success = true
      } else if (error != nil) {
        success = false
        //TODO: handle error
        println("error: \(error?.localizedDescription)")
      }
    }
    
    if (success == true) {
      self.setCaptureSessionPreset(preset)
    }
  }
  
  func releaseCapture() {
    self.stopCapture()
    _videoOutput?.setSampleBufferDelegate(nil, queue: nil)
    dispatch_sync(_capture_queue) {
      self._captureSession.stopRunning()
    }
    _captureSession = nil
    _videoOutput = nil
    _videoInput = nil
  }
  
  func initCapture() {
    // Setup capture session.
    _captureSession = AVCaptureSession()
    
    _captureSession.beginConfiguration()
    _captureSession.sessionPreset = _capturePreset
    // Needs to be set in order to receive audio route/interruption events
    _captureSession.usesApplicationAudioSession = false
    
    // Create a video device and input from that device
    // Add the input to the capture session
    let videoDevice = self.frontFacingCamera()
    assert(videoDevice == nil, "No video device found")
    
    // Add the device to the session
    var error: NSError?
    _videoInput = AVCaptureDeviceInput(device: videoDevice, error: &error)
    assert(error != nil, "No input for video device")
    
    _captureSession.addInput(_videoInput)
    
    // Create the output for the capture session.
    _videoOutput = AVCaptureVideoDataOutput()
    _videoOutput?.alwaysDiscardsLateVideoFrames = true
    
    _videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
    _videoOutput?.setSampleBufferDelegate(nil, queue: _capture_queue)
    
    _captureSession.addOutput(_videoOutput)
    _captureSession.commitConfiguration()
    
    _captureSession.startRunning()
    
    self.setActiveFrameRate(Constants.OpenTok.videoCaptureDefaultInitialFrameRate)
  }
  
  func isCaptureStarted() -> Bool {
    return (_captureSession != nil && _capturing == true)
  }
  
  func startCapture() -> Int32 {
    _capturing = true
    return 0
  }
  
  func stopCapture() -> Int32 {
    _capturing = false
    return 0
  }
  
  func currentDeviceOrientation() -> OTVideoOrientation {
    let orientation = UIApplication.sharedApplication().statusBarOrientation
    
    if (AVCaptureDevicePosition.Front == self.cameraPosition) {
      switch orientation {
      case UIInterfaceOrientation.LandscapeLeft:
        return OTVideoOrientation.Up
      case UIInterfaceOrientation.LandscapeRight:
        return OTVideoOrientation.Down
      case UIInterfaceOrientation.Portrait:
        return OTVideoOrientation.Left
      case UIInterfaceOrientation.PortraitUpsideDown:
        return OTVideoOrientation.Right
      }
    } else {
      switch orientation {
      case UIInterfaceOrientation.LandscapeLeft:
        return OTVideoOrientation.Down
      case UIInterfaceOrientation.LandscapeRight:
        return OTVideoOrientation.Up
      case UIInterfaceOrientation.Portrait:
        return OTVideoOrientation.Left
      case UIInterfaceOrientation.PortraitUpsideDown:
        return OTVideoOrientation.Right
      }
    }
    
    return OTVideoOrientation.Up
  }
  
  func captureOutput(captureOutput: AVCaptureOutput!, didDropSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
    
  }
  
  /**
   * Def: sanitary(n): A contigous image buffer with no padding.  All bytes in the 
   * store are actual pixel data
   */
  func imageBufferIsSanitary(imageBuffer: CVImageBufferRef) -> Bool {
    let planeCount: size_t = CVPixelBufferGetPlaneCount(imageBuffer)
    // (Apple bug?) interleaved chroma plane measures in at half of actual size.
    // No idea how many pixel formats this applys to, but we're specifically
    // targeting 4:2:0 here, so there are some assuptions that must be made.
    let biplanar = (2 == planeCount)
    
    for i in 0..<CVPixelBufferGetPlaneCount(imageBuffer) {
      var imageWidth: size_t = CVPixelBufferGetWidthOfPlane(imageBuffer, i) *
                               CVPixelBufferGetHeightOfPlane(imageBuffer, i)
      
      if (biplanar && i == 1) {
        imageWidth *= 2
      }
      
      let dataWidth: size_t = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, i) *
                              CVPixelBufferGetHeightOfPlane(imageBuffer, i)
      
      if (imageWidth != dataWidth) {
        return false
      }
      
      let hasNextAddress = CVPixelBufferGetPlaneCount(imageBuffer) > i + 1
      var nextPlaneContiguous = true
      
      if (hasNextAddress) {
        let planeLength: size_t = dataWidth * CVPixelBufferGetHeightOfPlane(imageBuffer, i)
        
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, i)
        let nextAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, i + 1)
        
        nextPlaneContiguous = &(baseAddress[planeLength]) == nextAddress
      }
      
      if (!nextPlaneContiguous) {
        return false
      }
    }
    
    return true
  }
  
  func sanitizeImageBuffer(imageBuffer: CVImageBufferRef, data: UInt8, planes: NSPointerArray) -> size_t {
    var pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer)
    if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelFormat ||
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelFormat) {
          
        return self.sanitizeBiPlanarImageBuffer(imageBuffer, data: data, planes: planes)
    } else {
      println("No sanitization implementation for pixelFormat %d", pixelFormat)
    }
  }
  
  

}
*/
