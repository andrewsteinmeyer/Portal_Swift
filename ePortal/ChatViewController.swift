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

  @IBOutlet weak var buyButton: DesignableButton!

  
  var broadcast: Broadcast!
  var firstMessageReceived = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    chatTextView.delegate = self
    
    broadcast.delegate = self
    broadcast.startObservingMessages()
    
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
    
    buyButton.animation = "fadeInLeft"
    buyButton.curve = "easeIn"
    buyButton.delay = 0.3
    buyButton.duration = 1.0
    buyButton.animate()
  }

}

extension ChatViewController: BroadcastDelegate {
  
  func broadcastQuantityDidUpdate(quantity: Int) {
    // stub
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
