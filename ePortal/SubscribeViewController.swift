//
//  SubscribeViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/30/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

/*!
 * SubscribeViewController handles connecting to a session and subscribing to the broadcast
 */
class SubscribeViewController: UIViewController {
  
  private var _session: OTSession!
  private var _subscriber: OTSubscriber!
  private var _broadcast: Broadcast!
  
  private var _overlayViewController: SubscribeOverlayViewController!
  
  var broadcast: Broadcast {
    get {
      return _broadcast
    } set(newBroadcast) {
      _broadcast = newBroadcast
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // create overlay
    _overlayViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Constants.SubscribeOverlayVC) as! SubscribeOverlayViewController
    
    // set frame equal to current view's bounds
    _overlayViewController.view.frame = self.view.bounds
    
    // add SubscriberOverlayViewController
    self.view.addSubview(_overlayViewController.view)
    self.addChildViewController(_overlayViewController)
    _overlayViewController.didMoveToParentViewController(self)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  /**
  * The broadcast is loaded when the subscriber picks a broadcast
  * After the broadcast is loaded, we subscribe the user to the broadcast
  */
  func loadBroadcastFromSnapshot(snapshot: FDataSnapshot) {
    let val: AnyObject! = snapshot.value
    
    // initialize broadcast object for the subscriber
    // extract broadcast data from snapshot
    if (val != nil) {
      let data = JSON(val)
      let publisherId = data["publisherId"].string ?? ""
      
      _broadcast = Broadcast(root: DatabaseManager.sharedInstance.root, publisherId: publisherId)
      _broadcast.extractData(data)
      
      generateOpentokToken()
    }
  }
  
  func generateOpentokToken() {
    let sessionId = _broadcast.sessionId
    
    // request a token for the session so the subscriber can connect to the stream
    LambdaHandler.sharedInstance.generateOpentokTokenForSessionId(sessionId).continueWithBlock() { [weak self]
      task in
      
      dispatch_async(GlobalMainQueue) {
        if let strongSelf = self {
          var data = JSON(task.result)
          let token = data["token"].string
          let apiKey = data["apiKey"].string
          print("Subscribing! token: \(token),\n apiKey: \(apiKey),\n sessionId: \(sessionId)")
          
          if (apiKey == nil || token == nil) {
            print("Error invalid response from aws lambda generateOpentokTokenForSessionId()")
          }
          else {
            // default token expires in 24 hours, do not store apiKey or token locally
            strongSelf.doConnectToSession(sessionId, WithToken: token!, apiKey: apiKey!)
          }
        }
      }
      // end AWS task with nil
      return nil
    }
    
  }
  
  func doConnectToSession(sessionId: String, WithToken token: String, apiKey: String) {
    // Initalize the session and connect the subscriber to the broadcast
    _session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self)
    
    if (_session != nil) {
      var error: OTError?
      _session?.connectWithToken(token, error: &error)
      if error != nil {
        print("Unable to connect to session \(error?.localizedDescription)")
      }
    }
  }
  
  func doSubscribe(stream: OTStream) {
    _subscriber = OTSubscriber(stream: stream, delegate: self)
    
    if (_subscriber != nil) {
      var error: OTError?
      _session?.subscribe(_subscriber, error: &error)
      if error != nil {
        print("Unable to subscribe \(error?.localizedDescription)")
      }
    }
  }
  
  func cleanupSubscriber() {
    if (_subscriber != nil) {
      _subscriber!.view.removeFromSuperview()
      _subscriber = nil
    }
  }
  
  override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
    return .Fade
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
  
}

//MARK: OTSession/Publisher Delegate

extension SubscribeViewController: OTSessionDelegate, OTSubscriberDelegate {
  // OTSession
  
  func sessionDidConnect(session: OTSession!) {
    print("session did connect")
  }
  
  func sessionDidDisconnect(session: OTSession!) {
    let alertMessage = "Session disconnected: \(session.sessionId)"
    print("sessionDidDisconnect: \(alertMessage)")
  }
  
  func session(session: OTSession!, streamCreated stream: OTStream!) {
    print("session streamCreated: \(stream.streamId)")
    
    if (_subscriber == nil) {
      self.doSubscribe(stream)
    }
  }
  
  func session(session: OTSession!, streamDestroyed stream: OTStream!) {
    print("session streamDestroyed: \(stream.streamId)")
    
    if (_subscriber.stream.streamId == stream.streamId) {
      self.cleanupSubscriber()
    }
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
  
  // OTSubscriber
  
  func subscriberDidConnectToStream(subscriber: OTSubscriberKit!) {
    print("subscriberDidConnectToStream \(subscriber.stream.connection.connectionId)")
    
    // expand view to entire screen
    _subscriber?.view.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
    self.view.addSubview(_subscriber!.view)
  }
  
  func subscriber(subscriber: OTSubscriberKit!, didFailWithError error: OTError!) {
    print("subscriber \(subscriber.stream.streamId) didFailWithError \(error)")
  }
  
  func subscriberVideoDataReceived(subscriber: OTSubscriber!) {
    print("subscriber \(subscriber.stream.streamId) videoDataReceived")
  }
  
}
