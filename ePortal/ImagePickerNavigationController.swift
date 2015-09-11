//
//  ImagePickerNavigationController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/7/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class ImagePickerNavigationController: UINavigationController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // set theme color for navigation buttons
    navigationBar.tintColor = UIColor.themeColor()
    
    // set color for title
    if let font = UIFont(name: "Lato-Bold", size: 15) {
      navigationBar.titleTextAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.darkGrayColor()]
      navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: font], forState: UIControlState.Normal)
    }
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.Default
  }
  
}