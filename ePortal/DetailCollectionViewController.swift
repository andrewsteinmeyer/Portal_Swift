//
//  ImageSliderCollectionViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/14/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class ImageSliderCollectionViewController: UICollectionViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup custom layout
    reloadLayout()
    
    // Register cell classes
    let headerViewNib = UINib(nibName: Constants.DiscoverCollection.HeaderViewIdentifier, bundle: nil)
    self.collectionView?.registerNib(headerViewNib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: Constants.DiscoverCollection.HeaderViewIdentifier)
    
    let discoverViewNib = UINib(nibName: Constants.DiscoverCollection.CellIdentifier, bundle: nil)
    self.collectionView?.registerNib(discoverViewNib, forCellWithReuseIdentifier: Constants.DiscoverCollection.CellIdentifier)
    
    self.collectionView?.delegate = self
    self.collectionView?.dataSource = self
    
  }
  
  func reloadLayout() {
    // set header size and item size
    // not using section header so disable sticky header for now
    if let layout = self.collectionViewLayout as? CSStickyHeaderFlowLayout {
      layout.parallaxHeaderReferenceSize = CGSizeMake(self.view.frame.width, Constants.DiscoverCollection.HeaderViewHeight)
      layout.itemSize = CGSizeMake(self.view.frame.size.width, layout.itemSize.height)
      layout.disableStickyHeaders = true
    }
  }
  
}

