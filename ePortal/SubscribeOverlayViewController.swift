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
    
    broadcast.delegate = self
    
    //set the KVO
    broadcast.addObserver(self, forKeyPath: "timeRemaining", options: NSKeyValueObservingOptions.New, context: nil)
    
    setupAppearance()
  }
  
  deinit {
    //remove the KVO
    broadcast.removeObserver(self, forKeyPath: "timeRemaining")
  }
  
  func setupAppearance() {
    quantityLabel.text! = String(broadcast.quantity)
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
  
}


extension SubscribeOverlayViewController: BroadcastDelegate {
  
  func broadcastQuantityDidUpdate(quantity: Int) {
    quantityLabel.text! = String(quantity)
    quantityButton.animation = "flash"
    quantityButton.curve = "easeOutQuad"
    quantityButton.duration = 0.5
    quantityButton.animate()
  }
  
  func broadcastSubscriberCountDidUpdate(count: Int) {
    // stub
  }
  
  func broadcastDidReceiveMessage(data: JSON) {
    // stub
  }
}