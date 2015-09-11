//
//  EditImageNavigationController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/8/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class EditImageNavigationController: UINavigationController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // set theme color for navigation buttons
    navigationBar.tintColor = UIColor.themeColor()
    
    // set color for title
    if let font = UIFont(name: "Lato-Bold", size: 15) {
      navigationBar.titleTextAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.darkGrayColor()]
    }
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.Default
  }
  
}
