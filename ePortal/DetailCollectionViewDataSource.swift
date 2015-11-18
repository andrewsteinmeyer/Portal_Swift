//
//  DetailCollectionViewDataSource.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 11/17/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

/*!
 * Subclass in order to properly display the StickyHeaderView in the DetailCollectionViewController
 */
class DetailCollectionViewDataSource: FirebaseCollectionViewDataSource {
  
  var broadcast: Broadcast?
  
  override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let cell = self.collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: Constants.DetailCollection.SectionHeaderIdentifier, forIndexPath: indexPath) as! DetailCollectionViewSectionHeader
      
      cell.titleLabel?.text = "LIVE VIEWERS"
      
      return cell
    case CSStickyHeaderParallaxHeader:
      // make sure the header cell uses the proper identifier
      let cell = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: Constants.DetailCollection.HeaderViewIdentifier, forIndexPath: indexPath) as! DetailCollectionViewHeaderView
      
      // set initial images that have downloaded
      cell.images = broadcast!.downloadedImages
      
      return cell
    default:
      assert(false, "Unexpected element kind")
    }
  }
  
}