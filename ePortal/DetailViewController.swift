//
//  DetailViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/5/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
  
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var scrollViewOnTop: UIScrollView!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  
  var broadcast: Broadcast!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // add scrollViewOnTop's panGestureRecognizer so this view will receive it's pan gestures
    // remove the panGestureRecognizer from collectionView so it does not compete with the scrollViewOnTop's
    self.view.addGestureRecognizer(self.scrollViewOnTop.panGestureRecognizer)
    self.collectionView.removeGestureRecognizer(self.collectionView.panGestureRecognizer)
    
    // setup collectionView's custom layout
    reloadLayout()
    
    // get title from broadcast
    titleLabel.textColor = UIColor.whiteColor()
    titleLabel.text = broadcast.title
    
    // Register cell classes
    let headerViewNib = UINib(nibName: Constants.DetailCollection.HeaderViewIdentifier, bundle: nil)
    self.collectionView.registerNib(headerViewNib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: Constants.DetailCollection.HeaderViewIdentifier)
    
    let detailViewNib = UINib(nibName: Constants.DetailCollection.CellIdentifier, bundle: nil)
    self.collectionView.registerNib(detailViewNib, forCellWithReuseIdentifier: Constants.DetailCollection.CellIdentifier)
    
    // set as collectionView data source
    self.collectionView.dataSource = self
    
    // set as the delegate
    self.scrollViewOnTop.delegate = self
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    var boundsSize = self.view.bounds.size
    
    // increase scrollView overlay by height of the collectionView
    boundsSize.height += collectionView.collectionViewLayout.collectionViewContentSize().height
    self.scrollViewOnTop.contentSize = boundsSize
    
  }
  
  func reloadLayout() {
    // round corners
    self.collectionView.layer.cornerRadius = 5
    
    // set header size and item size
    // not using section header so disable sticky header for now
    if let layout = self.collectionView.collectionViewLayout as? CSStickyHeaderFlowLayout {
      
      layout.enableDecorationView = true
      layout.minimumLineSpacing = 0.50
      
      layout.parallaxHeaderReferenceSize = CGSizeMake(self.collectionView.frame.width, Constants.DetailCollection.HeaderViewHeight)
      layout.parallaxHeaderMinimumReferenceSize = CGSizeMake(self.collectionView.frame.width, Constants.DetailCollection.HeaderViewHeight)
      layout.disableStickyHeaders = false
      //layout.parallaxHeaderAlwaysOnTop = true
    }
  }

}

extension DetailViewController: UIScrollViewDelegate {
  
  // stop scrolling when at top
  func scrollViewDidScroll(scrollView: UIScrollView) {
    
    // stop collectionView's horizontal scrolling
    self.collectionView.contentOffset.x = 0
    
    // set the max distance that we want the container view to scroll up
    let maxYOffsetForContainerView = CGFloat(200)
    
    // if we haven't scrolled up to the max, continue scrolling the container view up
    // keep the collectionView from scrolling until the containerView has scrolled up to max
    if (scrollView.contentOffset.y <= maxYOffsetForContainerView) {
      self.containerView.bounds.origin.y = scrollView.contentOffset.y
      self.collectionView.contentOffset = CGPointMake(0, 0)
      return
    }
    
    // if we get here, containerView has scrolled up to maxYOffsetForContainerView
    // keep resetting containerView y position to max so it does not move
    self.containerView.bounds.origin.y = maxYOffsetForContainerView
    
    // start to scroll the collectionView up by adjusting it's y offset position
    // collectionView is scrolled to the difference in the scrollView's y position and the containerView's max y position
    // because that is how far the user has scrolled above the maxYOffsetForContainerView
    let offset = scrollView.contentOffset.y - maxYOffsetForContainerView
    self.collectionView.contentOffset.y = offset
  }

}

extension DetailViewController: UICollectionViewDataSource {
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 10
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.DetailCollection.CellIdentifier, forIndexPath: indexPath)
    
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let cell = self.collectionView?.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: Constants.DetailCollection.SectionHeaderIdentifier, forIndexPath: indexPath) as! DetailCollectionViewSectionHeader
      
      cell.titleLabel?.text = "LIVE VIEWERS"
      
      return cell
    case CSStickyHeaderParallaxHeader:
      // make sure the header cell uses the proper identifier
      let cell = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: Constants.DetailCollection.HeaderViewIdentifier, forIndexPath: indexPath) as! DetailCollectionViewHeaderView
      
      // set initial images that have downloaded
      cell.images = broadcast.downloadedImages
      
      return cell
    default:
      assert(false, "Unexpected element kind")
    }
  }
  
}

