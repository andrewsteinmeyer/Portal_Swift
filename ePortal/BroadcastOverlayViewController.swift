//
//  BroadcastOverlayViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 11/15/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class BroadcastOverlayViewController: UIViewController {
  
  @IBOutlet weak var commentView: PeriscommentView!
  @IBOutlet weak var quantityButton: DesignableButton!
  @IBOutlet weak var quantityLabel: UILabel!
  @IBOutlet weak var timeRemainingLabel: UILabel!
  @IBOutlet weak var remainingLabel: UILabel!
  @IBOutlet weak var subscriberCount: UILabel!
  
  var broadcast: Broadcast!
  
  private var firstMessageReceived = false
  private var broadcastDetailsPopulated = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // hide details initially
    toggleBroadcastDetails(hidden: true)
    
    // register observer to listen to broadcast
    registerNotifications()
    
    // monitor user messages
    broadcast.startObservingMessages()
    
    //set the KVO
    broadcast.addObserver(self, forKeyPath: "timeRemaining", options: NSKeyValueObservingOptions.New, context: nil)
    
    setupAppearance()
  }
  
  deinit {
    //remove the KVO in order to stop watching timer
    broadcast.removeObserver(self, forKeyPath: "timeRemaining")
    
    // stop broadcast from observing messages
    broadcast.stopObservingMessages()
    
    // stop observing notifications
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func setupAppearance() {
    // set backgrounds to be transparent
    commentView.backgroundColor = UIColor.clearColor()
    
    // set initial subscriber count
    subscriberCount.text! = String(broadcast.subscriberCount)
  }
  
  func toggleBroadcastDetails(hidden hidden: Bool) {
    if hidden == true {
      timeRemainingLabel.alpha = 0
      quantityLabel.alpha = 0
      quantityButton.alpha = 0
      remainingLabel.alpha = 0
    }
    else {
      timeRemainingLabel.alpha = 1
      quantityLabel.alpha = 1
      quantityButton.alpha = 1
      remainingLabel.alpha = 1
    }
  }
  
  func populateAndDisplayBroadcastDetails() {
    quantityLabel.text! = String(broadcast.quantity)
    timeRemainingLabel.text! = broadcast.timeRemaining
    
    toggleBroadcastDetails(hidden: false)
    broadcastDetailsPopulated = true
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if keyPath == "timeRemaining" {
      timeRemainingLabel.text! = broadcast.timeRemaining
      timeRemainingLabel.layer.setNeedsDisplay()
    }
  }
  
}

//MARK: Notifications

extension BroadcastOverlayViewController {
  
  func registerNotifications() {
    // register observer to listen to broadcast
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshQuantity:", name: Constants.Notifications.BroadcastQuantityDidUpdate, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshSubscriberCount:", name: Constants.Notifications.BroadcastSubscriberCountDidUpdate, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "displayMessage:", name: Constants.Notifications.BroadcastDidReceiveMessage, object: nil)
  }
  
  func refreshQuantity(notification: NSNotification) {
    guard broadcastDetailsPopulated else {
      return
    }
    
    //extract quantity
    let userInfo = notification.userInfo as! [String: AnyObject]
    let quantity = userInfo["quantity"] as! Int?
    
    if let unwrappedQuantity = quantity {
      quantityLabel.text! = String(unwrappedQuantity)
      quantityButton.animation = "flash"
      quantityButton.curve = "easeOutQuad"
      quantityButton.duration = 0.5
      quantityButton.animate()
    }
  }
  
  func refreshSubscriberCount(notification: NSNotification) {
    //extract quantity
    let userInfo = notification.userInfo as! [String: AnyObject]
    let count = userInfo["count"] as! Int?
    
    if let unwrappedCount = count {
      subscriberCount.text! = String(unwrappedCount)
    }
  }
  
  func displayMessage(notification: NSNotification) {
    
    print("message received")
    //extract message
    let userInfo = notification.userInfo as! [String: AnyObject]
    let data = userInfo["message"]
    
    if let unwrappedMessage = data {
      // firebase sends last message after registering for updates
      // so ignore first message
      guard firstMessageReceived else {
        firstMessageReceived = true
        return
      }
      
      let message = JSON(unwrappedMessage)
      let comment = message["comment"].string ?? ""
      let author = message["author"].string ?? ""
      
      let profileImage = UIImage(named: "penny")!
      commentView.addCell(profileImage, name: author, comment: comment)
    }
  }
  
}

