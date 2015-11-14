//
//  SubscribeOverlayViewController.swift
//  test
//
//  Created by Andrew Steinmeyer on 10/6/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class SubscribeOverlayViewController: UIViewController {
  
  @IBOutlet weak var quantityButton: DesignableButton!
  @IBOutlet weak var quantityLabel: UILabel!
  @IBOutlet weak var timeRemainingLabel: UILabel!
  
  private var overlayPageViewController: OverlayPageViewController!
  var broadcast: Broadcast!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // register observer to listen to broadcast
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshQuantity:", name: Constants.Notifications.BroadcastQuantityDidUpdate, object: nil)
    
    //set the KVO
    broadcast.addObserver(self, forKeyPath: "timeRemaining", options: NSKeyValueObservingOptions.New, context: nil)
    
    setupAppearance()
  }
  
  deinit {
    //remove the KVO in order to stop watching timer
    broadcast.removeObserver(self, forKeyPath: "timeRemaining")
    
    // stop observing notifications
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  private func setupAppearance() {
    quantityLabel.text! = String(broadcast.quantity)
    timeRemainingLabel.text! = broadcast.timeRemaining
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // pass broadcast to DetailCollectionViewController
    if (segue.identifier == Constants.Segue.OverlayPageControl) {
      overlayPageViewController = segue.destinationViewController as! OverlayPageViewController
      overlayPageViewController.broadcast = broadcast
    }
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if keyPath == "timeRemaining" {
      timeRemainingLabel.text! = broadcast.timeRemaining
      timeRemainingLabel.layer.setNeedsDisplay()
    }
  }
  
  //MARK: Notifications
  
  func refreshQuantity(notification: NSNotification) {
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

