//
//  BroadcastViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/16/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//



class BroadcastViewController: UIViewController, SaleOptionsViewControllerDelegate {
  
  var _session: OTSession!
  var _publisher: OTPublisher!
  var _broadcast: Broadcast!
  var _firstAppearance = true
  
  var broadcast: Broadcast {
    get {
      return _broadcast
    } set(newBroadcast) {
      _broadcast = newBroadcast
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // make view invisible initially
    // do not want to see broadcast view until after the Sale Options view has loaded
    self.view.alpha = 0
    
    // initialize broadcast
    _broadcast = Broadcast()
    
    //register observer to listen for camera presentation and dismissal
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "stopCapturing", name: Constants.Notification.ImagePickerPresented, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "startCapturing", name: Constants.Notification.ImagePickerDismissed, object: nil)
    
    // request session id and token from opentok using aws lambda
    LambdaHandler.sharedInstance.generateOpentokSessionIdWithToken().continueWithBlock() { [weak self]
      task in
      
      dispatch_async(GlobalMainQueue) {
        if let strongSelf = self {
          var data = JSON(task.result)
          var token = data["token"].string
          var sessionId = data["sessionId"].string
          var apiKey = data["apiKey"].string
          //println("token: \(token),\n apiKey: \(apiKey),\n sessionId: \(sessionId)")
          
          if (apiKey == nil || token == nil || sessionId == nil) {
            println("Error invalid response from generateOpentokSessionIdWithToken")
          }
          else {
            strongSelf.broadcast.saveSessionDetails(sessionId!, token: token!, apiKey: apiKey!)
            strongSelf.doConnect()
          }
        }
      }
      return nil
    }
  }
  
  //make sure to remove this as an observer when cleaning up
  //otherwise, a notification might be sent to a deallocated instance (app could crash)
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    // Only present SaleOptionsViewController on first appearance
    // instantiate SaleOptionsViewController and pass the broadcast data
    if _firstAppearance {
      let viewController = storyboard!.instantiateViewControllerWithIdentifier(Constants.SaleOptionsVC) as! SaleOptionsViewController
      viewController.broadcast = broadcast
      viewController.delegate = self
      self.presentViewController(viewController, animated: true) {
        // make broadcastViewController's view visible after the SaleOptionsViewController is presented
        // after user dismisses the SaleOptionsViewController, the broadcastViewController will be present
        self.view.alpha = 1
      }
      _firstAppearance = false
    }
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
  }
  
  func doConnect() {
    // Initalize a new instance of OTSession and begin the connection process
    _session = OTSession(apiKey: broadcast.apiKey, sessionId: broadcast.sessionId, delegate: self)
    
    if (_session != nil) {
      var error: OTError?
      _session?.connectWithToken(broadcast.token, error: &error)
      if error != nil {
        println("Unable to connect to session \(error?.localizedDescription)")
      }
    }
  }
  
  func doPublish() {
    _publisher = OTPublisher(delegate: self)
    
    if (_session != nil && _publisher != nil) {
      var error: OTError?
      _session?.publish(_publisher, error: &error)
      if error != nil {
        println("Unable to publish \(error?.localizedDescription)")
      }
      
      // call async so ui can continue
      dispatch_async(GlobalUserInitiatedQueue) {
        self._publisher?.cameraPosition = .Back
      }
      
      _publisher?.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
      self.view.addSubview(_publisher!.view)
    }
  }
  
  func stopCapturing() {
    println("got to stop capture after imagepicker presented")
    _publisher?.videoCapture.stopCapture()
  }
  
  func startCapturing() {
    println("got to start capture after imagepicker dismissed")
    _publisher?.videoCapture.startCapture()
    // call async so ui can continue
    dispatch_async(GlobalUserInitiatedQueue) {
      self._publisher?.cameraPosition = .Back
    }
  }
  
  func cleanupPublisher() {
    if (_publisher != nil) {
      _publisher!.view.removeFromSuperview()
      _publisher = nil
    }
  }
  
  override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
    return .Fade
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
}

extension BroadcastViewController: SaleOptionsViewControllerDelegate {
  
  func saleOptionsViewControllerDidCancelSale() {
    self.dismissViewControllerAnimated(false, completion: nil)
  }
}


extension BroadcastViewController: OTSessionDelegate, OTPublisherDelegate {
  //MARK: OTSessionDelegate Callbacks
  
  func sessionDidConnect(session: OTSession!) {
    NSLog("session did connect")
    //self.doPublish()
  }
  
  func sessionDidDisconnect(session: OTSession!) {
    let alertMessage = "Session disconnected: \(session.sessionId)"
    println("sessionDidDisconnect: \(alertMessage)")
  }
  
  func session(session: OTSession!, streamCreated stream: OTStream!) {
    println("session streamCreated: \(stream.streamId)")
   
  }
  
  func session(session: OTSession!, streamDestroyed stream: OTStream!) {
    println("session streamDestroyed: \(stream.streamId)")
  }
  
  func session(session: OTSession!, connectionCreated connection: OTConnection!) {
    println("session connectionCreated: \(connection.connectionId)")
  }
  
  func session(session: OTSession!, connectionDestroyed connection: OTConnection!) {
    println("session connectionDestroyed: \(connection.connectionId)")
  }
  
  func session(session: OTSession!, didFailWithError error: OTError!) {
    println("didFailWithError: \(error)")
  }

  //MARK: OTPublisher delegate callbacks
  
  func publisher(publisher: OTPublisherKit!, streamCreated stream: OTStream!) {
    broadcast.isPublishing(true, onStream: stream.streamId)
    NSLog("Now publishing")
    println("StreamId: \(stream.streamId)")
    _publisher.videoCapture.stopCapture()
  }

  func publisher(publisher: OTPublisherKit!, streamDestroyed stream: OTStream!) {
    self.cleanupPublisher()
  }
  
  func publisher(publisher: OTPublisherKit!, didFailWithError error: OTError) {
    println("publisher didFailWithError %@", error)
    self.cleanupPublisher()
  }
  
}

