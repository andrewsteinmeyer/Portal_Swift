//
//  ProductImageCollectionViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/6/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit
import Photos

class ProductImageCollectionViewController: UICollectionViewController {
  
  var selectedAssets: SelectedAssets!
  
  private var _addImagePlaceholderCell = 0
  private var _assetThumbnailSize = CGSizeZero
  private var _cameraImages: PHFetchResult!
  private var _imagesCollection: PHAssetCollection!
  
  var lastIndexPath: NSIndexPath!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // initialize selectedAssets if empty
    if selectedAssets == nil {
      selectedAssets = SelectedAssets()
    }
    
    // get user permissions for photos
    requestPhotoLibraryAuthorization()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    // calculate thumbnail size
    // scale is to account for Retina displays
    let scale = UIScreen.mainScreen().scale
    let cellSize = (collectionView!.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
    _assetThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    
    // set image placeholder cell 
    // this cell should come right after the last selected asset cell
    if let selectedAssets = selectedAssets?.assets {
      _addImagePlaceholderCell = selectedAssets.count
    }
    
    collectionView!.reloadData()
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // prepare to present image picker
    if (segue.identifier == Constants.Segue.ImagePicker) {
      let nav = segue.destinationViewController as! ImagePickerNavigationController
      let destination = nav.viewControllers[0] as! AssetsViewController
    
      // pass selected photo assets if there are any
      destination.selectedAssets = selectedAssets
      
      // set title for image picker
      let count = selectedAssets!.assets.count
      destination.title = "Photos \(count)/\(Constants.SaleOption.ProductImageLimit)"
      
      // request all photos from photo album and sort by creation date (most recent first)
      // user will select images from the results
      let options = PHFetchOptions()
      options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      destination.assetsFetchResults = PHAsset.fetchAssetsWithOptions(options)
    }
    // prepare to present edit image viewcontroller for the chosen image
    else if (segue.identifier == Constants.Segue.EditImage) {
      let nav = segue.destinationViewController as! EditImageNavigationController
      let destination = nav.viewControllers[0] as! EditImageViewController
      
      // pass the asset that was chosen
      // set this controller as the delegate of the EditImageViewController
      let cell = sender as! ProductViewCell
      let indexPath = collectionView?.indexPathForCell(cell)
      let asset = selectedAssets.assets[indexPath!.row]
      destination.delegate = self
      destination.selectedAsset = asset
      
      if (cell.isCoverImage == true) {
        destination.isCoverImage = true
      }
    }
  }
  
  deinit {
    // Unregister observer
    PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
  }

}

//MARK: Product Image Picker

extension ProductImageCollectionViewController {
  
  func pickPhoto() {
    // use camera if available
    // otherwise, go straight to photo library
    if UIImagePickerController.isSourceTypeAvailable(.Camera) {
      showPhotoMenu()
    } else {
      choosePhotoFromLibrary()
    }
  }
  
  func requestPhotoLibraryAuthorization() {
    // request permissions and create album
    PHPhotoLibrary.requestAuthorization { status in
      dispatch_async(GlobalMainQueue) {
        switch status {
        case .Authorized:
          // Register observer
          PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
          
          //look for Portal photo album
          let options = PHFetchOptions()
          options.predicate = NSPredicate(format: "title = %@", Constants.PhotoAlbumTitle)
          let collections = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumRegular, options: options)
          
          if collections.count > 0 {
            // album already exists
            self._imagesCollection = collections[0] as! PHAssetCollection
            
            // fetch images that user has taken with camera
            // sort by most recent first
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            self._cameraImages = PHAsset.fetchAssetsInAssetCollection(self._imagesCollection, options: options)
          } else {
            // create the album
            var assetPlaceholder: PHObjectPlaceholder?
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
              let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(Constants.PhotoAlbumTitle)
              assetPlaceholder = changeRequest.placeholderForCreatedAssetCollection
              }, completionHandler: { success, error in
                if !success {
                  print("Failed to create album")
                  print(error)
                  return
                }
                
                let collections = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([assetPlaceholder!.localIdentifier], options: nil)
                if collections.count > 0 {
                  self._imagesCollection = collections[0] as! PHAssetCollection
                  
                  // fetch images that user has taken with camera
                  // sort by most recent first
                  let options = PHFetchOptions()
                  options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                  self._cameraImages = PHAsset.fetchAssetsInAssetCollection(self._imagesCollection, options: options)
                }
            })
          }
          
        default:
          self.showNoAccessAlert()
        }
      }
    }
  }
  
  func showPhotoMenu() {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    alertController.addAction(cancelAction)
    
    let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default, handler: { _ in self.takePhotoWithCamera() })
    alertController.addAction(takePhotoAction)
    
    let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: .Default, handler: { _ in self.choosePhotoFromLibrary() })
    alertController.addAction(chooseFromLibraryAction)
    
    presentViewController(alertController, animated: true, completion: nil)
  }
  
  func takePhotoWithCamera() {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .Camera
    imagePicker.delegate = self
    imagePicker.allowsEditing = false
    imagePicker.view.tintColor = UIColor.themeColor()
    presentViewController(imagePicker, animated: true, completion: nil)
  }
  
  func choosePhotoFromLibrary() {
    // show user the image picker
    self.performSegueWithIdentifier(Constants.Segue.ImagePicker, sender: nil)
  }
  
  func showNoAccessAlert() {
    let alert = UIAlertController(title: "No Photo Access", message: "Please grant Portal photo access in Settings -> Privacy", preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
    alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { _ in
      UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
      return
    }))
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  func saveImage(image: UIImage, toCollection collection: PHAssetCollection) {
    // Create placeholder object
    var imagePlaceholder: PHObjectPlaceholder!
    
    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
      // Create assetChangeRequest and grab placeholder object
      let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
      imagePlaceholder = assetChangeRequest.placeholderForCreatedAsset
      
      // Create assetColletionChangeRequest and pass asset placeholder object
      let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: collection)
      assetCollectionChangeRequest!.addAssets([imagePlaceholder])
      
      }, completionHandler: { _, _ in
        // Fetch the asset and add modification data to it
        let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([imagePlaceholder.localIdentifier], options: nil)
        let imageAsset = fetchResult[0] as! PHAsset
        
        // add the photo asset from camera to the front of the selected assets array
        // bump placeholder cell forward by one cell
        self.selectedAssets.assets.insert(imageAsset, atIndex: 0)
        self._addImagePlaceholderCell += 1
    })
  }

  
}


