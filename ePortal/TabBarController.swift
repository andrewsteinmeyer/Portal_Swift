//
//  TabBarController.swift
//  Expo
//
//  Created by Andrew Steinmeyer on 5/12/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupBroadcastTabBarItem()
  }
  
  func setupBroadcastTabBarItem() {
    // retrieve area of tab bar that contains the broadcast icon
    let tabBarRect = self.tabBar.frame
    let buttonCount = self.tabBar.items?.count
    let buttonWidth = tabBarRect.size.width / CGFloat(buttonCount!)
    let originX = buttonWidth * CGFloat(Constants.BroadcastTabBarItemIndex)
    let containingRect = CGRectMake(originX, 0, buttonWidth, self.tabBar.frame.size.height)
    
    // perform hit test on that area to retrieve its view
    let center = CGPointMake(CGRectGetMidX(containingRect), CGRectGetMidY(containingRect))
    let tabIndexItemView = self.tabBar.hitTest(center, withEvent: nil)
    
    // add tap gesture recognizer to that view
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "broadcastTabItemSelected:")
    tapGestureRecognizer.numberOfTapsRequired = 1
    tabIndexItemView!.addGestureRecognizer(tapGestureRecognizer)
  }
  
  // present BroadcastViewController when broadcast tabBarItem is tapped
  func broadcastTabItemSelected(sender:UIGestureRecognizer) {
    let broadcastVC = storyboard!.instantiateViewControllerWithIdentifier(Constants.BroadcastVC) as! BroadcastViewController
    broadcastVC.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
    broadcastVC.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
    self.presentViewController(broadcastVC, animated: false, completion: nil)
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }
  
  override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
    return .Fade
  }
  
}
