//
//  DiscoverCollectionViewDataSource.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/25/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//


/*!
 * Subclass in order to properly display the StickyHeaderView in the DiscoverCollectionViewController
 */

class DiscoverCollectionViewDataSource: FirebaseCollectionViewDataSource {
  
  // MARK: UICollectionViewDataSource
  
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
      let cell = self.collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: Constants.DiscoverCollection.HeaderViewIdentifier, forIndexPath: indexPath) as UICollectionReusableView!
      
      return cell
    default:
      assert(false, "Unexpected element kind")
    }
  }
  
}