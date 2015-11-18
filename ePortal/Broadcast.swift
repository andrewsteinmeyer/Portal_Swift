//
//  Broadcast.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/31/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import WebImage

typealias FSaveCompletionBlock = (error: NSError?) -> Void

// information for broadcast
class Broadcast: NSObject {
  
  private var ref: Firebase!
  private var valueHandle: UInt?
  private var messagesRef: Firebase!
  private var messagesHandle: UInt?
  private var subscribersRef: Firebase!
  private var subscribersHandle: UInt?
  
  private (set) var publisherId: String!
  private (set) var subscriberId: String!
  private (set) var broadcastId: String!
  private (set) var streamId: String!
  var sessionId: String!
  var isPublishing: Bool!
  
  private (set) var title: String!
  private (set) var shortDescription: String!
  private (set) var price: Double!
  private (set) var readableDuration: String!
  private (set) var endTime: Double!
  dynamic private (set) var timeRemaining: String!
  private (set) var readableEndTime: String!
  private (set) var timer: NSTimer?
  private (set) var quantity: Int!
  private (set) var imageUrls: [String]!
  private (set) var downloadedImages: [UIImage]!
  
  //TODO: list of people watching
  private var subscriberIds: [String]!
  var subscriberCount: Int!
  
  
  init(root: Firebase, broadcastId id: String) {
    // url to the publisher's broadcast
    ref = root.childByAppendingPath("broadcasts").childByAppendingPath(id)
    messagesRef = root.childByAppendingPath("messages").childByAppendingPath(id)
    //subscribersRef = root.childByAppendingPath("subscribers").childByAppendingPath(id)
    
    broadcastId = id
    isPublishing = false
    imageUrls = []
    downloadedImages = []
    quantity = 0
    
    //TODO: list of people watching
    subscriberIds = []
    subscriberCount = 0
  }
  
  /*!
   * Initializer for when the user creates a new broadcast to publish
   */
  convenience init(root: Firebase, publisherId id: String!) {
    // TODO: Bug - app crashes if we don't have userId by the time the user clicks the "Broadcast" tab item
    
    // set broadcastId as the userId plus a timestamp
    let broadcastId = "\(id)-\(timeStamp())"
    
    // initialize
    self.init(root: root, broadcastId: broadcastId)

    // set publisherId and listen for updates
    publisherId = id
    startObserving()
  }
  
  /*!
   * Initializer for when the user subscribes to a broadcast already in session
   */
  convenience init(root: Firebase, snapshot: FDataSnapshot, subscriberId id: String!) {
    let val: AnyObject! = snapshot.value
    
    let data = JSON(val)
    let broadcastId = snapshot.key
    
    // initialize
    self.init(root: root, broadcastId: broadcastId)
    
    // unpackage the snapshot
    // populate broadcast object with downloaded data
    extractData(data)
    
    // set subscriberId and listen for updates
    subscriberId = id
    startObserving()
    
    // start timer
    startCountdown()
  }
  
  /*!
   * Register to watch for changes at firebase urls
   */
  func startObserving() {
    // listen for updates to the broadcast
    self.valueHandle = ref.observeEventType(FEventType.Value, withBlock: { [weak self]
      snapshot in
      
      if let strongSelf = self {
        let val: AnyObject! = snapshot.value
        
        if (val is NSNull) {
          // no value found
        }
        else {
          // update data for user from firebase snapshot
          let data = JSON(val)
          strongSelf.isPublishing = data["isPublishing"].bool
          strongSelf.streamId = data["streamId"].string
          
          if let quantity = data["quantity"].int {
            strongSelf.quantity = quantity
            strongSelf.sendQuantityUpdatedNotification(quantity)
          }
          
          if let count = data["subscriberCount"].int {
            strongSelf.subscriberCount = count
            strongSelf.sendSubscriberCountUpdatedNotification(count)
          }
        }
      }
    })
  }
  
