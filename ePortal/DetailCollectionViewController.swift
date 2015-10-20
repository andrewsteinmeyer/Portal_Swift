//
//  DetailCollectionViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/14/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class DetailCollectionViewController: UICollectionViewController {
  
  var broadcast: Broadcast!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup custom layout
    reloadLayout()
    
    // Register cell classes
    let headerViewNib = UINib(nibName: Constants.DetailCollection.HeaderViewIdentifier, bundle: nil)
    self.collectionView?.registerNib(headerViewNib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: Constants.DetailCollection.HeaderViewIdentifier)
    
    //self.collectionView?.registerClass(DetailCollectionViewSectionHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: Constants.DetailCollection.SectionHeaderIdentifier)
    
    let detailViewNib = UINib(nibName: Constants.DetailCollection.CellIdentifier, bundle: nil)
    self.collectionView?.registerNib(detailViewNib, forCellWithReuseIdentifier: Constants.DetailCollection.CellIdentifier)
    
  }
  
  func reloadLayout() {
    // set header size and item size
    // not using section header so disable sticky header for now
    if let layout = self.collectionViewLayout as? CSStickyHeaderFlowLayout {
      
      layout.enableDecorationView = true
      layout.minimumLineSpacing = 0.50
      
      layout.parallaxHeaderReferenceSize = CGSizeMake(self.view.frame.width, Constants.DetailCollection.HeaderViewHeight)
      layout.parallaxHeaderMinimumReferenceSize = CGSizeMake(self.view.frame.width, Constants.DetailCollection.HeaderViewHeight)
      layout.disableStickyHeaders = false
      //layout.parallaxHeaderAlwaysOnTop = true
    }
  }
  
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 10
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.DetailCollection.CellIdentifier, forIndexPath: indexPath)
    
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    switch kind {
      case UICollectionElementKindSectionHeader:
      let cell = self.collectionView?.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: Constants.DetailCollection.SectionHeaderIdentifier, forIndexPath: indexPath) as! DetailCollectionViewSectionHeader
      
      cell.titleLabel.text = "LIVE VIEWERS"
      
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
