//
//  Broadcast.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/31/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import WebImage

typealias FSaveCompletionBlock = (error: NSError?) -> Void

protocol BroadcastDelegate: class {
  func broadcastSubscriberCountDidUpdate(count: Int) -> Void
  func broadcastQuantityDidUpdate(quantity: Int) -> Void
  func broadcastDidReceiveMessage(data: JSON) -> Void
}

// information for broadcast
class Broadcast: NSObject {
  
  weak var delegate: BroadcastDelegate?
  
  private var _ref: Firebase!
  private var _valueHandle: UInt?
  private var _messagesRef: Firebase!
  private var _messagesHandle: UInt?
  
  private var _publisherId: String!
  private var _subscriberId: String!
  private var _broadcastId: String!
  private var _sessionId: String!
  private var _isPublishing: Bool!
  private var _streamId: String!
  
  private var _title: String!
  private var _description: String!
  private var _price: Double!
  private var _readableDuration: String!
  private var _endTime: Double!
  private var _timeRemaining: String!
  private var _readableEndTime: String!
  private var _timer: NSTimer?
  private var _quantity: Int!
  private var _imageUrls: [String]!
  private var _downloadedImages: [UIImage]!
  
  //TODO: list of people watching
  private var _subscriberIds: [String]!
  private var _subscriberCount: Int!
  
  var publisherId: String {
    get {
      return _publisherId
    }
  }
  
  var broadcastId: String {
    get {
      return _broadcastId
    }
  }
  
  var title: String {
    get {
      return _title
    }
  }
  
  var isPublishing: Bool! {
    get {
      return _isPublishing
    }
    set(newValue) {
      _isPublishing = newValue
    }
  }
  
  var subscriberCount: Int! {
    get {
      return _subscriberCount
    }
    set(newValue) {
      _subscriberCount = newValue
    }
  }
  
  var sessionId: String {
    get {
      return _sessionId
    }
    set(newId) {
      _sessionId = newId
    }
  }
  
  var streamId: String {
    get {
      return _streamId
    }
  }
  
  dynamic private(set) var timeRemaining: String {
    get {
      return _timeRemaining
    }
    set(newValue) {
      _timeRemaining = newValue
    }
  }
  
  var downloadedImages: [UIImage] {
    get {
      return _downloadedImages
    }
  }
  
  var quantity: Int {
    get {
      return _quantity
    }
  }
  
  init(root: Firebase, broadcastId: String) {
    
    // url to the publisher's broadcast
    _ref = root.childByAppendingPath("broadcasts").childByAppendingPath(broadcastId)
    _messagesRef = root.childByAppendingPath("messages").childByAppendingPath(broadcastId)
    
    _broadcastId = broadcastId
    _isPublishing = false
    _imageUrls = []
    _downloadedImages = []
    
    _quantity = 0
    
    //TODO: list of people watching
    _subscriberIds = []
    _subscriberCount = 0
    
  }
  
  /*!
   * Initializer for when the user creates a new broadcast to publish
   */
  convenience init(root: Firebase, publisherId: String!) {
    // TODO: Bug - app crashes if we don't have userId by the time the user clicks the "Broadcast" tab item
    
    // set broadcastId as the userId plus a timestamp
    let broadcastId = "\(publisherId)-\(timeStamp())"
    
    // init
    self.init(root: root, broadcastId: broadcastId)

    // set publisherId and listen for updates
    _publisherId = publisherId
    startObserving()
  }
  
  /*!
   * Initializer for when the user subscribes to a broadcast already in session
   */
  convenience init(root: Firebase, snapshot: FDataSnapshot, subscriberId: String!) {
    let val: AnyObject! = snapshot.value
    
    let data = JSON(val)
    let broadcastId = snapshot.key
    
    //print("broadcastId: \(broadcastId)")
    //print("subscriberId: \(subscriberId)")
    
    // init
    self.init(root: root, broadcastId: broadcastId)
    
    // unpackage the snapshot
    // populate broadcast object with downloaded data
    extractData(data)
    
    // set subscriberId and listen for updates
    _subscriberId = subscriberId
    startObserving()
    
    // start timer
    startCountdown()
  }
  
