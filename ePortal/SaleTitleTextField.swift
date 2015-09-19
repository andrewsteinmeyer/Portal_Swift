//
//  SaleTitleTextField.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/19/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class SaleTitleTextField: UITextField {
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.tintColor = UIColor.themeColor()
  }
  
  func showWarning() {
    self.layer.borderColor = UIColor.themeColor().CGColor
    self.layer.borderWidth = 1
  }
  
  func clearWarning() {
    self.layer.borderWidth = 0
  }

}
