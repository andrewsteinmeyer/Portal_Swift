//
//  Broadcast.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/31/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

// information for broadcast
class Broadcast {
  var user: FBUser!
  var sessionId: String!
  var token: String!
  var apiKey: String!
  var isPublishing: Bool!
  var streamId: String!
  var sale: Sale!
  
  init() {
    sale = Sale()
    isPublishing = false
  }
  
  func saveSessionDetails(sessionId: String, token: String, apiKey: String) {
    self.sessionId = sessionId
    self.token = token
    self.apiKey = apiKey
  }
  
  func isPublishing(publishing: Bool, onStream streamId: String) {
    self.isPublishing = publishing
    self.streamId = streamId
  }
}

// information for the sale
class Sale {
  var title: String!
  var price: Int!
  
  init() {
    
  }
  
}