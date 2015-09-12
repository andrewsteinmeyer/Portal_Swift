//
//  Constants.swift
//
//  Created by Andrew Steinmeyer on 4/23/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import Foundation

struct Constants {
  // AWS Configuration
  struct AWS {
    static let CognitoRegionType = AWSRegionType.USEast1
    static let DefaultServiceRegionType = AWSRegionType.USEast1
    static let CognitoIdentityPoolId = "us-east-1:e40dbc7f-9b3c-4535-9145-52e5e797dcee"
    static let TwitterProvider = "Twitter"
  }
  
  // AWS Lambda
  struct Lambda {
    static let GetFirebaseToken = "generateFirebaseToken"
    static let GetOpentokSessionId = "generateOpentokSessionId"
  }
  
  // Firebase Configuration
  struct Firebase {
    static let RootUrl = "https://eportal.firebaseio.com"
  }
  
  // OpenTok
  struct OpenTok {
    static let VideoCaptureDefaultInitialFrameRate: Double = 15
  }
  
  // TabBarItem Index
  static let DiscoverTabBarItemIndex = 0
  static let BroadcastTabBarItemIndex = 1
  
  // ViewControllers
  static let LoginVC = "LoginViewController"
  static let MainTabBarVC = "MainTabBarController"
  static let BroadcastVC = "BroadcastViewController"
  static let SaleOptionsVC = "SaleOptionsTableViewController"
  
  // Photo Album
  static let PhotoAlbumTitle = "Portal"
  
  // SaleOption Settings
  struct SaleOption {
    static let ProductImageLimit = 5
    static let ProductViewCellIdentifier = "ProductViewCell"
    static let ImagePickerSegue = "ImagePickerSegue"
    static let EditImageSegue = "EditImageSegue"
  }
  
  // Notifications
  struct Notification {
    static let ImagePickerPresented = "com.dsmlabs.ePortal.ImagePickerPresentedNotification"
    static let ImagePickerDismissed = "com.dsmlabs.ePortal.ImagePickerDismissedNotification"
  }
    
}
