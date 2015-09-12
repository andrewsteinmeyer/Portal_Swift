//
//  SaleOptionTextField.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 8/27/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class SaleOptionTextField: UITextField {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    //self.backgroundColor = UIColor.whiteColor()
    self.layer.cornerRadius = 3
    self.tintColor = UIColor.themeColor()
    self.font = UIFont(name: "Lato-Regular", size: 15)
  }
  
  override func deleteBackward() {
    super.deleteBackward()
    
    if let textFieldDelegate = delegate as? SaleOptionsViewController {
      if (textFieldDelegate.respondsToSelector("textFieldDidDelete")) {
        textFieldDelegate.textFieldDidDelete()
      }
    }
  }
  

}