  /*!
   * Register to watch for messages transmitted by subscribers
   * Only watch for most recent message that was sent
   */
  func startObservingMessages() {
    // listen for new messages
    messagesHandle = messagesRef.queryLimitedToLast(1).observeEventType(.ChildAdded, withBlock: { [weak self]
      snapshot in
    
      if let strongSelf = self {
        let val: AnyObject! = snapshot.value
        
        if (val is NSNull) {
          // no message
        }
        else {
          print("broadcast: \(val)")
          // new message received
          let message = val
          strongSelf.sendBroadcastDidReceiveMessageNotification(message)
          
        }
      }
    })
  }
  
  func transmitMessageFromSubscriber(text: String) {
    guard (subscriberId != nil) else {
      return
    }
    
    transmitMessage(author: subscriberId, text: text)
  }
  
  /*!
   * Send a message to the subscribers
   */
  func transmitMessage(author author: String, text: String) {
    // auto-increment
    let messageRef = messagesRef.childByAutoId()
    
    let newMessage: [String: String] = [
                      "author": author,
                      "comment": text,
                      "timestamp": timeStamp()
                      ]
    
    // save to firebase
    messageRef.setValue(newMessage) {
      (error: NSError?, ref: Firebase!) in
      
      if error != nil {
        print("error saving message to firebase")
        //block(error: error)
      } else {
        print("message saved to firebase!")
        //block(error: nil)
      }
    }
  }
  
  /*!
   * Remove all observers and clear the observer handles
   */
  func stopObserving() {
    if (valueHandle != nil) {
      ref.removeObserverWithHandle(valueHandle!)
      valueHandle = nil
    }
    if (messagesHandle != nil) {
      messagesRef.removeObserverWithHandle(messagesHandle!)
      messagesHandle = nil
    }
    if let timer = timer {
      timer.invalidate()
    }
  }
  
  /*!
   * Remove the messages observer and clear the handle
   */
  func stopObservingMessages() {
    if (messagesHandle != nil) {
      messagesRef.removeObserverWithHandle(messagesHandle!)
      messagesHandle = nil
    }
  }
  
  /*!
   * Broadcast is now publishing on a stream
   */
  func isPublishing(publishing: Bool, onStream stream: String) {
    isPublishing = publishing
    streamId = stream
  }
  
  /*!
   * Set details of the broadcast from what the user entered
   * User enters details before publishing
   */
  func setDetails(title t: String, description d: String, price p: String, duration dur: String, quantity q: String) {
    title = t.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    shortDescription = d.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    price = Double(p)
    readableDuration = dur.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    quantity = Int(q)
  }
  
  func addImageUrl(imageUrl: String) {
    imageUrls.append(imageUrl)
  }
  
  /*!
   * End time is set using the end time stored in firebase
   * The countdown for the sale will be calculated using the end time
   */
  func setEndTime() {
    // get server time
    let timestamp = DatabaseManager.sharedInstance.serverTimestampInMilliseconds()
    
    let clockParts = readableDuration.componentsSeparatedByString(":")
    let minutes = Double(clockParts[0])
    let seconds = clockParts.count > 1 ? Double(clockParts[1]) : 0.0
    
    // get duration
    let millisecondsInFuture = (minutes! * 60 + seconds!) * 1000
    
    // set end time
    endTime = timestamp + millisecondsInFuture
    readableEndTime = getFormattedTime(endTime)
  }
  
  /*!
   * The broadcast keeps a local record of the countdown
   * The countdown is based off of the official end time stored in the database
   * The client checks the countdown every second
   */
  func startCountdown() {
    timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateCountdown"), userInfo: nil, repeats: true)
    
    // use NSRunLoopCommonModes so timer continues to countdown when user interacts with screen
    NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
  }
  
  /*!
   * Called to update the countdown timer
   * The end time is the official end time stored in the database
   */
  func updateCountdown() {
    let millisecondsRemaining = endTime - DatabaseManager.sharedInstance.serverTimestampInMilliseconds()
    
    if millisecondsRemaining > 0 {
      let (m,s) = millisecondsToMinutesSeconds(millisecondsRemaining)
      
      switch m {
      case _ where m > 1:
        timeRemaining = (s < 10) ? "\(m):0\(s)" : "\(m):\(s)"
      case _ where m < 1:
        timeRemaining = (s < 10) ? "00:0\(s)" : "00:\(s)"
      default:
        break
      }
    } else {
      timeRemaining = "00:00"
      
      if let timer = timer {
        timer.invalidate()
      }
    }
  }
  
