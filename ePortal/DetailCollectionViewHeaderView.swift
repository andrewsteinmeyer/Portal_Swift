//
//  DetailCollectionViewHeaderView.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/13/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class DetailCollectionViewHeaderView: UICollectionReusableView {
  
  @IBOutlet weak var publisherThumbnailView: UIImageView!
  @IBOutlet weak var publisherNameLabel: UILabel!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var pageControl: UIPageControl!
  
  var images:[UIImage]! {
    didSet {
      collectionView.reloadData()
      pageControl.numberOfPages = images.count
    }
  }

  private var collectionViewLayout:UICollectionViewFlowLayout {
    get {
      return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
  }
  
  private var currentPage:Int {
    get {
      return Int((collectionView.contentOffset.x / collectionView.contentSize.width) * CGFloat(images.count))
    }
  }
  
  private func setupPageControl() {
    pageControl.currentPage = 0
    pageControl.currentPageIndicatorTintColor = UIColor.whiteColor()
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // register observer to listen to broadcast
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshImages:", name: Constants.Notifications.BroadcastImageDidDownload, object: nil)
    
    let imageViewNib = UINib(nibName: "ImageSliderCell", bundle: nil)
    self.collectionView?.registerNib(imageViewNib, forCellWithReuseIdentifier: "ImageSliderCell")
    
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.pagingEnabled = true
    
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirection.Horizontal
    collectionViewLayout.minimumLineSpacing = 0
    collectionViewLayout.minimumInteritemSpacing = 0
    
    setupPageControl()
  }
  
  //make sure to remove this as an observer when cleaning up
  //otherwise, a notification might be sent to a deallocated instance (app could crash)
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func refreshImages(notification: NSNotification) {
    //extract image
    let userInfo = notification.userInfo as! [String: AnyObject]
    let downloadedImage = userInfo["image"] as! UIImage?
    
    if let unwrappedImage = downloadedImage {
      images.append(unwrappedImage)
    }
  }
  
}


extension DetailCollectionViewHeaderView: UICollectionViewDelegate, UICollectionViewDataSource {
  
  //MARK: UICollectionView dataSource methods
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let images = images {
      return images.count
    }
    
    return 0
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageSliderCell", forIndexPath: indexPath) as! ImageSliderCollectionViewCell
    cell.imageView.image = images[indexPath.row]
    
    return cell
  }
  
  func collectionView( collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    return collectionView.bounds.size
  }
  
  // MARK: UICollectionView delegate methods
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    // If the scroll animation ended, update the page control to reflect the current page we are on
    pageControl.currentPage = currentPage
    
  }
}

