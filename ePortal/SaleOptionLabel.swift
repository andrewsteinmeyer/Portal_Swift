//
//  SaleOptionLabel.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/26/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class SaleOptionLabel: UILabel {
  override func drawTextInRect(rect: CGRect) {
    // indent sale option labels
    let newRect = CGRectOffset(rect, 15, 0)
    super.drawTextInRect(newRect)
  }

}
