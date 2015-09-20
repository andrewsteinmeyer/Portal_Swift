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
  private var _userId: String?
  private var _sessionId: String!
  private var _isPublishing: Bool!
  private var _streamId: String!
  
  private var _title: String!
  private var _description: String!
  private var _price: Double!
  private var _allottedTime: String!
  private var _quantity: Int!
  
  var isPublishing: Bool! {
    get {
      return _isPublishing
    } set(newValue) {
      _isPublishing = newValue
    }
  }
  
  init(root: Firebase, userId: String?) {
    // set broadcast url path
    let broadcastRef = root.childByAppendingPath("broadcasts").childByAppendingPath(userId)
    
    _ref = broadcastRef
    _userId = broadcastRef.key
    
    _isPublishing = false
  }
  
  func saveSessionId(sessionId: String) {
    _sessionId = sessionId
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
  
  func saveWithCompletionBlock(block: FSaveCompletionBlock) {
    
    let newBroadcast = ["title": _title,
                        "description": _description,
                        "price": _price,
                        "time": _allottedTime,
                        "quantity": _quantity]
    
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
