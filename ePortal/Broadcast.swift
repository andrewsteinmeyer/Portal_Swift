//
//  Broadcast.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/31/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

typealias FSaveCompletionBlock = (error: NSError?) -> Void

// information for broadcast
class Broadcast {
  private var _ref: Firebase
  private var _valueHandle: UInt?
  
  private var _publisherId: String!
  private var _sessionId: String!
  private var _isPublishing: Bool!
  private var _streamId: String!
  
  private var _title: String!
  private var _description: String!
  private var _price: Double!
  private var _allottedTime: String!
  private var _quantity: Int!
  private var _imageUrls: [String]!
  
  var publisherId: String {
    get {
      return _publisherId
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
  
  init(root: Firebase, publisherId: String!) {
    // set broadcast url path
    // TODO: Bug - app crashes if we don't have userId by the time the user clicks the "Broadcast" tab item
    let broadcastRef = root.childByAppendingPath("broadcasts").childByAppendingPath(publisherId)
    
    _ref = broadcastRef
    _publisherId = broadcastRef.key
    
    _isPublishing = false
    _imageUrls = []
    
    // register to watch for changes at broadcast url in firebase
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
    
    let updated = ["streamId": _streamId,
                   "isPublishing": _isPublishing]
    
    _ref.updateChildValues(updated as [NSObject : AnyObject])
  }
  
  func setDetails(title: String, description: String, price: String, time: String, quantity: String) {
    _title = title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    _description = description.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    _price = Double(price)
    _allottedTime = time.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    _quantity = Int(quantity)
  }
  
  func addImage(imageUrl: String) {
    _imageUrls.append(imageUrl)
  }
  
  /*!
   * Build the broadcast and save it to firebase
   */
  func saveWithCompletionBlock(block: FSaveCompletionBlock) {
    
    var newBroadcast: [String: AnyObject] = [
                        "publisherId": _publisherId,
                        "sessionId": _sessionId,
                        "isPublishing": false,
                        "title": _title,
                        "description": _description,
                        "price": _price,
                        "time": _allottedTime,
                        "quantity": _quantity
                        ]
    
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
}
