//
//  OverlayPageViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 11/5/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class OverlayPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

  private var chatViewController: ChatViewController!
  private var detailViewController: DetailViewController!
  
  var broadcast: Broadcast!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.delegate = self
    self.dataSource = self
    
    // page 1 setup
    detailViewController = self.storyboard?.instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
    detailViewController.broadcast = broadcast
    
    // page 2 setup
    chatViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
    chatViewController.broadcast = broadcast
    
    // set initial page
    setViewControllers([self.detailViewController], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
    
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