//
//  DiscoverCollectionViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 6/20/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

let cellIdentifier = "DiscoverViewCell"
let headerViewIdentifier = "DiscoverHeaderView"
let kHeaderViewHeight: CGFloat = 200

// not using section header for now
// let sectionHeaderIdentifier = "DiscoverSectionHeader"

class DiscoverCollectionViewController: UICollectionViewController {
  
  @IBAction func logoutUser(sender: AnyObject) {
    ClientManager.sharedInstance.logoutWithCompletionHandler() {
      task in
      
      // logout of database
      DatabaseManager.sharedInstance.logout()
      
      dispatch_async(GlobalMainQueue) {
        println("completing logout")
        
        // return user to login screen
        let navVC = UIApplication.sharedApplication().keyWindow?.rootViewController as! UINavigationController
        navVC.popToRootViewControllerAnimated(true)
      }
      
      return nil
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup custom layout
    reloadLayout()
    
    // Register cell classes
    var headerViewNib = UINib(nibName: headerViewIdentifier, bundle: nil)
    self.collectionView?.registerNib(headerViewNib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: headerViewIdentifier)
    
    var discoverViewNib = UINib(nibName: cellIdentifier, bundle: nil)
    self.collectionView?.registerNib(discoverViewNib, forCellWithReuseIdentifier: cellIdentifier)
  }
  
  func reloadLayout() {
    // set header size and item size
    // not using section header so disable sticky header for now
    if let layout = self.collectionViewLayout as? CSStickyHeaderFlowLayout {
      layout.parallaxHeaderReferenceSize = CGSizeMake(self.view.frame.width, kHeaderViewHeight)
      layout.itemSize = CGSizeMake(self.view.frame.size.width, layout.itemSize.height)
      layout.disableStickyHeaders = true
    }
  }
  
}

extension DiscoverCollectionViewController: UICollectionViewDataSource {
  
  // MARK: UICollectionViewDataSource
  
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 5
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = self.collectionView?.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
    
    // Configure the cell
    
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    switch kind {
    /*
    Decided not to use section headers, but have this here just in case
    
    case UICollectionElementKindSectionHeader:
      let cell = self.collectionView?.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionHeaderIdentifier, forIndexPath: indexPath) as! DiscoverSectionHeaderView
      
      return cell
    */
    case CSStickyHeaderParallaxHeader:
      let cell = self.collectionView?.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: headerViewIdentifier, forIndexPath: indexPath) as! UICollectionReusableView
      
      return cell
    default:
      assert(false, "Unexpected element kind")
    }
  }
  
  // MARK: UICollectionViewDelegate

  /*
  // Uncomment this method to specify if the specified item should be highlighted during tracking
  override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
  return true
  }
  */

  /*
  // Uncomment this method to specify if the specified item should be selected
  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
  return true
  }
  */
  
  /*
  // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
  override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
  return false
  }
  
  override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
  return false
  }
  
  override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
  
  }
  */

}
