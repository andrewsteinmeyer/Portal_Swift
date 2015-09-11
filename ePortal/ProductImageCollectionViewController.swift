//
//  ProductImageCollectionViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/6/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit
import Photos

class ProductImageCollectionViewController: UICollectionViewController, EditImageViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  var selectedAssets: SelectedAssets!
  
  private var _addImagePlaceholderCell = 0
  private var _assetThumbnailSize = CGSizeZero
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // initialize selectedAssets if empty
    if selectedAssets == nil {
      selectedAssets = SelectedAssets()
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    // calculate thumbnail size
    // scale is to account for Retina displays
    let scale = UIScreen.mainScreen().scale
    let cellSize = (collectionView!.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
    _assetThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    
    // put placeholder cell after selected image cells
    if let selectedAssets = selectedAssets?.assets {
      _addImagePlaceholderCell = selectedAssets.count
    }
    
    collectionView!.reloadData()
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // prepare to present image picker
    if (segue.identifier == Constants.SaleOption.ImagePickerSegue) {
      let nav = segue.destinationViewController as! ImagePickerNavigationController
      let destination = nav.viewControllers[0] as! AssetsViewController
    
      // pass selected photo assets if there are any
      destination.selectedAssets = selectedAssets
      
      // set title for image picker
      let count = selectedAssets!.assets.count
      destination.title = "Photos \(count)/\(Constants.SaleOption.ProductImageLimit)"
      
      // request all photos from photo album and sort by creation date
      // user will select images from the results
      let options = PHFetchOptions()
      options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
      destination.assetsFetchResults = PHAsset.fetchAssetsWithOptions(options)
    }
    // prepare to present edit image viewcontroller for the chosen image
    else if (segue.identifier == Constants.SaleOption.EditImageSegue) {
      let nav = segue.destinationViewController as! EditImageNavigationController
      let destination = nav.viewControllers[0] as! EditImageViewController
      
      // pass the asset that was chosen
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
  
  //MARK: Product Image Picker
  
  func requestPhotoLibraryAuthorization() {
    // Request Permissions and Create Album
    PHPhotoLibrary.requestAuthorization { status in
      dispatch_async(GlobalMainQueue) {
        switch status {
        case .Authorized:
          // user authorized access
          // show user the image picker
          self.performSegueWithIdentifier(Constants.SaleOption.ImagePickerSegue, sender: nil)
          break
        default:
          self.showNoAccessAlert()
        }
      }
    }
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
  
  // MARK: UICollectionViewDataSource
  
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
    
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  
  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ProductViewCell {
      // present image picker for cell with image placeholder
      if (cell.isPlaceholderImage == true) {
        self.pickPhoto()
      }
      // present image editor for cell containing a selected image
      // if we get here, the user has already authorized app to access pictures in condition above
      else if (cell.hasImage) {
        performSegueWithIdentifier(Constants.SaleOption.EditImageSegue, sender: cell)
      }
    }
    
    // do not select images
    return false
  }
  
  // MARK: EditImageViewControllerDelegate
  func editImageViewControllerDidDeleteAsset(assetToDelete: PHAsset) {
    // Update selected Assets
    selectedAssets.assets = selectedAssets.assets.filter { asset in
      !(asset == assetToDelete)
    }
  }
  
  //MARK: UIImagePickerControllerDelegate
  
  func takePhotoWithCamera() {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .Camera
    imagePicker.delegate = self
    imagePicker.allowsEditing = false
    imagePicker.view.tintColor = UIColor.themeColor()
    presentViewController(imagePicker, animated: true, completion: nil)
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
    let image = info[UIImagePickerControllerEditedImage] as! UIImage?
    
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  
  func pickPhoto() {
    if UIImagePickerController.isSourceTypeAvailable(.Camera) {
      showPhotoMenu()
    } else {
      requestPhotoLibraryAuthorization()
    }
  }
  
  func showPhotoMenu() {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    alertController.addAction(cancelAction)
    
    let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default, handler: { _ in self.takePhotoWithCamera() })
    alertController.addAction(takePhotoAction)
    
    let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: .Default, handler: { _ in self.requestPhotoLibraryAuthorization() })
    alertController.addAction(chooseFromLibraryAction)
    
    presentViewController(alertController, animated: true, completion: nil)
  }
}
