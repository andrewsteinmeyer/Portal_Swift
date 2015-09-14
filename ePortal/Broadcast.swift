//
//  Broadcast.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/31/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

// information for broadcast
class Broadcast {
  private var _user: FBUser!
  private var _sessionId: String!
  private var _isPublishing: Bool!
  private var _streamId: String!
  private var _sale: Sale!
  
  var isPublishing: Bool! {
    get {
      return _isPublishing
    } set(newValue) {
      _isPublishing = newValue
    }
  }
  
  init() {
    _sale = Sale()
    _isPublishing = false
  }
  
  func saveSessionId(sessionId: String) {
    _sessionId = sessionId
  }
  
  func isPublishing(publishing: Bool, onStream streamId: String) {
    _isPublishing = publishing
    _streamId = streamId
  }
}

// information for the sale
class Sale {
  var title: String!
  var price: Int!
  
  init() {
    
  }
  
}