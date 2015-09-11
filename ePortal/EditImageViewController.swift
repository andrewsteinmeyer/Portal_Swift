//
//  EditImageViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/8/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit
import Photos

protocol EditImageViewControllerDelegate {
  func editImageViewControllerDidDeleteAsset(asset: PHAsset)
}

class EditImageViewController: UIViewController {
  @IBOutlet weak var checkMark: CheckMark2!
  @IBOutlet weak var previewImageView: UIImageView!
  
  var isCoverImage: Bool = false
  var selectedAsset: PHAsset!
  var indexPath: NSIndexPath!
  
  var delegate: EditImageViewControllerDelegate?
  
  @IBAction func didPressDelete(sender: AnyObject) {
    self.delegate?.editImageViewControllerDidDeleteAsset(self.selectedAsset)
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // set color for navigation buttons
    if let font = UIFont(name: "Lato-Bold", size: 15) {
      navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: font], forState: UIControlState.Normal)
      navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: font], forState: UIControlState.Normal)
    }
    
    // set recognizer to toggle state of check mark on tap
    var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "toggleCheckmark")
    tap.cancelsTouchesInView = false
    checkMark.addGestureRecognizer(tap)
    
    if isCoverImage == true {
      toggleCheckmark()
    }
    
    loadSelectedImageAsset()
  }
  
  func loadSelectedImageAsset() {
    // Load a high quality image to display
    // If screen is Retina, ask for an image twice the normal size
    let scale = UIScreen.mainScreen().scale
    let targetSize = CGSize(width: CGRectGetWidth(previewImageView.bounds) * scale, height: CGRectGetHeight(previewImageView.bounds) * scale)
    
    // Request high quality image
    let options = PHImageRequestOptions()
    options.deliveryMode = .HighQualityFormat
    options.networkAccessAllowed = true
    
    PHImageManager.defaultManager().requestImageForAsset(selectedAsset,
      targetSize: targetSize,
      contentMode: .AspectFit,
      options: options) { result, info in
        // set the image after it is fetched
        self.previewImageView.image = result
    }
  }
  
  func selectedAsset(asset: PHAsset, atIndexPath indexPath: NSIndexPath) {
    self.selectedAsset = asset
    self.indexPath = indexPath
  }
  
  func toggleCheckmark() {
    checkMark.isSelected = !checkMark.isSelected
  }
  
}