//MARK: UICollectionViewController Delegate and DataSource

extension ProductImageCollectionViewController {
  // UICollectionViewDataSource
  
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return Constants.SaleOption.ProductImageLimit
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    // retrieve cell to present product images
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.SaleOption.ProductViewCellIdentifier, forIndexPath: indexPath) as! ProductViewCell
    
    // configure the cell
    let reuseCount = ++cell.reuseCount
    let row = indexPath.row
    
    // fetch images for selected photo assets
    if let selectedAssets = selectedAssets?.assets {
      if (row < selectedAssets.count) {
        // the first selected image will be the cover image initially
        if row == 0 {
          cell.isCoverImage = true
        }
        
        // prepare request and fetch images using the respective photo asset
        let options = PHImageRequestOptions()
        options.networkAccessAllowed = true
      
        let asset = selectedAssets[row] as PHAsset
        PHImageManager.defaultManager().requestImageForAsset(asset,
          targetSize: _assetThumbnailSize,
          contentMode: .AspectFill,
          options: options) { result, info in
            // make sure we are still handling the same reuse cell after fetch
            if reuseCount == cell.reuseCount {
              cell.productImageView.image = result
              cell.hasImage = true
            }
        }
      }
    }
    
    // show placeholder image in the cell after the last selected image
    if (row == _addImagePlaceholderCell) {
      cell.isPlaceholderImage = true
    }
    
    // store last indexPath in collectionView
    // this will get popped off collectionView when the user takes a picture with the camera
    // to make room for the picture to be inserted at the beginning of the collectionview
    if (indexPath.row == (Constants.SaleOption.ProductImageLimit - 1)) {
      lastIndexPath = indexPath
    }
    
    return cell
  }
  
  // UICollectionViewDelegate
  
  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ProductViewCell {
      // present image picker for cell with image placeholder
      if (cell.isPlaceholderImage == true) {
        self.pickPhoto()
      }
      // present image editor for cell containing a selected image
      // if we get here, the user has already authorized app to access pictures in condition above
      else if (cell.hasImage) {
        performSegueWithIdentifier(Constants.Segue.EditImage, sender: cell)
      }
    }
    
    // do not select images
    return false
  }
  
}


// MARK: EditImageViewControllerDelegate

extension ProductImageCollectionViewController: EditImageViewControllerDelegate {
  
  func editImageViewControllerDidDeleteAsset(assetToDelete: PHAsset) {
    // Update selected Assets
    selectedAssets.assets = selectedAssets.assets.filter { asset in
      !(asset == assetToDelete)
    }
  }

}

//MARK: UIImagePickerControllerDelegate

extension ProductImageCollectionViewController:  UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    let image = info[UIImagePickerControllerOriginalImage] as! UIImage
    saveImage(image, toCollection: self._imagesCollection)
    
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    dismissViewControllerAnimated(true, completion: nil)
  }

}

//MARK: PHPhotoLibraryChangeObserver

extension ProductImageCollectionViewController: PHPhotoLibraryChangeObserver {
  
  func photoLibraryDidChange(changeInstance: PHChange)  {
    // put on main because we are working with UI
    dispatch_async(GlobalMainQueue) {
      // Respond to changes in collection
      if let collectionChanges = changeInstance.changeDetailsForFetchResult(self._cameraImages) {
        self._cameraImages = collectionChanges.fetchResultAfterChanges
        
        if collectionChanges.hasMoves ||
          !collectionChanges.hasIncrementalChanges {
            // reload entire view bc changes were not incremental
            self.collectionView!.reloadData()
        } else {
          // perform incremental updates
          self.collectionView!.performBatchUpdates({
            
            let insertedIndexes = collectionChanges.insertedIndexes
            if insertedIndexes?.count > 0 {
              let indexPath = self.lastIndexPath!
              // remove last item
              self.collectionView!.deleteItemsAtIndexPaths([indexPath])
              // add new item to front
              self.collectionView!.insertItemsAtIndexPaths(self.indexPathsFromIndexSet(insertedIndexes!, section: 0))
            }
            }, completion: { _ in
                self.collectionView!.reloadData()
            })
        }
      }
    }
  }
  
  // Create an array of index paths from an index set
  func indexPathsFromIndexSet(indexSet:NSIndexSet, section:Int) -> [NSIndexPath] {
    var indexPaths: [NSIndexPath] = []
    indexSet.enumerateIndexesUsingBlock { i, _ in
      indexPaths.append(NSIndexPath(forItem: i, inSection: section))
    }
    return indexPaths
  }
  
  
}
