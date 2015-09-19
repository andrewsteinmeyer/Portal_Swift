//
//  ProductViewCell.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/2/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import Foundation

import UIKit

class ProductViewCell: UICollectionViewCell {
  
  var reuseCount: Int = 0
  
  @IBOutlet weak var productImageView: UIImageView!
  private var border: CAShapeLayer!
  private var highlightBorder: CAShapeLayer!
  private var placeholderImageView: UIImageView!
  
  var hasImage: Bool = false
  
  // cell contains main image for sale
  var isCoverImage: Bool! {
    willSet(newValue) {
      highlightImage(isCoverImage: newValue)
    }
  }
  
  // cell contains placeholder image
  var isPlaceholderImage: Bool! {
    willSet(newValue) {
      togglePlaceholderImage(isPlaceholder: newValue)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    // initialize values
    isPlaceholderImage = false
    isCoverImage = false
    
    // round cell corners
    self.layer.cornerRadius = 3
    
    // set up placeholder image
    placeholderImageView = UIImageView()
    placeholderImageView.image = UIImage(named: "camera-icon")
    placeholderImageView.layer.opacity = 0
    addSubview(placeholderImageView)
    
    // set up dashed border
    border = CAShapeLayer()
    border.strokeColor = UIColor.lightGrayColor().CGColor
    border.fillColor = nil
    border.lineWidth = 1.5
    border.lineDashPattern = [3, 2]
    self.layer.addSublayer(border)
    
    // set up highlight border
    // hide initially
    highlightBorder = CAShapeLayer()
    highlightBorder.strokeColor = UIColor.themeColor().CGColor
    highlightBorder.fillColor = nil
    highlightBorder.lineWidth = 2
    highlightBorder.opacity = 0
    self.layer.addSublayer(highlightBorder)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    // wrap dashed border around thumbnail image
    border.path = UIBezierPath(roundedRect: self.bounds, cornerRadius:3).CGPath
    border.frame = self.bounds
    
    // wrap highlighted border around thumbnail image
    highlightBorder.path = UIBezierPath(roundedRect: self.bounds, cornerRadius:3).CGPath
    highlightBorder.frame = self.bounds
    
    // set placeholder photo image size and location in cell
    placeholderImageView.frame = CGRect(x: (self.bounds.width - 26)/2, y: (self.bounds.height - 18)/2, width: 26, height: 18)
  }
  
  func togglePlaceholderImage(isPlaceholder isPlaceholder: Bool) {
    if isPlaceholder == true {
      placeholderImageView.layer.opacity = 1
    } else {
      placeholderImageView.layer.opacity = 0
    }
  }
  
  func highlightImage(isCoverImage isCoverImage: Bool) {
    if isCoverImage == true {
      highlightBorder.opacity = 1
      border.opacity = 0
    } else {
      highlightBorder.opacity = 0
      border.opacity = 1
    }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    clear()
  }
  
  func clear() {
    isCoverImage = false
    isPlaceholderImage = false
    hasImage = false
    productImageView.image = nil
  }
  
}
