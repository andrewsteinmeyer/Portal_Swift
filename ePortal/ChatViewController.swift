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
  
  private var firstMessageReceived = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // register observer to listen to broadcast
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshSubscriberCount:", name: Constants.Notifications.BroadcastSubscriberCountDidUpdate, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "displayMessage:", name: Constants.Notifications.BroadcastDidReceiveMessage, object: nil)
    
    chatTextView.delegate = self
    
    //broadcast.delegate = self
    broadcast.startObservingMessages()
    
    setupAppearance()
  }
  
  deinit {
    // stop broadcast from observing messages
    broadcast.stopObservingMessages()
    
    // stop observing notifications
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func setupAppearance() {
    // set backgrounds to be transparent
    chatBarView.backgroundColor = UIColor.clearColor()
    periscommentView.backgroundColor = UIColor.clearColor()
    
    // set initial subscriber count
    subscriberCount.text! = String(broadcast.subscriberCount)
    
    // animate buy button
    buyButton.animation = "fadeInLeft"
    buyButton.curve = "easeIn"
    buyButton.delay = 0.3
    buyButton.duration = 0.3
    buyButton.animate()
  }
  
  //MARK: Notifications
  
  func refreshSubscriberCount(notification: NSNotification) {
    //extract quantity
    let userInfo = notification.userInfo as! [String: AnyObject]
    let count = userInfo["count"] as! Int?
    
    if let unwrappedCount = count {
      subscriberCount.text! = String(unwrappedCount)
    }
  }
  
  func displayMessage(notification: NSNotification) {
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
      self.periscommentView.addCell(profileImage, name: author, comment: comment)
    }
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
