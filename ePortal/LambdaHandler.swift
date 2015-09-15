//
//  LambdaHandler.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/15/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

/*!
 * Responsible for invoking calls out to AWS Lambda backend
 */
final class LambdaHandler {
  
  private var _lambdaInvoker: AWSLambdaInvoker!
  
  private init() {
    _lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
  }
  
  func generateFirebaseTokenWithId(id: String) -> AWSTask {
    // use lambda to request a login token from Firebase tied to the user's unique cognito identity
    let params = [ "identity" : id ]
    return self._lambdaInvoker.invokeFunction(Constants.Lambda.GetFirebaseToken, JSONObject: params)
  }
  
  func generateOpentokSessionIdWithToken() -> AWSTask {
    // use lambda to request a session id and token from Opentok service
    let params = []
    return self._lambdaInvoker.invokeFunction(Constants.Lambda.GetOpentokSessionId, JSONObject: params)
  }
  
  //MARK: Singleton
  
  class var sharedInstance: LambdaHandler {
    struct SingletonWrapper {
      static let singleton = LambdaHandler()
    }
    return SingletonWrapper.singleton
  }

}
