//
//  SubscribeOverlayViewController.swift
//  test
//
//  Created by Andrew Steinmeyer on 10/6/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class SubscribeOverlayViewController: UIViewController, UIPageViewControllerDataSource {
  
  var pageViewController: UIPageViewController!
  var chatViewController: ChatViewController!
  var broadcastViewController: BroadcastDetailViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
    self.pageViewController.dataSource = self
    
    self.chatViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
    self.broadcastViewController = self.storyboard?.instantiateViewControllerWithIdentifier("BroadcastDetailViewController") as! BroadcastDetailViewController
    
    self.pageViewController.setViewControllers([self.broadcastViewController], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
    
    // set size equal to entire view
    self.pageViewController.view.frame = self.view.bounds
    
    // add pageViewController
    self.view.addSubview(pageViewController.view)
    self.addChildViewController(pageViewController)
    self.pageViewController.didMoveToParentViewController(self)
  }
  
  
  func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    if viewController is BroadcastDetailViewController {
      return nil
    } else {
      return self.broadcastViewController
    }
  }
  
  func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    if viewController is BroadcastDetailViewController {
      return self.chatViewController
    } else {
      return nil
    }
  }

}
