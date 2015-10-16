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
  var detailViewController: DetailViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
    self.pageViewController.dataSource = self
    
    // set up pages
    chatViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
    detailViewController = self.storyboard?.instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
    
    // set initial page
    pageViewController.setViewControllers([self.detailViewController], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
    
    // set size equal to entire view
    pageViewController.view.frame = self.view.bounds
    
    // add pageViewController
    self.view.addSubview(pageViewController.view)
    self.addChildViewController(pageViewController)
    self.pageViewController.didMoveToParentViewController(self)
  }
  
  func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    if viewController is DetailViewController {
      return nil
    } else {
      return self.detailViewController
    }
  }
  
  func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    if viewController is DetailViewController {
      return self.chatViewController
    } else {
      return nil
    }
  }
  
}

