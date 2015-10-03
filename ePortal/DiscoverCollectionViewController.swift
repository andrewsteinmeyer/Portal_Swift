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
  
  private var _ref: Firebase!
  private var _dataSource: FirebaseCollectionViewDataSource!
  
  @IBAction func logoutUser(sender: AnyObject) {
    ClientManager.sharedInstance.logoutWithCompletionHandler() {
      task in
      
      // logout of database
      DatabaseManager.sharedInstance.logout()
      
      dispatch_async(GlobalMainQueue) {
        print("completing logout")
        
        // return user to login screen
        let navVC = UIApplication.sharedApplication().keyWindow?.rootViewController as! UINavigationController
        navVC.popToRootViewControllerAnimated(true)
      }
      
      return nil
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // set reference to firebase root
    _ref = DatabaseManager.sharedInstance.root
    
    // setup custom layout
    reloadLayout()
    
    // Register cell classes
    let headerViewNib = UINib(nibName: headerViewIdentifier, bundle: nil)
    self.collectionView?.registerNib(headerViewNib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: headerViewIdentifier)
    
    let discoverViewNib = UINib(nibName: cellIdentifier, bundle: nil)
    self.collectionView?.registerNib(discoverViewNib, forCellWithReuseIdentifier: cellIdentifier)
    
    // set datasource to root/broadcasts firebase url
    self._dataSource = BroadcastCollectionViewDataSource(ref: _ref.childByAppendingPath("broadcasts"), nibNamed: "DiscoverViewCell", cellReuseIdentifier: "DiscoverViewCell", view: self.collectionView!)
    
    // setup callback to populate cells with broadcasts from firebase
    self._dataSource.populateCellWithBlock { (cell: UICollectionViewCell, obj: NSObject) -> Void in
      let snapshot = obj as! FDataSnapshot
      
      print(cell)
      
      // configure cell after we receive data
      if let discoverCell = cell as? DiscoverViewCell {
        discoverCell.configureCellWithSnapshot(snapshot)
      }
    }
    
    // set source to firebase source
    self.collectionView?.dataSource = self._dataSource
    
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // prepare to subscribe to the broadcast that the user selected
    if (segue.identifier == Constants.Segue.Subscribe) {
      // pass the broadcast data that we need
      if let snapshot = sender as? FDataSnapshot {
        let destination = segue.destinationViewController as! SubscribeViewController
        destination.loadBroadcastFromSnapshot(snapshot)
      }
    }
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

extension DiscoverCollectionViewController {

  //MARK: UICollectionViewDelegate

  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    // pass cell in order to pass broadcast data to SubscribeViewController during segue
    let row = UInt(indexPath.row)
    let snapshot = _dataSource.objectAtIndex(row) as! FDataSnapshot
    performSegueWithIdentifier(Constants.Segue.Subscribe, sender: snapshot)
    
    return true
  }

}

