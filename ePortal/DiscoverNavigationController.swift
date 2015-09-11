//
//  DiscoverNavigationController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 6/16/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class DiscoverNavigationController: UINavigationController {

  override func viewDidLoad() {
    super.viewDidLoad()
  
    //self.navigationBar.translucent = true
    //self.navigationBar.tintColor = UIColor.whiteColor()
    // Do any additional setup after loading the view.
    
    if let font = UIFont(name: "Lato-Bold", size: 20) {
      self.navigationBar.titleTextAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.whiteColor()]
    }
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }

}
