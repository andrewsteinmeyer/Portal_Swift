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
  private var _user: FBUser!
  private var _sessionId: String!
  private var _isPublishing: Bool!
  private var _streamId: String!
  
  var title: String!
  var description: String!
  var price: Int!
  var quantity: Int!
  
  var isPublishing: Bool! {
    get {
      return _isPublishing
    } set(newValue) {
      _isPublishing = newValue
    }
  }
  
  init() {
    _isPublishing = false
  }
  
  func saveSessionId(sessionId: String) {
    _sessionId = sessionId
  }
  
  func isPublishing(publishing: Bool, onStream streamId: String) {
    _isPublishing = publishing
    _streamId = streamId
  }
  
  func saveWithCompletionBlock(block: FSaveCompletionBlock) {
    block(error: nil)
  }
}