  /*!
   * Build the broadcast and save it to firebase
   */
  func saveWithCompletionBlock(block: FSaveCompletionBlock) {
    // build broadcast
    var newBroadcast: [String: AnyObject] = [
                        "publisherId": publisherId,
                        "sessionId": sessionId,
                        "streamId": streamId,
                        "isPublishing": isPublishing,
                        "title": title,
                        "description": description,
                        "price": price,
                        "readableDuration": readableDuration,
                        "endTime": endTime,
                        "readableEndTime": readableEndTime,
                        "quantity": quantity,
                        "subscriberCount": subscriberCount
                        ]
    // add images
    // image1: url
    if let urls = imageUrls {
      var imageCount = 0
      var images = [String: String]()
      for imageUrl in urls {
        imageCount++
        let key = "image" + String(imageCount)
        images[key] = imageUrl
      }
      
      // add photos that user selected
      newBroadcast.unionInPlace([ "photos": images])
    }
    
     // save to firebase
    ref.setValue(newBroadcast) {
      (error: NSError?, ref: Firebase!) in
      
      if error != nil {
        block(error: error)
      } else {
        
        // add first message to database for this broadcast
        // this is to get around child_added issue
        // message listeners will ignore first message
        self.transmitMessage(author: "Application", text: "Populating with first message")
        
        // set the timer and start it
        self.updateCountdown()
        self.startCountdown()
        block(error: nil)
      }
    }
    

  }
  
  /*!
   * Extract the data for the broadcast and store it on the broadcast object.
   */
  func extractData(data: JSON) {
    // get the sessionId
    sessionId = data["sessionId"].string ?? ""
    streamId = data["streamId"].string ?? ""
    
    publisherId = data["publisherId"].string ?? ""
    isPublishing = data["isPublishing"].bool ?? false
    
    title = data["title"].string ?? ""
    shortDescription = data["description"].string ?? ""
    price = data["price"].double ?? 0.0
    quantity = data["quantity"].int ?? 0
    readableDuration = data["readableDuration"].string ?? ""
    endTime = data["endTime"].double ?? 0.0
    
    subscriberCount = data["subscriberCount"].int ?? 0
    
    // set initial countdown for timer
    updateCountdown()
    
    for (_, url):(String, JSON) in data["photos"] {
      // if we have an image url, save it
      if let imageUrl = url.string {
        imageUrls.append(imageUrl)
        
        // construct Fastly image url
        let cacheUrl = Constants.Fastly.RootUrl.stringByAppendingString(imageUrl)
        let url = NSURL(string: cacheUrl)
        
        // request cached image from Fastly
        SDWebImageManager.sharedManager().downloadImageWithURL(url!, options: SDWebImageOptions(rawValue: 0), progress: nil, completed: {
          (image: UIImage!, error: NSError!, type: SDImageCacheType, finished: Bool, url: NSURL!) in
          
          if error != nil {
            print(error)
          }
          else {
            print("cached image successfully fetched and storing on broadcast")
            self.downloadedImages.append(image)
            
            //send notification 
            self.sendImageDownloadedNotification(image)
          }
        })
      }
    }
  }
  
  //MARK: NSNotifications
  
  private func sendImageDownloadedNotification(image: UIImage) {
    NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notifications.BroadcastImageDidDownload, object: self, userInfo: ["image": image])
  }
  
  private func sendQuantityUpdatedNotification(quantity: Int) {
    NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notifications.BroadcastQuantityDidUpdate, object: self, userInfo: ["quantity": quantity])
  }
  
  private func sendSubscriberCountUpdatedNotification(count: Int) {
    NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notifications.BroadcastSubscriberCountDidUpdate, object: self, userInfo: ["count": count])
  }
  
  private func sendBroadcastDidReceiveMessageNotification(message: AnyObject) {
    NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notifications.BroadcastDidReceiveMessage, object: self, userInfo: ["message": message])
  }
  
}
