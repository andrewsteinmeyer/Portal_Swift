//
//  DetailViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/5/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIScrollViewDelegate {
  
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var descriptionLabel: UILabel!
  
  var detailCollectionViewController: DetailCollectionViewController!
  var broadcast: Broadcast!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.containerView.layer.cornerRadius = 5
    
    // get description from broadcast
    descriptionLabel.text = broadcast.description
    
    // start scroll near bottom and limit how far up it can go
    self.scrollView.delegate = self
    self.scrollView.contentInset = UIEdgeInsets(top: 400, left: 0, bottom: 0, right: 0)
    self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height + 200)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // pass broadcast to DetailCollectionViewController
    if (segue.identifier == Constants.Segue.DetailCollection) {
      detailCollectionViewController = segue.destinationViewController as! DetailCollectionViewController
      detailCollectionViewController.broadcast = broadcast
    }
  }
  
  // stop scrolling when at top
  func scrollViewDidScroll(scrollView: UIScrollView) {
    if scrollView.contentOffset.y > -1 {
      scrollView.contentOffset = CGPointZero
    }
  }

}
