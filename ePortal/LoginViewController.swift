//
//  LoginViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 6/16/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit
import TwitterKit

/*!
 * LoginViewController handles user login to app
 */
class LoginViewController: UIViewController {

  @IBOutlet weak var loginActivityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var loginButton: DesignableButton!
  @IBOutlet weak var portalImage: DesignableImageView!
  
  var startAnimating = false
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // set in appDelegate to start loading spinner
    // when proceeding to main tab bar
    if startAnimating == true {
      toggleLoginButton()
    }
    
    setupLoginButton()
  }
  
  func loginButtonPressedDown() {
    highlightBorder()
  }
  
  func loginButtonDidPress() {
    unhighlightBorder()
    
    toggleLoginButton()
    loginUser()
  }
  
  //MARK: - Alerts and indicators
  
  func toggleLoginButton() {
    if (loginButton.hidden != true) {
      loginActivityIndicator.startAnimating()
      loginButton.hidden = true
    } else {
      loginActivityIndicator.stopAnimating()
      loginButton.hidden = false
    }
  }
  
  func alertWithTitle(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  //MARK: - Appearance
  
  func setupLoginButton() {
    loginButton.layer.borderColor = UIColor.whiteColor().CGColor
    loginButton.layer.borderWidth = 0.75
    loginButton.layer.cornerRadius = 17
    loginButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
    
    loginButton.addTarget(self, action: "loginButtonPressedDown", forControlEvents: UIControlEvents.TouchDown)
    loginButton.addTarget(self, action: "loginButtonDidPress", forControlEvents: UIControlEvents.TouchUpInside)
  }
  
  func highlightBorder() {
    loginButton.layer.borderColor = UIColor.yellowColor().CGColor
  }
  
  func unhighlightBorder() {
    loginButton.layer.borderColor = UIColor.whiteColor().CGColor
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
}

//MARK: User Login

extension LoginViewController {
  
  /*!
   * Use AWS Cognito to create an Identity Id and authorize the user
   * The Identity Id is then used to securely log in to Firebase database
   */
  func loginUser() {
    /// Log in client with AWS Cognito
    ClientManager.sharedInstance.loginWithCompletionHandler() {
      task in
      
      let id = ClientManager.sharedInstance.getIdentityId()
      let twitterData = ClientManager.sharedInstance.getTwitterUserData()
      
      /// Log in to database using the AWS Cognito Identity Id
      DatabaseManager.sharedInstance.logInWithIdentityId(id, providerData: twitterData) {
        task in
      
        /// push to tabBarController on success
        if (task.error == nil) {
          dispatch_async(GlobalMainQueue) {
            let navVC = self.navigationController
            let mainTabVC = navVC!.storyboard?.instantiateViewControllerWithIdentifier(Constants.MainTabBarVC) as UIViewController!
            
            afterDelay(2) {
              self.toggleLoginButton()
              navVC!.pushViewController(mainTabVC, animated: true)
            }
          }
        }
        /// present alert to user if error logging in to app
        else {
          dispatch_async(GlobalMainQueue) {
            self.alertWithTitle("Error logging in with Twitter credentials", message: "Sorry, better luck next time")
            
            afterDelay(0.6) {
              self.toggleLoginButton()
            }
          }
        }
        // end AWS task with nil
        return nil
      }
      // end AWS task with nil
      return nil
    }
  }
  
}

