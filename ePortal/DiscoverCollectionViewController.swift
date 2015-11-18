//
//  DiscoverCollectionViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 6/20/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class DiscoverCollectionViewController: UICollectionViewController {
  
  private var ref: Firebase!
  private var dataSource: DiscoverCollectionViewDataSource!
  
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
    ref = DatabaseManager.sharedInstance.root
    
    // setup custom layout
    reloadLayout()
    
    // Register cell classes
    let headerViewNib = UINib(nibName: Constants.DiscoverCollection.HeaderViewIdentifier, bundle: nil)
    self.collectionView?.registerNib(headerViewNib, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: Constants.DiscoverCollection.HeaderViewIdentifier)
    
    let discoverViewNib = UINib(nibName: Constants.DiscoverCollection.CellIdentifier, bundle: nil)
    self.collectionView?.registerNib(discoverViewNib, forCellWithReuseIdentifier: Constants.DiscoverCollection.CellIdentifier)
    
    // set datasource to root/broadcasts firebase url
    dataSource = DiscoverCollectionViewDataSource(ref: ref.childByAppendingPath("broadcasts"), nibNamed: Constants.DiscoverCollection.CellIdentifier, cellReuseIdentifier: Constants.DiscoverCollection.CellIdentifier, view: self.collectionView!)
    
    // setup callback to populate cells with broadcasts from firebase
    dataSource.populateCellWithBlock { (cell: UICollectionViewCell, obj: NSObject) -> Void in
      let snapshot = obj as! FDataSnapshot
      
      // configure cell after we receive data
      if let discoverCell = cell as? DiscoverCollectionViewCell {
        discoverCell.configureCellWithSnapshotData(snapshot)
      }
    }
    
    // set source to firebase source
    self.collectionView?.dataSource = dataSource
    
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
  
}

extension DiscoverCollectionViewController {

  //MARK: UICollectionViewDelegate

  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    // pass the cell in order to pass broadcast data to SubscribeViewController during segue
    let row = UInt(indexPath.row)
    let snapshot = dataSource.objectAtIndex(row) as! FDataSnapshot
    performSegueWithIdentifier(Constants.Segue.Subscribe, sender: snapshot)
    
    return true
  }

}

