//
//  FBUser.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/7/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import Firebase

typealias FUserCompletionBlock = (user: FBUser) -> Void

protocol FBUserDelegate: class {
  func userDidUpdate(user: FBUser)
}

class FBUser {
  
  private var _loaded: Bool
  private var _userId: String
  private var _firstName: String?
  private var _lastName: String?
  private var _fullName: String?
  private var _ref: Firebase
  private var _valueHandle: UInt?
  
  weak var delegate: FBUserDelegate?
  
  class func loadFromRoot(root: Firebase, withUserData userData: [String:String], completionBlock block: FUserCompletionBlock) -> FBUser {
    // load the user and set the given location, with the given initial data, and setup the callback for when it updates
    let userId = userData["userId"]
    let peopleRef = root.childByAppendingPath("people").childByAppendingPath(userId)
    
    return FBUser(initRef: peopleRef, initialData: userData, andBlock: block)
  }
  
  init(initRef ref: Firebase, initialData userData: [String:String], andBlock userBlock: FUserCompletionBlock) {
    _loaded = false
    _userId = ref.key
    
    // Setup initial data that we already have
    _firstName = userData["firstName"]
    _lastName = userData["lastName"]
    _fullName = userData["fullName"]
    _ref = ref
    
    self._valueHandle = _ref.observeEventType(FEventType.Value, withBlock: { [weak self] snapshot in
      
      if let strongSelf = self {
        let val: AnyObject! = snapshot.value
        
        if (val == nil) {
          // First login, no values to load from firebase
          // Initial values have been set using provider data when user logged in
        } else {
          // update data for user from firebase snapshot
          let data = JSON(val)
          strongSelf._firstName = data["firstName"].string
          strongSelf._lastName = data["lastName"].string
          strongSelf._fullName = data["fullName"].string
        }
        
        if (strongSelf._loaded == true) {
          // just call delegate for updates
          //TODO: self.delegate.userDidUpdate(self)
        } else {
          userBlock(user: strongSelf)
        }
        strongSelf._loaded = true
      }
    })
    
  }
  
  func updateFromRoot(root: Firebase) {
    // Force lowercase for firstName and lastName so that we can check search index keys in the security rules
    // These values are not for display
    let peopleRef = root.childByAppendingPath("people").childByAppendingPath(_userId)
    peopleRef.updateChildValues([ "firstName": _firstName!.lowercaseString,
                                  "lastName": _lastName!.lowercaseString,
                                  "fullName": _fullName!])
  }
  
}
