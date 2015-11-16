//
//  BroadcastOverlayViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 11/15/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class BroadcastOverlayViewController: UIViewController {
  
  @IBOutlet weak var quantityButton: DesignableButton!
  @IBOutlet weak var quantityLabel: UILabel!
  @IBOutlet weak var timeRemainingLabel: UILabel!
  @IBOutlet weak var remainingLabel: UILabel!
  
  var broadcast: Broadcast!
  
  private var _broadcastDetailsPopulated = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // hide details initially
    toggleBroadcastDetails(hidden: true)
    
    // register observer to listen to broadcast
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshQuantity:", name: Constants.Notifications.BroadcastQuantityDidUpdate, object: nil)
    
    //set the KVO
    broadcast.addObserver(self, forKeyPath: "timeRemaining", options: NSKeyValueObservingOptions.New, context: nil)
  }
  
  deinit {
    //remove the KVO in order to stop watching timer
    broadcast.removeObserver(self, forKeyPath: "timeRemaining")
    
    // stop observing notifications
    NSNotificationCenter.defaultCenter().removeObserver(self)
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
    _broadcastDetailsPopulated = true
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if keyPath == "timeRemaining" {
      timeRemainingLabel.text! = broadcast.timeRemaining
      timeRemainingLabel.layer.setNeedsDisplay()
    }
  }
  
  //MARK: Notifications
  
  func refreshQuantity(notification: NSNotification) {
    
    guard _broadcastDetailsPopulated else {
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
  
}

