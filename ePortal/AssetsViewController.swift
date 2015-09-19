/*
* Copyright (c) 2014 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import Photos

class AssetsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
  let AssetCollectionViewCellReuseIdentifier = "AssetCell"
  
  var assetsFetchResults: PHFetchResult?
  var selectedAssets: SelectedAssets!
  
  private var assetThumbnailSize = CGSizeZero
  private let imageManager: PHCachingImageManager = PHCachingImageManager()
  private var cachingIndexes: [NSIndexPath] = []
  private var lastCacheFrameCenter: CGFloat = 0
  private var cacheQueue = dispatch_queue_create("cache_queue", DISPATCH_QUEUE_SERIAL)
  
  deinit {
    // Unregister observer
    PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
  }
  
  @IBAction func donePressed(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  // MARK: UIViewController
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // set color for navigation buttons
    if let font = UIFont(name: "Lato-Bold", size: 15) {
      navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: font], forState: UIControlState.Normal)
      navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: font], forState: UIControlState.Normal)
    }
    
    collectionView?.allowsMultipleSelection = true
    resetCache()
    
    // Register observer
    PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
  }
  
  override func viewWillAppear(animated: Bool)  {
    super.viewWillAppear(animated)
    
    // Calculate Thumbnail Size
    let scale = UIScreen.mainScreen().scale
    let cellSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
    assetThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    
    collectionView?.reloadData()
    updateSelectedItems()
    updateCache()
  }
  
  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    collectionView?.reloadData()
    updateSelectedItems()
  }
  
  // MARK: Private
  func currentAssetAtIndex(index:NSInteger) -> PHAsset {
    if let fetchResult = assetsFetchResults {
      return fetchResult[index] as! PHAsset
    } else {
      return selectedAssets.assets[index]
    }
  }
  
  func updateSelectedItems() {
    // Select the selected items
    if let fetchResult = assetsFetchResults {
      // Iterate over assets that are already selected and present checkmark
      for asset in selectedAssets.assets {
        let index = fetchResult.indexOfObject(asset)
        if index != NSNotFound {
          let indexPath = NSIndexPath(forItem: index, inSection: 0)
          collectionView?.selectItemAtIndexPath(indexPath,
            animated: false, scrollPosition: .None)
        }
      }
    } else {
      // not using this currently because we always pass a fetchResult for now
      for i in 0..<selectedAssets.assets.count {
        let indexPath = NSIndexPath(forItem: i, inSection: 0)
        collectionView?.selectItemAtIndexPath(indexPath,
          animated: false, scrollPosition: .None)
      }
    }
  }
  
  func updateTitleWithAssetCount() {
    let count = selectedAssets!.assets.count
    self.title = "Photos \(count)/\(Constants.SaleOption.ProductImageLimit)"
  }
  
  // MARK: UICollectionViewDelegate
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    // Update selected Assets
    let asset = currentAssetAtIndex(indexPath.item)
    selectedAssets.assets.append(asset)
    
    updateTitleWithAssetCount()
  }
  
  override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
    // Update selected Assets
    let assetToDelete = currentAssetAtIndex(indexPath.item)
    selectedAssets.assets = selectedAssets.assets.filter { asset in
      !(asset == assetToDelete)
    }
    if assetsFetchResults == nil {
      collectionView.deleteItemsAtIndexPaths([indexPath])
    }
    
    updateTitleWithAssetCount()
  }
  
  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    // only allow user to select up to limit
    let count = selectedAssets!.assets.count
    return (count < Constants.SaleOption.ProductImageLimit ? true : false)
  }
  
  // MARK: UICollectionViewDataSource
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int  {
    if let fetchResult = assetsFetchResults {
      return fetchResult.count
    } else if selectedAssets != nil {
      return selectedAssets.assets.count
    }
    return 0
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AssetCollectionViewCellReuseIdentifier, forIndexPath: indexPath) as! AssetCell
    
    // populate cell
    let reuseCount = ++cell.reuseCount
    let asset = currentAssetAtIndex(indexPath.item)
    
    // set fetch request options
    let options = PHImageRequestOptions()
    options.networkAccessAllowed = true
    
    // fetch the image using the asset
    imageManager.requestImageForAsset(asset,
      targetSize: assetThumbnailSize,
      contentMode: .AspectFill, options: options)
      { result, info in
        if reuseCount == cell.reuseCount {
          cell.imageView.image = result
        }
    }
    
    return cell
  }
  
  // MARK: UICollectionViewDelegateFlowLayout
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    var thumbsPerRow: Int
    switch collectionView.bounds.size.width {
    case 0..<400:
      thumbsPerRow = 4
    case 400..<600:
      thumbsPerRow = 5
    case 600..<800:
      thumbsPerRow = 6
    case 800..<1200:
      thumbsPerRow = 7
    default:
      thumbsPerRow = 4
    }
    var width = collectionView.bounds.size.width / CGFloat(thumbsPerRow)
    // account for spacing between cells
    width -= (collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
    return CGSize(width: width,height: width)
  }
  
  // MARK: Caching
  func resetCache() {
    imageManager.stopCachingImagesForAllAssets()
    cachingIndexes.removeAll(keepCapacity: true)
    lastCacheFrameCenter = 0
  }
  
  func updateCache() {
    let bound = collectionView?.bounds
    let currentFrameCenter = CGRectGetMidY(bound!)
    // only update cache if we have scrolled a third of the visible screen
    if abs(currentFrameCenter - lastCacheFrameCenter) <
      CGRectGetHeight(bound!) / 3 {
        return
    }
    // reset new center after user scrolls a third of the screen
    lastCacheFrameCenter = currentFrameCenter
    let numOffscreenAssetsToCache = 60
    
    var visibleIndexes = collectionView?.indexPathsForVisibleItems() as [NSIndexPath]!
    visibleIndexes.sortInPlace { a, b in
      a.item < b.item
    }
    if visibleIndexes.count == 0 {
      return
    }
    
    var totalItemCount = selectedAssets.assets.count
    if let fetchResults = assetsFetchResults {
      totalItemCount = fetchResults.count
    }
    let lastItemToCache = min(totalItemCount,visibleIndexes[visibleIndexes.count-1].item + numOffscreenAssetsToCache/2)
    let firstItemToCache = max(0, visibleIndexes[0].item - numOffscreenAssetsToCache/2)
    
    let options = PHImageRequestOptions()
    options.networkAccessAllowed = true
    options.resizeMode = .Fast
    
    // remove items from cache that move far enough off screen
    var indexesToStopCaching: [NSIndexPath] = []
    cachingIndexes = cachingIndexes.filter { index in
      if index.item < firstItemToCache || index.item > lastItemToCache {
        indexesToStopCaching.append(index)
        return false
      }
      return true
    }
    // asset thumbnail size much match same size as when we cached
    imageManager.stopCachingImagesForAssets(assetsAtIndexPaths(indexesToStopCaching),
      targetSize: assetThumbnailSize,
      contentMode: .AspectFill,
      options: options)
    
    // add items to cache that are within our cache range
    var indexesToStartCaching: [NSIndexPath] = []
    for i in firstItemToCache..<lastItemToCache {
      let indexPath = NSIndexPath(forItem: i, inSection: 0)
      if !cachingIndexes.contains(indexPath) {
        indexesToStartCaching.append(indexPath)
      }
    }
    cachingIndexes += indexesToStartCaching
    
    // cache the items
    imageManager.startCachingImagesForAssets(
      assetsAtIndexPaths(indexesToStartCaching),
      targetSize: assetThumbnailSize, contentMode: .AspectFill,
      options: options)
  }
  
  func assetsAtIndexPaths(indexPaths:[NSIndexPath]) -> [PHAsset] {
    return indexPaths.map { indexPath in
      return self.currentAssetAtIndex(indexPath.item)
    }
  }
  
  // MARK: UIScrollViewDelegate
  override func scrollViewDidScroll(scrollView: UIScrollView) {
    dispatch_async(cacheQueue) {
      self.updateCache()
    }
  }
  
  // update fetch results if user has updated a photo
  func photoLibraryDidChange(changeInstance: PHChange)  {
    // Respond to changes
    if let collectionChanges = changeInstance.changeDetailsForFetchResult(self.assetsFetchResults!) {
      self.assetsFetchResults = collectionChanges.fetchResultAfterChanges
      
      if collectionChanges.hasMoves ||
        !collectionChanges.hasIncrementalChanges {
          // reload entire view bc changes were not incremental
          self.collectionView?.reloadData()
      } else {
        // perform incremental updates
        self.collectionView?.performBatchUpdates({
          let removedIndexes = collectionChanges.removedIndexes
          if removedIndexes?.count > 0 {
            self.collectionView?.deleteItemsAtIndexPaths(self.indexPathsFromIndexSet(removedIndexes!, section: 0))
          }
          let insertedIndexes = collectionChanges.insertedIndexes
          if insertedIndexes?.count > 0 {
            self.collectionView?.insertItemsAtIndexPaths(self.indexPathsFromIndexSet(insertedIndexes!, section: 0))
          }
          let changedIndexes = collectionChanges.changedIndexes
          if changedIndexes?.count > 0 {
            self.collectionView?.reloadItemsAtIndexPaths(self.indexPathsFromIndexSet(changedIndexes!, section: 0))
          }
          }, completion: nil)
      }
    }
  }
  
  func indexPathsFromIndexSet(indexSet:NSIndexSet, section:Int) -> [NSIndexPath] {
    var indexPaths: [NSIndexPath] = []
    indexSet.enumerateIndexesUsingBlock { i, stop in
      indexPaths.append(NSIndexPath(forItem: i, inSection: section))
    }
    return indexPaths
  }
}
