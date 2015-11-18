//
//  BroadcastViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/16/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

/*!
 * BroadcastViewController handles connecting to a session and publishing the broadcast
 */
class BroadcastViewController: UIViewController {
  
  private var session: OTSession!
  private var publisher: OTPublisher!
  private var firstAppearance = true
  private (set) var broadcast: Broadcast!
  
  private var overlayViewController: BroadcastOverlayViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // make view invisible initially
    // do not want to see broadcast view until after the Sale Options view has loaded
    self.view.alpha = 0
    
    // initialize broadcast with firebase ref
    broadcast = Broadcast(root: DatabaseManager.sharedInstance.root, publisherId: DatabaseManager.sharedInstance.userId)
    
    // create overlay and pass broadcast
    overlayViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Constants.BroadcastOverlayVC) as! BroadcastOverlayViewController
    overlayViewController.broadcast = broadcast
    
    // request sessionId and token from opentok using aws lambda
    LambdaHandler.sharedInstance.generateOpentokSessionIdWithToken().continueWithBlock() { [weak self]
      task in
      
      dispatch_async(GlobalMainQueue) {
        if let strongSelf = self {
          var data = JSON(task.result)
          let token = data["token"].string
          let sessionId = data["sessionId"].string
          let apiKey = data["apiKey"].string
          //println("token: \(token),\n apiKey: \(apiKey),\n sessionId: \(sessionId)")
          
          if (apiKey == nil || token == nil || sessionId == nil) {
            print("Error invalid response from aws lambda generateOpentokSessionIdWithToken()")
          }
          else {
            // update broadcast object with sessionId and connect
            // default token expires in 24 hours, do not store apiKey or token locally
            strongSelf.broadcast.sessionId = sessionId!
            strongSelf.doConnectToSession(sessionId!, WithToken: token!, apiKey: apiKey!)
          }
        }
      }
      // end AWS task with nil
      return nil
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    // hide status bar
    UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
    
    // Only present SaleOptionsViewController on first appearance
    // instantiate SaleOptionsViewController and pass the broadcast object
    if firstAppearance {
      let viewController = storyboard!.instantiateViewControllerWithIdentifier(Constants.SaleOptionsVC) as! SaleOptionsViewController
      viewController.broadcast = broadcast
      viewController.delegate = self
      self.presentViewController(viewController, animated: true) {
        // make broadcastViewController's view visible after the SaleOptionsViewController is presented
        // after user dismisses the SaleOptionsViewController, the broadcastViewController will be present
        self.view.alpha = 1
        self.overlayViewController.view.alpha = 1
      }
      firstAppearance = false
    }
  }
  
  private func arrangeOverlayViewController() {
    // set frame equal to current view's bounds
    overlayViewController.view.frame = self.view.bounds
    
    // add BroadcastOverlayViewController
    self.view.addSubview(overlayViewController.view)
    self.addChildViewController(overlayViewController)
    overlayViewController.didMoveToParentViewController(self)
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    arrangeOverlayViewController()
  }
  
  func doConnectToSession(sessionId: String, WithToken token: String, apiKey: String) {
    // Initalize a new instance of OTSession and begin the connection process
    session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self)
    
    if (session != nil) {
      var error: OTError?
      session?.connectWithToken(token, error: &error)
      if error != nil {
        print("Unable to connect to session \(error?.localizedDescription)")
      }
    }
  }
  
  func doPublish() {
    publisher = OTPublisher(delegate: self)
    
    if (publisher != nil) {
      var error: OTError?
      session?.publish(publisher, error: &error)
      if error != nil {
        print("Unable to publish \(error?.localizedDescription)")
      }
      
      // call async so UI can continue
      // seems to speed up publisher presentation
      dispatch_async(GlobalUserInitiatedQueue) {
        publisher?.cameraPosition = .Back
      }
      
      // expand view to entire screen
      publisher?.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
      self.view.addSubview(publisher!.view)
    }
  }
  
  func cleanupPublisher() {
    if (publisher != nil) {
      publisher!.view.removeFromSuperview()
      publisher = nil
    }
  }
  
  override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
    return .Fade
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
}

//MARK: SaleOptionsViewController Delegate

extension BroadcastViewController: SaleOptionsViewControllerDelegate {
  
  func saleOptionsViewControllerDidCancelSale() {
    self.dismissViewControllerAnimated(true, completion: nil)
    
  }
  
  func saleOptionsViewControllerDidStartBroadcast() {
    print("got to start publishing broadcast in broadcast controller")
    doPublish()
  }
}

//MARK: OTSession/Publisher Delegate

extension BroadcastViewController: OTSessionDelegate, OTPublisherDelegate {
  // OTSession
  
  func sessionDidConnect(session: OTSession!) {
    NSLog("session did connect")
  }
  
  func sessionDidDisconnect(session: OTSession!) {
    let alertMessage = "Session disconnected: \(session.sessionId)"
    print("sessionDidDisconnect: \(alertMessage)")
  }
  
  func session(session: OTSession!, streamCreated stream: OTStream!) {
    print("session streamCreated: \(stream.streamId)")
  }
  
  func session(session: OTSession!, streamDestroyed stream: OTStream!) {
    print("session streamDestroyed: \(stream.streamId)")
  }
  
  func session(session: OTSession!, connectionCreated connection: OTConnection!) {
    print("session connectionCreated: \(connection.connectionId)")
  }
  
  func session(session: OTSession!, connectionDestroyed connection: OTConnection!) {
    print("session connectionDestroyed: \(connection.connectionId)")
  }
  
  func session(session: OTSession!, didFailWithError error: OTError!) {
    print("didFailWithError: \(error)")
  }

  // OTPublisher 
  
  func publisher(publisher: OTPublisherKit!, streamCreated stream: OTStream!) {
    broadcast.isPublishing(true, onStream: stream.streamId)
    NSLog("Now publishing on stream...")
    print("StreamId: \(stream.streamId)")
    
    // save broadcast to firebase once the user is publishing
    // broadcast will immediately show up in subscriber's DiscoverCollectionViewController
    // once it is saved to firebase.
    // NOTE: Need delay so that images have time to be uploaded to AWS and cached to Fastly
    //       Otherwise, the DiscoverCollectionViewController sees the new broadcast too quickly
    //       and attempts to download the pictures from Fastly before they have had time to get there.
    afterDelay(2) {
      self.broadcast.setEndTime()
      self.broadcast.saveWithCompletionBlock() {
        error in

        if error != nil {
          print("error saving broadcast to firebase")
        }
        
        self.overlayViewController.populateAndDisplayBroadcastDetails()
      }
    }
  }

  func publisher(publisher: OTPublisherKit!, streamDestroyed stream: OTStream!) {
    broadcast.isPublishing = false
    cleanupPublisher()
  }
  
  func publisher(publisher: OTPublisherKit!, didFailWithError error: OTError) {
    broadcast.isPublishing = false
    print("publisher didFailWithError %@", error)
    cleanupPublisher()
  }
  
}

