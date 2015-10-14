//
//  ChatViewController.swift
//  test
//
//  Created by Andrew Steinmeyer on 10/7/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {

  @IBOutlet weak var periscommentView: PeriscommentView!
  override func viewDidLoad() {
    super.viewDidLoad()
    addCells()
  }
  
  func addCells() {
    let profileImage = UIImage(named: "penny")!
    let name = "@andrew"
    dispatchOnMainThread(1) {
      let comment = "Awesome!"
      self.periscommentView.addCell(profileImage, name: name, comment: comment)
    }
    
    dispatchOnMainThread(5) { () -> () in
      let comment = "Hooooo!"
      self.periscommentView.addCell(profileImage, name: name, comment: comment)
    }
    
    dispatchOnMainThread(7) { () -> () in
      let comment = "Supported looooooong line comments."
      self.periscommentView.addCell(profileImage, name: name, comment: comment)
    }
  }
  
  func dispatchOnMainThread(delay: Double = 0, block: () -> ()) {
    if delay == 0 {
      dispatch_async(dispatch_get_main_queue()) {
        block()
      }
      return
    }
    
    let d = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(d, dispatch_get_main_queue()) {
      block()
    }
  }

}
