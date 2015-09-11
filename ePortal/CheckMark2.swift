//
//  CheckMark2.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/8/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit
import CoreGraphics

class CheckMark2: UIView {
  
  var isSelected: Bool = false {
    didSet {
      setNeedsDisplay()
    }
  }
  
  override func drawRect(rect: CGRect) {
    super.drawRect(rect)
    drawRectChecked()
  }
  
  func drawRectChecked() {
    //// General Declarations
    let context = UIGraphicsGetCurrentContext()
    
    //// Color Declarations
    let checkmarkOvalColor = UIColor.themeColor()
    
    //// Frames
    let frame = bounds
    
    //// Subframes
    let group = CGRect(x: CGRectGetMinX(frame) + 3, y: CGRectGetMinY(frame) + 3, width: CGRectGetWidth(frame) - 6, height: CGRectGetHeight(frame) - 6)
    
    //// CheckedOval Drawing
    let checkedOvalPath = UIBezierPath(ovalInRect:CGRect(x: CGRectGetMinX(group) + 0.5, y: CGRectGetMinY(group) + 0.5, width: CGRectGetWidth(group) + 1, height: CGRectGetHeight(group) + 1))
    
    // only display outline when not selected
    UIColor.themeColor().setStroke()
    checkedOvalPath.lineWidth = 1
    checkedOvalPath.stroke()
    
    // if selected, fill oval and display check mark
    if isSelected {
      CGContextSaveGState(context)
      checkmarkOvalColor.setFill()
      checkedOvalPath.fill()
      CGContextRestoreGState(context)
    
      //// Bezier Drawing
      let bezierPath = UIBezierPath()
      bezierPath.moveToPoint(CGPoint(x: CGRectGetMinX(group) + 0.27083 * CGRectGetWidth(group), y: CGRectGetMinY(group) + 0.54167 * CGRectGetHeight(group)))
      bezierPath.addLineToPoint(CGPoint(x: CGRectGetMinX(group) + 0.41667 * CGRectGetWidth(group), y: CGRectGetMinY(group) + 0.68750 * CGRectGetHeight(group)))
      bezierPath.addLineToPoint(CGPoint(x: CGRectGetMinX(group) + 0.75000 * CGRectGetWidth(group), y: CGRectGetMinY(group) + 0.35417 * CGRectGetHeight(group)))
      bezierPath.lineCapStyle = kCGLineCapSquare
      
      UIColor.whiteColor().setStroke()
      bezierPath.lineWidth = 1
      bezierPath.stroke()
    }
  }
}