  /*!
   * Register to watch for changes at firebase urls
   */
  func startObserving() {
    // listen for updates to the broadcast
    self._valueHandle = _ref.observeEventType(FEventType.Value, withBlock: { [weak self]
      snapshot in
      
      if let strongSelf = self {
        let val: AnyObject! = snapshot.value
        
        if (val is NSNull) {
          // no value found
        }
        else {
          // update data for user from firebase snapshot
          let data = JSON(val)
          strongSelf._isPublishing = data["isPublishing"].bool
          strongSelf._streamId = data["streamId"].string
          strongSelf._quantity = data["quantity"].int
          
          if let quantity = data["quantity"].int {
            strongSelf._quantity = quantity
            strongSelf.delegate?.broadcastQuantityDidUpdate(quantity)
          }
          
          if let count = data["subscriberCount"].int {
            strongSelf._subscriberCount = count
            strongSelf.delegate?.broadcastSubscriberCountDidUpdate(count)
          }
          
          //print("update isPublishing: \(strongSelf._isPublishing)")
          //print("update streamId: \(strongSelf._streamId)")
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
    self._messagesHandle = _messagesRef.queryLimitedToLast(1).observeEventType(.ChildAdded, withBlock: { [weak self]
      snapshot in
    
      if let strongSelf = self {
        let val: AnyObject! = snapshot.value
        
        if (val is NSNull) {
          // no message
        }
        else {
          // new message received
          let data = JSON(val)
          strongSelf.delegate?.broadcastDidReceiveMessage(data)
          
        }
      }
    })
  }
  
  /*!
   * Send a message to the subscribers
   */
  func transmitMessage(text: String) {
    // auto-increment
    let messageRef = _messagesRef.childByAutoId()
    
    let newMessage: [String: String] = [
                      "author": _subscriberId,
                      "message": text,
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
    if (_valueHandle != nil) {
      _ref.removeObserverWithHandle(_valueHandle!)
      _valueHandle = nil
    }
    if (_messagesHandle != nil) {
      _messagesRef.removeObserverWithHandle(_messagesHandle!)
      _messagesHandle = nil
    }
    if let timer = _timer {
      timer.invalidate()
    }
  }
  
  /*!
   * Remove the messages observer and clear the handle
   */
  func stopObservingMessages() {
    if (_messagesHandle != nil) {
      _messagesRef.removeObserverWithHandle(_messagesHandle!)
      _messagesHandle = nil
    }
  }
  
  /*!
   * Broadcast is now publishing on a stream
   */
  func isPublishing(publishing: Bool, onStream streamId: String) {
    _isPublishing = publishing
    _streamId = streamId
  }
  
  /*!
   * Set details of the broadcast from what the user entered
   * User enters details before publishing
   */
  func setDetails(title: String, description: String, price: String, duration: String, quantity: String) {
    _title = title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    _description = description.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    _price = Double(price)
    _readableDuration = duration.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    _quantity = Int(quantity)
  }
  
  func addImageUrl(imageUrl: String) {
    _imageUrls.append(imageUrl)
  }
  
  /*!
   * End time is set using the end time stored in firebase
   * The countdown for the sale will be calculated using the end time
   */
  func setEndTime() {
    // get server time
    let timestamp = DatabaseManager.sharedInstance.serverTimestampInMilliseconds()
    
    let clockParts = _readableDuration.componentsSeparatedByString(":")
    let minutes = Double(clockParts[0])
    let seconds = clockParts.count > 1 ? Double(clockParts[1]) : 0.0
    
    // get duration
    let millisecondsInFuture = (minutes! * 60 + seconds!) * 1000
    
    // set end time
    _endTime = timestamp + millisecondsInFuture
    _readableEndTime = getFormattedTime(_endTime)
  }
  
  /*!
   * The broadcast keeps record of the countdown when a subscriber starts watching
   * The countdown is based off of the official end time stored in the database
   * The client checks the countdown every second
   */
  func startCountdown() {
    _timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateCountdown"), userInfo: nil, repeats: true)
  }
  
  /*!
   * The end time is the official end time stored in the database
   */
  func updateCountdown() {
    let millisecondsRemaining = _endTime - DatabaseManager.sharedInstance.serverTimestampInMilliseconds()
    
    if millisecondsRemaining > 0 {
      let (m,s) = millisecondsToMinutesSeconds(millisecondsRemaining)
      
      switch m {
      case _ where m > 1:
        _timeRemaining = (s < 10) ? "\(m):0\(s)" : "\(m):\(s)"
      case _ where m < 1:
        _timeRemaining = (s < 10) ? "00:0\(s)" : "00:\(s)"
      default:
        break
      }
    } else {
      _timeRemaining = "00:00"
      
      if let timer = _timer {
        timer.invalidate()
      }
    }
    
    // set accessible property
    // this triggers KVO
    timeRemaining = _timeRemaining
    
  }
  
  /*!
   * Build the broadcast and save it to firebase
   */
  func saveWithCompletionBlock(block: FSaveCompletionBlock) {
    // build broadcast
    var newBroadcast: [String: AnyObject] = [
                        "publisherId": _publisherId,
                        "sessionId": _sessionId,
                        "streamId": _streamId,
                        "isPublishing": _isPublishing,
                        "title": _title,
                        "description": _description,
                        "price": _price,
                        "readableDuration": _readableDuration,
                        "endTime": _endTime,
                        "readableEndTime": _readableEndTime,
                        "quantity": _quantity,
                        "subscriberCount": _subscriberCount
                        ]
    // add images
    // image1: url
    if let urls = _imageUrls {
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
    _ref.setValue(newBroadcast) {
      (error: NSError?, ref: Firebase!) in
      
      if error != nil {
        block(error: error)
      } else {
        block(error: nil)
      }
    }
  }
  
  /*!
   * Extract the data for the broadcast and store it on the broadcast object.
   */
  func extractData(data: JSON) {
    // get the sessionId
    _sessionId = data["sessionId"].string ?? ""
    _streamId = data["streamId"].string ?? ""
    
    _publisherId = data["publisherId"].string ?? ""
    _isPublishing = data["isPublishing"].bool ?? false
    
    _title = data["title"].string ?? ""
    _description = data["description"].string ?? ""
    _price = data["price"].double ?? 0.0
    _quantity = data["quantity"].int ?? 0
    _readableDuration = data["readableDuration"].string ?? ""
    _endTime = data["endTime"].double ?? 0.0
    
    _subscriberCount = data["subscriberCount"].int ?? 0
    
    for (_, url):(String, JSON) in data["photos"] {
      // if we have an image url, save it
      if let imageUrl = url.string {
        _imageUrls.append(imageUrl)
        
        // construct url
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
            self._downloadedImages.append(image)
            
            //send notification 
            NSNotificationCenter.defaultCenter().postNotificationName("DownloadImageNotification", object: self, userInfo: ["images": self._downloadedImages])
          }
        })
      }
    }
  }
  
}
