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

final class FBUser {
  
  private var ref: Firebase
  private var valueHandle: UInt?
  
  private var loaded: Bool
  private (set) var userId: String
  private var firstName: String?
  private var lastName: String?
  private var fullName: String?
  
  weak var delegate: FBUserDelegate?
  
  /*!
   * Load the user and set the given location, with the given initial data
   * Setup the callback block to call when the user data updates in firebase
   */
  class func loadFromRoot(root: Firebase, withUserData userData: [String:String], completionBlock block: FUserCompletionBlock) -> FBUser {
    
    let userId = userData["userId"]
    let peopleRef = root.childByAppendingPath("people").childByAppendingPath(userId)
    
    return FBUser(initRef: peopleRef, initialData: userData, andBlock: block)
  }
  
  init(initRef firebaseRef: Firebase, initialData userData: [String:String], andBlock userBlock: FUserCompletionBlock) {
    ref = firebaseRef
    userId = firebaseRef.key
    loaded = false
    
    // Store initial data that we already have (provided by AWS Cognito login provider)
    firstName = userData["firstName"]
    lastName = userData["lastName"]
    fullName = userData["fullName"]
    
    print("\(firstName), \(lastName), \(fullName)")
    
    // register to watch for changes at user url in firebase
    // changes are specific to the user at root/people/userId
    valueHandle = ref.observeEventType(FEventType.Value, withBlock: { [weak self]
      snapshot in
      
      if let strongSelf = self {
        let val: AnyObject! = snapshot.value
        
        if (val is NSNull) {
          // First login, no values to load from firebase
          // Initial user info is set using AWS Cognito provider data (ie. Twitter)
        } else {
          // update data for user from firebase snapshot
          let data = JSON(val)
          strongSelf.firstName = data["firstName"].string
          strongSelf.lastName = data["lastName"].string
          strongSelf.fullName = data["fullName"].string
        }
        
        if (strongSelf.loaded == true) {
          // just call delegate for updates
          strongSelf.delegate!.userDidUpdate(strongSelf)
        } else {
          // execute block on initial login
          userBlock(user: strongSelf)
        }
        
        // set loaded flag
        strongSelf.loaded = true
      }
    })
  }
  
  /*!
   * Remove the observer and clear the observer handle
   */
  func stopObserving() {
    if (valueHandle != nil) {
      ref.removeObserverWithHandle(valueHandle!)
      valueHandle = nil
    }
  }
  
  func updateFromRoot(root: Firebase) {
    // Force lowercase for firstName and lastName so that we can check search index keys in the security rules
    // These values are not for display
    let peopleRef = root.childByAppendingPath("people").childByAppendingPath(userId)
    peopleRef.updateChildValues([ "firstName": firstName!.lowercaseString,
                                  "lastName": lastName!.lowercaseString,
                                  "fullName": fullName!])
  }
  
}
