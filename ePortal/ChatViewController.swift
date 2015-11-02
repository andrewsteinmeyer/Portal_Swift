//
//  ChatViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/7/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {

  @IBOutlet weak var chatBarView: UIView!
  @IBOutlet weak var periscommentView: PeriscommentView!
  @IBOutlet weak var chatTextView: ChatTextView!
  @IBOutlet weak var subscriberCount: UILabel!
  @IBOutlet weak var quantityButton: DesignableButton!
  @IBOutlet weak var quantityLabel: UILabel!
  @IBOutlet weak var buyButton: DesignableButton!
  @IBOutlet weak var timeRemainingLabel: UILabel!
  
  var broadcast: Broadcast!
  var firstMessageReceived = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    chatTextView.delegate = self
    
    broadcast.delegate = self
    broadcast.startObservingMessages()
    
    //set the KVO
    broadcast.addObserver(self, forKeyPath: "timeRemaining", options: NSKeyValueObservingOptions.New, context: nil)
    
    setupAppearance()
  }
  
  deinit {
    broadcast.stopObservingMessages()
    
    //remove the KVO
    broadcast.removeObserver(self, forKeyPath: "timeRemaining")
  }
  
  func setupAppearance() {
    chatBarView.backgroundColor = UIColor.clearColor()
    periscommentView.backgroundColor = UIColor.clearColor()
    
    subscriberCount.text! = String(broadcast.subscriberCount)
    quantityLabel.text! = String(broadcast.quantity)
    timeRemainingLabel.text! = broadcast.timeRemaining
    
    buyButton.animation = "fadeInLeft"
    buyButton.curve = "easeIn"
    buyButton.delay = 0.5
    buyButton.duration = 1.0
    buyButton.animate()
    
  }
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if keyPath == "timeRemaining" {
      timeRemainingLabel.text! = broadcast.timeRemaining
    }
  }

}

extension ChatViewController: BroadcastDelegate {
  
  func broadcastQuantityDidUpdate(quantity: Int) {
    quantityLabel.text! = String(quantity)
    quantityButton.animation = "flash"
    quantityButton.curve = "easeOutQuad"
    quantityButton.duration = 0.5
    quantityButton.animate()
  }
  
  func broadcastSubscriberCountDidUpdate(count: Int) {
    subscriberCount.text! = String(count)
  }
  
  func broadcastDidReceiveMessage(data: JSON) {
    // don't broadcast first message
    // firebase sends first child initially
    if firstMessageReceived {
      let comment = data["message"].string ?? ""
      let author = data["author"].string ?? ""
      
      let profileImage = UIImage(named: "penny")!
      self.periscommentView.addCell(profileImage, name: author, comment: comment)
    }
    
    // set flag so that all other messages are transmitted
    firstMessageReceived = true
  }
}

extension ChatViewController: UITextViewDelegate {
  
  func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
    if textView is ChatTextView {
      // if return pressed on keyboard
      if (text == "\n") {
        let text = textView.text!
        let strippedMessage = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        // transmit to subscribers
        broadcast.transmitMessage(strippedMessage)
        
        // clear text view
        textView.text = ""
      
        return false
      }
    }
    return true
  }
  
  func textViewDidChange(textView: UITextView) {
    if textView is ChatTextView {
      chatTextView.togglePlaceholder()
      chatTextView.adjustHeight()
    }
  }
  
  func textViewDidEndEditing(textView: UITextView) {
    if textView is ChatTextView {
      chatTextView.togglePlaceholder()
    }
    
  }
}
