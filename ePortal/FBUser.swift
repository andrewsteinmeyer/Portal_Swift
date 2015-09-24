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
  
  private var _ref: Firebase
  private var _valueHandle: UInt?
  
  private var _loaded: Bool
  private var _userId: String
  private var _firstName: String?
  private var _lastName: String?
  private var _fullName: String?
  
  weak var delegate: FBUserDelegate?
  
  var userId: String {
    get {
      return _userId
    }
  }
  
  /*!
   * Load the user and set the given location, with the given initial data
   * Setup the callback block to call when the user data updates in firebase
   */
  class func loadFromRoot(root: Firebase, withUserData userData: [String:String], completionBlock block: FUserCompletionBlock) -> FBUser {
    
    let userId = userData["userId"]
    let peopleRef = root.childByAppendingPath("people").childByAppendingPath(userId)
    
    return FBUser(initRef: peopleRef, initialData: userData, andBlock: block)
  }
  
  init(initRef ref: Firebase, initialData userData: [String:String], andBlock userBlock: FUserCompletionBlock) {
    _ref = ref
    _userId = ref.key
    _loaded = false
    
    // Store initial data that we already have (provided by AWS Cognito login provider)
    _firstName = userData["firstName"]
    _lastName = userData["lastName"]
    _fullName = userData["fullName"]
    
    // register to watch for changes at user url in firebase
    // changes are specific to the user at root/people/userid
    self._valueHandle = _ref.observeEventType(FEventType.Value, withBlock: { [weak self]
      snapshot in
      
      if let strongSelf = self {
        let val: AnyObject! = snapshot.value
        
        if (val == nil) {
          // First login, no values to load from firebase
          // Initial user info is set using AWS Cognito provider data (ie. Twitter)
        } else {
          // update data for user from firebase snapshot
          let data = JSON(val)
          strongSelf._firstName = data["firstName"].string
          strongSelf._lastName = data["lastName"].string
          strongSelf._fullName = data["fullName"].string
        }
        
        if (strongSelf._loaded == true) {
          // just call delegate for updates
          strongSelf.delegate!.userDidUpdate(strongSelf)
        } else {
          // execute block on initial login
          userBlock(user: strongSelf)
        }
        
        // set loaded flag
        strongSelf._loaded = true
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
  
  func updateFromRoot(root: Firebase) {
    // Force lowercase for firstName and lastName so that we can check search index keys in the security rules
    // These values are not for display
    let peopleRef = root.childByAppendingPath("people").childByAppendingPath(_userId)
    peopleRef.updateChildValues([ "firstName": _firstName!.lowercaseString,
                                  "lastName": _lastName!.lowercaseString,
                                  "fullName": _fullName!])
  }
  
}
