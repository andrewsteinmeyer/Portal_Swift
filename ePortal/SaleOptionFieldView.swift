//
//  SaleOptionFieldView.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/16/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class SaleOptionFieldView: DesignableView {

  func showWarning() {
    self.layer.borderColor = UIColor.themeColor().CGColor
    self.layer.borderWidth = 1
  }
  
  func clearWarning() {
    self.layer.borderColor = UIColor.lightGrayColor().CGColor
    self.layer.borderWidth = 0.5
  }

}
