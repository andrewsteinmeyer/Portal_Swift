//
//  ChatViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/7/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {

  @IBOutlet weak var chatBarView: UIView!
  @IBOutlet weak var periscommentView: PeriscommentView!
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupAppearance()
    addCells()
  }
  
  func addCells() {
    let profileImage = UIImage(named: "penny")!
    let name = "@andrew"
    afterDelay(1) {
      let comment = "Awesome!"
      self.periscommentView.addCell(profileImage, name: name, comment: comment)
    }
    
    afterDelay(5) { () -> () in
      let comment = "Hooooo!"
      self.periscommentView.addCell(profileImage, name: name, comment: comment)
    }
    
    afterDelay(7) { () -> () in
      let comment = "Supported looooooong line comments."
      self.periscommentView.addCell(profileImage, name: name, comment: comment)
    }
  }
  
  func setupAppearance() {
    chatBarView.backgroundColor = UIColor.clearColor()
    periscommentView.backgroundColor = UIColor.clearColor()
  }


}
