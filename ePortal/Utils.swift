//
//  Utils.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 4/15/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import Foundation
import Accounts

//MARK: Global aliases for queues

var GlobalMainQueue: dispatch_queue_t {
  return dispatch_get_main_queue()
}

var GlobalUserInteractiveQueue: dispatch_queue_t {
  return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
}

var GlobalUserInitiatedQueue: dispatch_queue_t {
  return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)
}

var GlobalUtilityQueue: dispatch_queue_t {
  return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.rawValue), 0)
}

var GlobalBackgroundQueue: dispatch_queue_t {
  return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)
}

func afterDelay(delay: Double = 0, block: () -> ()) {
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

var dateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.dateStyle = .MediumStyle
  formatter.timeStyle = .MediumStyle
  return formatter
}()

func getFormattedTime(milliseconds: Double) -> String {
  let seconds = milliseconds / 1000
  return dateFormatter.stringFromDate(NSDate(timeIntervalSince1970: seconds))
}

func timeStamp() -> String {
  return String(Int(NSDate().timeIntervalSince1970))
}

func millisecondsToMinutesSeconds (milliseconds : Double) -> (Int, Int) {
  let seconds = Int(milliseconds / 1000)
  return ((seconds % 3600) / 60, (seconds % 3600) % 60)
}

//MARK: Dictionary merge extension

extension Dictionary {
  mutating func unionInPlace(
    dictionary: Dictionary<Key, Value>) {
      for (key, value) in dictionary {
        self[key] = value
      }
  }
}
