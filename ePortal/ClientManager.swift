//
//  ClientManager.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 7/20/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import KeychainAccess
import TwitterKit
import Fabric

/*!
 * ClientManager handles login details for the client using AWS Cognito
 */
final class ClientManager {
  
  private var _credentialsProvider: AWSCognitoCredentialsProvider!
  private var _completionHandler: AWSContinuationBlock!
  private var _keychain: Keychain!
  
  private var _firstName: String?
  private var _lastName: String?
  private var _fullName: String?
  
  private var _twitterUserData: TWTRUser? {
    get {
      return self._twitterUserData
    }
    set(data) {
      if let fullName = data?.name {
        _fullName = fullName
        
        let fullNameArr = fullName.componentsSeparatedByString(" ")
        _firstName = fullNameArr[0]
        _lastName = fullNameArr[1]
      }
    }
  }

  //MARK: Lifecycle

  private init() {
    _keychain = Keychain(service: String(format: "%@.%@", NSBundle.mainBundle().bundleIdentifier!, "ClientManager"))
  }

  class var sharedInstance: ClientManager {
    struct SingletonWrapper {
      static let singleton = ClientManager()
    }
    return SingletonWrapper.singleton
  }
  
  //MARK: Login Helpers
  
  func initializeCredentials(logins: [NSObject: AnyObject]?) -> AWSTask {
    // Setup AWS Credentials
    self._credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.AWS.CognitoRegionType,
                                                             identityPoolId: Constants.AWS.CognitoIdentityPoolId)
    
    if let logins = logins {
      self._credentialsProvider.logins = logins
    }
    
    let configuration = AWSServiceConfiguration(region: Constants.AWS.DefaultServiceRegionType,
                                                credentialsProvider: self._credentialsProvider)
    
    AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
    
    return self._credentialsProvider.getIdentityId()
  }
  
  func completeLogin(logins: [NSObject: AnyObject]?) {
    var task: AWSTask
    
    if (self._credentialsProvider == nil) {
      task = self.initializeCredentials(logins)
    }
    else {
      if (self._credentialsProvider.logins != nil) {
        //should not get into this block until we add more login providers
        var merge = NSMutableDictionary(dictionary: self._credentialsProvider.logins)
        merge.addEntriesFromDictionary(logins!)
      
        self._credentialsProvider.logins = merge as [NSObject: AnyObject]
      }
      else {
        if let logins = logins {
          self._credentialsProvider.logins = logins
        }
      }
      
      //Force refresh of credentials to see if we need to merge identities.
      //User is initially unauthorized.  When they login with Twitter, the new authorized identity
      //needs to be merged with the previous unauthorized identity to retain the cognito identity id.
      //Currently only supporting Twitter as login provider, but could add more later (Digits, Facebook, Amazon, etc)
      task = self._credentialsProvider.refresh()
    }
    
    task.continueWithBlock {
      task in
      
      //TODO: Set Current Device Token stuff for Cognito sync, see CognitoSyncDemo
      
      if (task.error == nil) {
        println("received AWS credentials")
        println("Cognito id: \(task.result)")
      }
      return task
      
    }.continueWithBlock(self._completionHandler)
    
  }
  
  func resumeSessionWithCompletionHandler(completionHandler: AWSContinuationBlock) {
    self._completionHandler = completionHandler
    
    if ((self._keychain[Constants.AWS.TwitterProvider]) != nil) {
      println("logging in with twitter")
      loginWithTwitter()
    }
    else if (self._credentialsProvider == nil) {
      println("no login info yet, just setting up aws credentials")
      self.completeLogin(nil)
    }
  }
  
  func loginWithCompletionHandler(completionHandler: AWSContinuationBlock) {
    self._completionHandler = completionHandler
    
    self.loginWithTwitter()
  }
  
  func logoutWithCompletionHandler(completionHandler: AWSContinuationBlock) {
    if (self.isLoggedInWithTwitter()) {
      self.logoutTwitter()
    }
    
    //TODO: Does wiping the credential Provider keychain reset the user's cognito id?
    //      Or is it remembered when the user logs back in? Pretty sure it is remembered
    //      If it gets wiped, we don't want to clearKeyChain in wipeAll() function
    
    self.wipeAll()
    
    AWSTask(result: nil).continueWithBlock(completionHandler)
  }
  
  func wipeAll() {
    println("wiping credentials")
    self._credentialsProvider.logins = nil
    self._credentialsProvider.clearKeychain()
  }
  
  func isLoggedIn() -> Bool {
    return self.isLoggedInWithTwitter()
  }
  
  func getIdentityId() -> String {
    return self._credentialsProvider.identityId
  }
  
  //MARK: Twitter
  
  func isLoggedInWithTwitter() -> Bool {
    var loggedIn = Twitter.sharedInstance().session() != nil
    return self._keychain[Constants.AWS.TwitterProvider] != nil && loggedIn
  }
  
  func loginWithTwitter() {
    Twitter.sharedInstance().logInWithCompletion { session, error in
      if (session != nil) {
        if let sessionId = session.userID {
          Twitter.sharedInstance().APIClient.loadUserWithID(sessionId) { user, error in
            if let user = user {
              println("Twitter user: \(user.name)")
              self.setTwitterUserData(user)
              self.completeTwitterLogin()
            }
            else {
              println("error requesting user data with Twitter session id: \(error?.localizedDescription)")
            }
          }
        }
      }
      else {
        println("error logging in with Twitter: \(error.localizedDescription)")
      }
    }
  }
  
  func completeTwitterLogin() {
    self._keychain[Constants.AWS.TwitterProvider] = "YES"
    self.completeLogin( ["api.twitter.com": self.loginForTwitterSession( Twitter.sharedInstance().session() )])
    
  }
  
  func loginForTwitterSession(session: TWTRAuthSession) -> String {
    return String(format: "%@;%@", session.authToken, session.authTokenSecret)
  }
  
  func logoutTwitter() {
    if (Twitter.sharedInstance().session() != nil) {
      Twitter.sharedInstance().logOut()
      self._keychain[Constants.AWS.TwitterProvider] = nil
      self.clearTwitterUserData()
    }
  }
  
  func setTwitterUserData(user: TWTRUser) {
    _twitterUserData = user
  }
  
  func getTwitterUserData() -> [String: String]? {
    var data = [String: String]()
    
    if let firstName = _firstName {
      data["firstName"] = firstName
    }
    if let lastName = _lastName {
      data["lastName"] = lastName
    }
    if let fullName = _fullName {
      data["fullName"] = fullName
    }
    
    return (data.isEmpty ? nil : data)
  }
  
  func clearTwitterUserData() {
    _twitterUserData = nil
  }
  
  
  //MARK: Initialization
  
  func initializeDependencies() {
    Fabric.with([Twitter()])
  }
  
}