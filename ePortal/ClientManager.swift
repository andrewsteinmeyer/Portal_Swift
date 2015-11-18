//
//  ClientManager.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 7/20/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import KeychainAccess
import TwitterKit
import Crashlytics
import Fabric

/*!
 * ClientManager handles login details for the client using AWS Cognito
 */
final class ClientManager {
  
  private var credentialsProvider: AWSCognitoCredentialsProvider!
  private var completionHandler: AWSContinuationBlock!
  private var keychain: Keychain!
  
  private var firstName: String?
  private var lastName: String?
  private var fullName: String?
  
  private var twitterUserData: TWTRUser? {
    get {
      return self.twitterUserData
    }
    set(user) {
      if let name = user?.name {
        fullName = name
        
        let fullNameArr = fullName!.componentsSeparatedByString(" ")
        firstName = fullNameArr[0]
        lastName = fullNameArr[1]
      }
    }
  }

  //MARK: Lifecycle

  private init() {
    keychain = Keychain(service: String(format: "%@.%@", NSBundle.mainBundle().bundleIdentifier!, "ClientManager"))
  }

  class var sharedInstance: ClientManager {
    struct SingletonWrapper {
      static let singleton = ClientManager()
    }
    return SingletonWrapper.singleton
  }
  
  //MARK: Login Helpers
  
  private func initializeCredentials(logins: [NSObject: AnyObject]?) -> AWSTask {
    // Setup AWS Credentials
    credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.AWS.Cognito.RegionType,
                                                             identityPoolId: Constants.AWS.Cognito.IdentityPoolId)
    
    // set logins if they exist
    if let logins = logins {
      credentialsProvider.logins = logins
    }
    
    let configuration = AWSServiceConfiguration(region: Constants.AWS.Cognito.DefaultServiceRegionType,
                                                credentialsProvider: credentialsProvider)
    
    AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
    
    return credentialsProvider.getIdentityId()
  }
  
  private func completeLogin(logins: [NSObject: AnyObject]?) {
    var task: AWSTask
    
    if (credentialsProvider == nil) {
      task = initializeCredentials(logins)
    }
    else {
      if (credentialsProvider.logins != nil) {
        //should not get into this block until we add more login providers
        let merge = NSMutableDictionary(dictionary: credentialsProvider.logins)
        merge.addEntriesFromDictionary(logins!)
      
        credentialsProvider.logins = merge as [NSObject: AnyObject]
      }
      else {
        if let logins = logins {
          credentialsProvider.logins = logins
        }
      }
      
      //Force refresh of credentials to see if we need to merge identities.
      //User is initially unauthorized.  When they login with Twitter, the new authorized identity
      //needs to be merged with the previous unauthorized identity to retain the cognito identity id.
      //Currently only supporting Twitter as login provider, but could add more later (Digits, Facebook, Amazon, etc)
      task = credentialsProvider.refresh()
    }
    
    task.continueWithBlock {
      task in
      
      //TODO: Set Current Device Token stuff for Cognito sync, see CognitoSyncDemo
      
      if (task.error == nil) {
        print("received AWS credentials")
        print("Cognito id: \(task.result)")
      }
      return task
      
    }.continueWithBlock(completionHandler)
    
  }
  
  func resumeSessionWithCompletionHandler(handler: AWSContinuationBlock) {
    completionHandler = handler
    
    if ((keychain[Constants.AWS.Cognito.Provider.Twitter]) != nil) {
      print("logging in with twitter")
      loginWithTwitter()
    }
    else if (credentialsProvider == nil) {
      print("no login info yet, just setting up aws credentials")
      completeLogin(nil)
    }
  }
  
  func loginWithCompletionHandler(handler: AWSContinuationBlock) {
    completionHandler = handler
    
    self.loginWithTwitter()
  }
  
  func logoutWithCompletionHandler(completionHandler: AWSContinuationBlock) {
    if (isLoggedInWithTwitter()) {
      logoutTwitter()
    }
    
    //TODO: Does wiping the credential Provider keychain reset the user's cognito id?
    //      Or is it remembered when the user logs back in? Pretty sure it is remembered
    //      If it gets wiped, we don't want to clearKeyChain in wipeAll() function
    
    wipeAll()
    
    AWSTask(result: nil).continueWithBlock(completionHandler)
  }
  
  private func wipeAll() {
    print("wiping credentials")
    credentialsProvider.logins = nil
    credentialsProvider.clearKeychain()
  }
  
  func isLoggedIn() -> Bool {
    return isLoggedInWithTwitter()
  }
  
  func getIdentityId() -> String {
    return credentialsProvider.identityId
  }
  
  //MARK: Twitter
  
  private func isLoggedInWithTwitter() -> Bool {
    let loggedIn = Twitter.sharedInstance().session() != nil
    return keychain[Constants.AWS.Cognito.Provider.Twitter] != nil && loggedIn
  }
  
  private func loginWithTwitter() {
    Twitter.sharedInstance().logInWithCompletion { session, error in
      if (session != nil) {
        if let sessionId = session?.userID {
          Twitter.sharedInstance().APIClient.loadUserWithID(sessionId) { user, error in
            if let user = user {
              print("Twitter user: \(user.name)")
              self.setTwitterUserData(user)
              self.completeTwitterLogin()
            }
            else {
              print("error requesting user data with Twitter session id: \(error?.localizedDescription)")
            }
          }
        }
      }
      else {
        print("error logging in with Twitter: \(error?.localizedDescription)")
      }
    }
  }
  
  private func completeTwitterLogin() {
    keychain[Constants.AWS.Cognito.Provider.Twitter] = "YES"
    completeLogin( ["api.twitter.com": self.loginForTwitterSession( Twitter.sharedInstance().session()! )])
    
  }
  
  private func loginForTwitterSession(session: TWTRAuthSession) -> String {
    return String(format: "%@;%@", session.authToken, session.authTokenSecret)
  }
  
  private func logoutTwitter() {
    if (Twitter.sharedInstance().session() != nil) {
      Twitter.sharedInstance().logOut()
      keychain[Constants.AWS.Cognito.Provider.Twitter] = nil
      clearTwitterUserData()
    }
  }
  
  func setTwitterUserData(user: TWTRUser) {
    twitterUserData = user
  }
  
  func getTwitterUserData() -> [String: String]? {
    var data = [String: String]()
    
    if let firstName = firstName {
      data["firstName"] = firstName
    }
    if let lastName = lastName {
      data["lastName"] = lastName
    }
    if let fullName = fullName {
      data["fullName"] = fullName
    }
    
    return (data.isEmpty ? nil : data)
  }
  
  func clearTwitterUserData() {
    twitterUserData = nil
  }
  
  
  //MARK: Initialization
  
  func initializeDependencies() {
    Fabric.with([Twitter(), Crashlytics()])
  }
  
}