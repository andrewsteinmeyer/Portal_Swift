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
class Broadcast {
  private var _ref: Firebase
  private var _valueHandle: UInt?
  
  private var _publisherId: String!
  private var _broadcastId: String!
  private var _sessionId: String!
  private var _isPublishing: Bool!
  private var _streamId: String!
  
  private var _title: String!
  private var _description: String!
  private var _price: Double!
  private var _allottedTime: String!
  private var _quantity: Int!
  private var _imageUrls: [String]!
  private var _downloadedImages: [UIImage]!
  
  private var _subscriberIds: [String]!
  
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
  
  var isPublishing: Bool! {
    get {
      return _isPublishing
    }
    set(newValue) {
      _isPublishing = newValue
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
  
  var downloadedImages: [UIImage] {
    get {
      return _downloadedImages
    }
  }
  
  var description: String {
    get {
      return _description
    }
  }
  
  init(root: Firebase, publisherId: String!) {
    // set broadcast url path
    // TODO: Bug - app crashes if we don't have userId by the time the user clicks the "Broadcast" tab item
    
    // set broadcastId as the userId with timestamp appended
    let broadcastId = "\(publisherId)-\(timeStamp())"
    let broadcastRef = root.childByAppendingPath("broadcasts").childByAppendingPath(broadcastId)
    
    // url to the publisher's broadcast
    _ref = broadcastRef
    _publisherId = publisherId
    _broadcastId = broadcastId
    _isPublishing = false
    _imageUrls = []
    _downloadedImages = []
    
    // list of people watching
    _subscriberIds = []
    
    // register to watch for changes at broadcast url in firebase
    // changes are specific to this particular broadcast at root/broadcast/publisherId
    self._valueHandle = _ref.observeEventType(FEventType.Value, withBlock: { [weak self]
      snapshot in
      
      if let strongSelf = self {
        let val: AnyObject! = snapshot.value
        
        if (val != nil) {
          // update data for user from firebase snapshot
          let data = JSON(val)
          strongSelf._isPublishing = data["isPublishing"].bool
          strongSelf._streamId = data["streamId"].string
          
          print("update isPublishing: \(strongSelf._isPublishing)")
          print("update streamId: \(strongSelf._streamId)")
        }
      }
    })
  }
  
  /*!
   * Remove the observer and clear the observer handle
   */
  func stopObserving() {
    if (_valueHandle != nil) {
      _ref.removeObserverWithHandle(_valueHandle!)
      _valueHandle = nil
    }
  }
  
  func isPublishing(publishing: Bool, onStream streamId: String) {
    _isPublishing = publishing
    _streamId = streamId
  }
  
  func setDetails(title: String, description: String, price: String, time: String, quantity: String) {
    _title = title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    _description = description.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    _price = Double(price)
    _allottedTime = time.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    _quantity = Int(quantity)
  }
  
  func addImageUrl(imageUrl: String) {
    _imageUrls.append(imageUrl)
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
                        "time": _allottedTime,
                        "quantity": _quantity
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
  
  func extractData(data: JSON) {
    // get the sessionId
    _sessionId = data["sessionId"].string ?? ""
    _streamId = data["streamId"].string ?? ""
    
    _title = data["title"].string ?? ""
    _description = data["description"].string ?? ""
    _price = data["price"].double ?? 0.0
    _quantity = data["quantity"].int ?? 0
    _allottedTime = data["time"].string ?? ""
    
    print("extracting")
    
    for (key, url):(String, JSON) in data["photos"] {
      // if we have an image url, save it
      if let imageUrl = url.string {
        _imageUrls.append(imageUrl)
        print("key: \(key)")
        print("subj: \(String(url))")
        
        // construct url and request cached image from Fastly
        let cacheUrl = Constants.Fastly.RootUrl.stringByAppendingString(imageUrl)
        print(cacheUrl)
        
        let url = NSURL(string: cacheUrl)
        
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
