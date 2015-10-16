//
//  DiscoverCollectionViewCell.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 6/20/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit
import WebImage

class DiscoverCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var publisherThumbnailView: UIImageView!
  @IBOutlet weak var publisherNameLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var productMaskView: UIView!
  @IBOutlet weak var productImageView: UIImageView!
  @IBOutlet weak var itemsRemainingButton: DesignableButton!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // setup cell
    setupAppearance()
  }
  
  func setupAppearance() {
    //contentView.layer.cornerRadius = 5
  }
  
  func configureCellWithSnapshotData(snapshot: FDataSnapshot) {
    let val: AnyObject! = snapshot.value
    
    if (val != nil) {
      // update data for user from firebase snapshot
      let data = JSON(val)
      let title = data["title"].string ?? ""
      let price = data["price"].double ?? 0
      let quantity = data["quantity"].int ?? 0
      let photokey = data["photos"]["image1"].string ?? ""
      
      self.titleLabel.text = title
      self.priceLabel.text = "$\(String(price))"
      self.itemsRemainingButton.setTitle(String(quantity), forState: .Normal)
      
      // construct url and request cached image from Fastly
      let cacheUrl = Constants.Fastly.RootUrl.stringByAppendingString(photokey)
      print(cacheUrl)
      
      let url = NSURL(string: cacheUrl)
      self.productImageView.sd_setImageWithURL(url!, completed: {
        (image: UIImage!, error: NSError!, type: SDImageCacheType, url: NSURL!) in
        
        if error != nil {
          print(error)
        }
        else {
          print("cached image successfully fetched")
        }
      })
    }
  }
  
}
