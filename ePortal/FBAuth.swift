//
//  FBAuth.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/5/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

typealias FAuthCompletionBlock = (error: NSError?, user: FAuthData?) -> Void

/*!
 * This class manages multiple concurrent auth requests (login, logout, status)
 * against the same Firebase database
 */
class FBAuthData {
  private var _blocks: [Int: FAuthCompletionBlock]
  private var _ref: Firebase
  private var _luid: Int
  private var _user: FAuthData?
  private var _authHandle: UInt?
  private var _providerData: [String:String]?
  
  init(ref: Firebase) {
    // Start at 1 so it works with if (luid) {...}
    _luid = 1
    _ref = ref
    _user = nil
    _blocks = [:]
    
    // Keep an eye on what Firebase says that our authentication is
    _authHandle = _ref.observeAuthEventWithBlock() { [weak self]
      user in
      
      if let strongSelf = self {
        // Handle user logout (we had a user and now we don't)
        if ( (user == nil) && (strongSelf._user != nil) ) {
          println("FBAuthData: logging out user")
          strongSelf.onAuthStatusError(error: nil, user: nil)
        }
      }
    }
  }
  
  deinit {
    if let authHandle = _authHandle {
      _ref.removeAuthEventObserverWithHandle(authHandle)
    }
  }
  
  /*!
   * Login to database with firebase token generated from AWS lambda function.
   * Provider data is initial user data given by the provider that was used to login via AWS Cognito
   */
  func logInWithToken(token: String, providerData: [String:String]?) -> AWSTask {
    // set any initial user data from AWS cognito
    if let data = providerData {
      self._providerData = data
    }
    
    var task = AWSTaskCompletionSource()
    
    _ref.authWithCustomToken(token) {
      err, authData in
      
      // update the user's authData
      self.onAuthStatusError(error: err, user: authData)
      
      // log in attempt failed
      if (err != nil) {
        task.setError(err)
      }
      // log in attempt succesful
      else {
        self.populateSearchIndicesForUser(authData)
        task.setResult(authData)
        
      }
    }
    
    return task.task
  }
  
  /*!
   * Add the user's information to the search index.
   * List each user in the search index twice, once by first name and once by last name.
   * We include the user uid at the end to guarantee uniqueness
   */
  func populateSearchIndicesForUser(user: FAuthData) {
    let firstNameRef = _ref.root.childByAppendingPath("search/firstName")
    let lastNameRef = _ref.root.childByAppendingPath("search/lastName")
    
    let firstName = self._providerData?["firstName"]
    let lastName = self._providerData?["lastName"]
    let firstNameKey = String(format: "%@_%@_%@", firstName!, lastName!, user.uid).lowercaseString
    let lastNameKey = String(format: "%@_%@_%@", lastName!, firstName!, user.uid).lowercaseString
    
    firstNameRef.childByAppendingPath(firstNameKey).setValue(user.uid)
    lastNameRef.childByAppendingPath(lastNameKey).setValue(user.uid)
  }
  
  /*!
   * Monitor authorization status of the user.
   * The database manager provides the callback block to execute.
   */
  func checkAuthStatus(block: FAuthCompletionBlock) -> Int {
    var handle = _luid++
    
    _blocks[handle] = block
    
    if (_user != nil) {
      // we already have a user logged in
      // force async to be consistent
      
      var callback = { [weak self]
        () -> Void in
        if let strongSelf = self {
          block(error: nil, user: strongSelf._user!)
        }
        return
      }
      
      dispatch_async(GlobalMainQueue) {
        callback()
      }
    } else if (_blocks.count == 1) {
      // This is the first block for this firebase, kick off the login process
      _ref.observeAuthEventWithBlock() {
        user in
        
        if (user != nil) {
          self.onAuthStatusError(error: nil, user: user)
        } else {
          self.onAuthStatusError(error: nil, user: nil)
        }
      }
    }
    return handle
  }
  
  func stopWatchingAuthStatus(handle: Int) {
    _blocks[handle] = nil
  }
  
  func onAuthStatusError(#error: NSError?, user: FAuthData?) {
    if (user != nil) {
      _user = user
    }
    else {
      _user = nil
    }
    
    for handle in _blocks.keys {
      // tell everyone who's listening
      let block = _blocks[handle]
      block!(error: error, user: user)
    }
  }
  
  func logout() {
    // Pass through to Firebase to unauth
    _ref.unauth()
  }
  
}

/*!
 * Singleton used by DatabaseManager to manage FBAuthData instances
 */
final class FBAuth {
  private var firebases: [String: FBAuthData]
  
  private init() {
    self.firebases = [String: FBAuthData]()
  }
  
  func checkAuthForRef(ref: Firebase, withBlock block: FAuthCompletionBlock) -> Int {
    let firebaseId = ref.root.description
    
    // Pass to the FBAuthData object, which manages multiple auth requests against the same Firebase
    var authData: FBAuthData! = self.firebases[firebaseId]
    
    if (authData == nil) {
      authData = FBAuthData(ref: ref.root)
      self.firebases[firebaseId] = authData
    }
    
    return authData.checkAuthStatus(block)
  }
  
  func loginRef(ref: Firebase, withToken token: String, providerData data: [String:String]?) -> AWSTask {
    let firebaseId = ref.root.description
    
    // Pass to the FBAuthData object, which manages multiple auth requests against the same Firebase
    var authData = self.firebases[firebaseId] as FBAuthData!
    
    if (authData == nil) {
      authData = FBAuthData(ref: ref.root)
      self.firebases[firebaseId] = authData
    }
    
    return authData.logInWithToken(token, providerData: data)
  }
  
  func logoutRef(ref: Firebase) {
    let firebaseId = ref.root.description
    
    // Pass to the FBAuthData object, which manages multiple auth requests against the same Firebase
    var authData = self.firebases[firebaseId] as FBAuthData!
    
    if (authData == nil) {
      authData = FBAuthData(ref: ref.root)
      self.firebases[firebaseId] = authData
    }
    
    return authData.logout()
    
  }
  
  //MARK: Class functions
  
  class var sharedInstance: FBAuth {
    struct SingletonWrapper {
      static let singleton = FBAuth()
    }
    return SingletonWrapper.singleton
  }
  
  // Pass through methods to the singleton
  class func loginRef(ref: Firebase, withToken token: String, providerData data: [String:String]?) -> AWSTask {
    return self.sharedInstance.loginRef(ref, withToken: token, providerData: data)
  }
  
  class func logoutRef(ref: Firebase) {
    return self.sharedInstance.logoutRef(ref)
  }
  
  class func watchAuthForRef(ref: Firebase, withBlock block: FAuthCompletionBlock) -> Int {
    return self.sharedInstance.checkAuthForRef(ref, withBlock: block)
  }
}

