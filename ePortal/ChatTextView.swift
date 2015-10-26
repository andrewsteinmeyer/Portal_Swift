//
//  ChatTextView.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/20/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class ChatTextView: DesignableTextView {

  private var _placeholderLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    self.scrollEnabled = false
    configureView()
  }
  
  func configureView() {
    // set description text appearance
    self.layer.cornerRadius = 5
    self.tintColor = UIColor.lightGrayColor()
    
    // set placeholder appearance
    // placeholder is visible inside description text until user enters a description
    _placeholderLabel = UILabel(frame: CGRectMake(0, 0, self.bounds.width - 10, self.bounds.height))
    _placeholderLabel.numberOfLines = 0
    _placeholderLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
    _placeholderLabel.text = "Join in the fun already..."
    _placeholderLabel.font = UIFont(name: "Lato-Regular", size: 16)
    _placeholderLabel.sizeToFit()
    _placeholderLabel.frame.origin = CGPointMake(5, self.font!.pointSize / 2)
    _placeholderLabel.textColor = UIColor.lightGrayColor()
    _placeholderLabel.hidden = self.text.characters.count != 0
    self.addSubview(_placeholderLabel)
    
  }
  
  func togglePlaceholder() {
    _placeholderLabel.hidden = self.text.characters.count != 0
  }
  
  func adjustHeight() {
    // resize view based on content
    let fixedWidth = self.frame.size.width
    self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
    let newSize = self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
    var newFrame = self.frame
    newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
    self.frame = newFrame
  }
}
