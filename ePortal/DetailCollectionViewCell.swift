//
//  DetailCollectionViewCell.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/14/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class DetailCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var subscriberImage: UIImageView!
  @IBOutlet weak var subscriberName: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
  func configureCellWithSnapshotData(snapshot: FDataSnapshot) {
    let val: AnyObject! = snapshot.value
    
    if (val is NSNull) {
      // no value found
    }
    else {
      subscriberImage.image = UIImage(named: "penny")!
      subscriberName.text! = "PENNY STEINMEYER"
    }
  }
  
}
