//
//  AppDelegate.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 7/20/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit
import Fabric
import TwitterKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    //setup login helpers
    initializeDependencies()
    customizeAppearance()
    
    let navVC = self.window!.rootViewController as! UINavigationController
    
    /*
     Refresh credentials and proceed to TabBarController if logged in.
     Otherwise, present loginViewController.
    */
    
    if ClientManager.sharedInstance.isLoggedIn() {
      let mainTabVC = navVC.storyboard?.instantiateViewControllerWithIdentifier(Constants.MainTabBarVC) as UIViewController!
      navVC.pushViewController(mainTabVC, animated: false)
      
      ClientManager.sharedInstance.resumeSessionWithCompletionHandler() {
        task in
        
        let id = ClientManager.sharedInstance.getIdentityId()
        let twitterData = ClientManager.sharedInstance.getTwitterUserData()
        print("resumed in AppDelegate so skipping login page")
        
        DatabaseManager.sharedInstance.resumeSessionWithCompletionHandler(id, providerData: twitterData) {
          task in
          
          print("Task result: \(task.result)")
          print("back in AppDelegate after Database login attempt")
          
          return nil
        }
        
        return nil
      }
    }
    
    return true
  }
  
  func initializeDependencies() {
    ClientManager.sharedInstance.initializeDependencies()
  }
  
  func customizeAppearance() {
    UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
    UITabBar.appearance().tintColor = UIColor.themeColor()
    
    //UITabBar.appearance().barTintColor = UIColor.blackColor()
    //UINavigationBar.appearance().barTintColor = UIColor.themeColor()
    //UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
  }
  
}

//MARK: - TabBarController Delegate

extension AppDelegate: UITabBarControllerDelegate {
  
  // Ignore tap on BroadcastTabBarItem since a gesture recognizer invokes the BroadcastViewController
  func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
    return !viewController.isEqual(tabBarController.viewControllers?[Constants.BroadcastTabBarItemIndex])
  }
}
