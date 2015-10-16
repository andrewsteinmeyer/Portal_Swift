//
//  DetailCollectionViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/14/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class DetailCollectionViewController: UICollectionViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup custom layout
    reloadLayout()
    
    // Register cell classes
    let headerViewNib = UINib(nibName: Constants.DetailCollection.HeaderViewIdentifier, bundle: nil)
    self.collectionView?.registerNib(headerViewNib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: Constants.DetailCollection.HeaderViewIdentifier)
    
    let detailViewNib = UINib(nibName: Constants.DetailCollection.CellIdentifier, bundle: nil)
    self.collectionView?.registerNib(detailViewNib, forCellWithReuseIdentifier: Constants.DetailCollection.CellIdentifier)
    
  }
  
  func reloadLayout() {
    // set header size and item size
    // not using section header so disable sticky header for now
    if let layout = self.collectionViewLayout as? CSStickyHeaderFlowLayout {
      layout.parallaxHeaderReferenceSize = CGSizeMake(self.view.frame.width, Constants.DetailCollection.HeaderViewHeight)
      layout.parallaxHeaderMinimumReferenceSize = CGSizeMake(self.view.frame.width, Constants.DetailCollection.HeaderViewHeight)
      layout.disableStickyHeaders = true
      //layout.parallaxHeaderAlwaysOnTop = true
    }
  }
  
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 5
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.DetailCollection.CellIdentifier, forIndexPath: indexPath)
    
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    switch kind {
      /*
      Decided not to use section headers, but kept this here just in case
      
      case UICollectionElementKindSectionHeader:
      let cell = self.collectionView?.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionHeaderIdentifier, forIndexPath: indexPath) as! DiscoverSectionHeaderView
      
      return cell
      */
    case CSStickyHeaderParallaxHeader:
      // make sure the header cell uses the proper identifier
      let cell = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: Constants.DetailCollection.HeaderViewIdentifier, forIndexPath: indexPath) as UICollectionReusableView!
      
      return cell
    default:
      assert(false, "Unexpected element kind")
    }
  }
  
  
  
  
}
