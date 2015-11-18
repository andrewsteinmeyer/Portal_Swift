//
//  SaleOptionsViewController.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 6/25/15.
//  Copyright (c) 2015 Andrew Steinmeyer. All rights reserved.
//

import UIKit
import Photos

protocol SaleOptionsViewControllerDelegate {
  func saleOptionsViewControllerDidCancelSale()
  func saleOptionsViewControllerDidStartBroadcast()
}

class SaleOptionsViewController: UITableViewController {
  
  @IBOutlet weak var titleField: SaleTitleTextField!
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var descriptionTextView: SaleDescriptionTextView!
  @IBOutlet weak var dollarSignLabel: UILabel!
  @IBOutlet weak var timeColonLabel: UILabel!
  @IBOutlet weak var priceDotLabel: UILabel!
  @IBOutlet weak var minutesTextField: SaleOptionTextField!
  @IBOutlet weak var secondsTextField: SaleOptionTextField!
  @IBOutlet weak var dollarsTextField: SaleOptionTextField!
  @IBOutlet weak var centsTextField: SaleOptionTextField!
  @IBOutlet weak var quantityTextField: SaleOptionTextField!
  @IBOutlet weak var broadcastButton: DesignableButton!
  @IBOutlet weak var saleTimeView: SaleOptionFieldView!
  @IBOutlet weak var priceView: SaleOptionFieldView!
  @IBOutlet weak var quantityView: SaleOptionFieldView!
  
  var broadcast: Broadcast!
  var delegate: SaleOptionsViewControllerDelegate?
  
  // text input type
  enum SaleOptionTag: Int {
    case Minutes = 1, Seconds, Dollars, Cents, Quantity, Title
  }
  
  // text inputs
  private var _textFields: [UITextField]!
  private var _shouldJumpFieldOnDelete = [SaleOptionTag: Bool]()
  private var _activeTextField: UITextField!
  
  @IBAction func closeSale(sender: AnyObject) {
    self.delegate?.saleOptionsViewControllerDidCancelSale()
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func startBroadcast(sender: AnyObject) {
    if broadcastIsReady() {
      setBroadcastDetails().continueWithBlock() {
        task in
        
        self.delegate?.saleOptionsViewControllerDidStartBroadcast()
        self.dismissViewControllerAnimated(true, completion: nil)
        
        return nil
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Looks for taps on view to dismiss keyboard
    // don't cancel touches in view so that we do not impede tap on photo picker
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboardDidEndEditing")
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  
    // track textFields
    _textFields = [minutesTextField, secondsTextField, dollarsTextField, centsTextField, quantityTextField, titleField]
    
    // add navigation between text fields
    addKeyboardNavigationButtons()
    titleField.becomeFirstResponder()
  }
  
  func addKeyboardNavigationButtons() {
    for textField in _textFields {
      let toolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
      toolbar.barStyle = UIBarStyle.Default
      toolbar.tintColor = UIColor.themeColor()
      textField.addTarget(self, action: "setActiveTextField:", forControlEvents: UIControlEvents.EditingDidBegin)
      textField.addTarget(self, action: "sanitizeInput:", forControlEvents: UIControlEvents.EditingDidEnd)
      
      var items = [UIBarButtonItem]()
      
      if let tag = SaleOptionTag(rawValue: textField.tag) {
        switch tag {
        case .Minutes:
          let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
          let next = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("goToNextField"))
          items = [flexSpace, next]
          textField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
          
        case .Seconds, .Dollars, .Cents:
          let prev = UIBarButtonItem(title: "Previous", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("goToPrevField"))
          let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
          let next = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("goToNextField"))
          items = [prev, flexSpace, next]
          textField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
          
        case .Quantity:
          let prev = UIBarButtonItem(title: "Previous", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("goToPrevField"))
          let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
          let done = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: Selector("dismissKeyboard"))
          items = [prev, flexSpace, done]
          textField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
          
        default:
          // do nothing for titleField
          break
        }
      }
      
      // add items to toolbar, add toolbar to keyboard
      toolbar.items = items
      toolbar.sizeToFit()
      textField.inputAccessoryView = toolbar
    }
  }
  
  func goToPrevField() {
    let arrayPosition = _activeTextField.tag - 1
    if let textField = _textFields?[arrayPosition - 1] {
      textField.text = nil
      
      if let tag = SaleOptionTag(rawValue: textField.tag) {
        switch tag {
        case .Minutes, .Seconds:
          if (secondsTextField.text!.length == 0
              && minutesTextField.text!.length == 0) {
            timeColonLabel.textColor = UIColor.lightGrayColor()
          }
        case .Dollars, .Cents:
          if (centsTextField.text!.length == 0
            && dollarsTextField.text!.length == 0) {
            priceDotLabel.textColor = UIColor.lightGrayColor()
            dollarSignLabel.textColor = UIColor.lightGrayColor()
          }
        default:
          break
        }
      }
      
      textField.becomeFirstResponder()
    }
  }
  
  func goToNextField() {
    let arrayPosition = _activeTextField.tag - 1
    if let textField = _textFields?[arrayPosition + 1] {
      textField.becomeFirstResponder()
    }
  }
  
  func dismissKeyboard() {
    let arrayPosition = _activeTextField.tag - 1
    if let textField = _textFields?[arrayPosition] {
      textField.resignFirstResponder()
    }
  }
  
  /*!
   * Mark the active textfield on editingDidBegin update
   * Autofill textfields that might need values, clear warnings
   */
  func setActiveTextField(textField: UITextField) {
    _activeTextField = textField
    
    if let tag = SaleOptionTag(rawValue: textField.tag) {
      if (tag != .Cents
        && centsTextField.text!.length == 0
        && dollarsTextField.text!.length != 0) {
        centsTextField.text = centsTextField.text!.stringByAppendingString("00")
      }
      else if (tag != .Dollars
        && dollarsTextField.text!.length == 0
        && centsTextField.text!.length != 0) {
          dollarsTextField.text = dollarsTextField.text!.stringByAppendingString("0")
      }
      else if (tag != .Seconds
        && secondsTextField.text!.length == 0
        && minutesTextField.text!.length != 0) {
        secondsTextField.text = secondsTextField.text!.stringByAppendingString("00")
      }
      else if (tag != .Minutes
        && minutesTextField.text!.length == 0
        && secondsTextField.text!.length != 0) {
        minutesTextField.text = minutesTextField.text!.stringByAppendingString("00")
      }
      
      /// remove warnings if they exist
      switch tag {
      case .Dollars, .Cents:
        priceView.clearWarning()
      case .Minutes, .Seconds:
        saleTimeView.clearWarning()
      case .Quantity:
        quantityView.clearWarning()
      case .Title:
        titleField.clearWarning()
      }
    }
  }
  
  /*!
   * Check textfields on editingDidEnd update
   */
  func sanitizeInput(textField: UITextField) {
    if let tag = SaleOptionTag(rawValue: textField.tag) {
      switch tag {
      case .Seconds, .Cents:
        // add a zero if only one digit was entered
        let length = textField.text!.utf16.count
        if (length == 1) {
          textField.text = textField.text!.stringByAppendingString("0")
        }
      default:
        // do nothing for other textFields
        break
      }
      
      if (tag == .Seconds) {
        if (minutesTextField.text!.length != 0 && secondsTextField.text!.length == 0) {
          secondsTextField.text = secondsTextField.text!.stringByAppendingString("00")
        } else if (Int(secondsTextField.text!) > 59) {
          secondsTextField.text = "59"
        } else if (Int(minutesTextField.text!) > 14) {
          secondsTextField.text = "00"
        }
      } else if (tag == .Minutes) {
        if (Int(minutesTextField.text!) > 15) {
          minutesTextField.text = "15"
          secondsTextField.text = "00"
        }
      } else if (tag == .Cents
        && dollarsTextField.text!.length != 0
        && centsTextField.text!.length == 0) {
        centsTextField.text = centsTextField.text!.stringByAppendingString("00")
      }
    }
  }
  
  /*!
   * Check to update textfield properties when the values change
   */
  func textFieldDidChange(textField: UITextField) {
    if let tag = SaleOptionTag(rawValue: textField.tag) {
      let textCount = textField.text!.length
      
      switch tag {
      case .Minutes, .Seconds:
        timeColonLabel.textColor = (minutesTextField.text!.length != 0 || secondsTextField.text!.length != 0) ? UIColor.blackColor() : UIColor.lightGrayColor()
        if (textCount == 2) {
          goToNextField()
        }
      case .Dollars, .Cents:
        if (dollarsTextField.text!.length != 0 || centsTextField.text!.length != 0) {
          priceDotLabel.textColor = UIColor.blackColor()
          dollarSignLabel.textColor = UIColor.blackColor()
        } else {
          priceDotLabel.textColor = UIColor.lightGrayColor()
          dollarSignLabel.textColor = UIColor.lightGrayColor()
        }
        
        if (tag == .Dollars && textCount == 5) {
          goToNextField()
        } else if (tag == .Cents && textCount == 2) {
          goToNextField()
        }

      default:
        break
      }
    }
  }
  
  func textFieldDidDelete() {
    if let textField = _activeTextField {
      if let tag = SaleOptionTag(rawValue: textField.tag) {
        let textCount = textField.text!.length
        
        switch tag {
        case .Seconds, .Cents:
          // jump back to previous textField if appropriate
          if (textCount == 0 && _shouldJumpFieldOnDelete[tag] == true) {
            if (tag == .Seconds) {
              timeColonLabel.textColor = UIColor.lightGrayColor()
            } else if (tag == .Cents) {
              priceDotLabel.textColor = UIColor.lightGrayColor()
              dollarSignLabel.textColor = UIColor.lightGrayColor()
            }
            goToPrevField()
          }
        default:
          break
        }
        
        // reset to true after a delete
        _shouldJumpFieldOnDelete[tag] = true
      }
    }
  }
  
  /*!
   * Review input fields and validate data
   */
  func broadcastIsReady() -> Bool {
    // validate quantity
    if (quantityTextField.text!.length == 0 ||
      quantityTextField.text!.length > 0 && Int(quantityTextField.text!)! == 0) {
        quantityView.showWarning()
        self.alertWithTitle("Invalid quantity", message: "You are planning on selling something, right?", handler: nil)
        
        return false
    }
    
    var isReady = true
    
    if titleField.text!.length == 0 {
      isReady = false
      titleField.showWarning()
    }
    if descriptionTextView.text.length == 0 {
      isReady = false
      descriptionTextView.showWarning()
    }
    if dollarsTextField.text!.length == 0 || centsTextField.text!.length == 0 {
      isReady = false
      priceView.showWarning()
    }
    if minutesTextField.text!.length == 0 || secondsTextField.text!.length == 0 {
      isReady = false
      saleTimeView.showWarning()
    }
    
    if isReady == false {
      self.alertWithTitle("So Close!", message: "You are missing some information about your sale.  Please fill in the missing information so we can start this thing!", handler: nil)
    }
    
    return isReady
  }
  
  /*!
   * Setup the broadcast object using information that the user input
   * Broadcast object will then be saved to firebase database
   */
  func setBroadcastDetails() -> AWSTask {
    // retrieve selected image assets and save to AWS S3
    let productImageVC = self.childViewControllers[0] as! ProductImageCollectionViewController
    let assets = productImageVC.selectedAssets.assets as [PHAsset]
    
    return saveImages(assets).continueWithBlock() {
      task in
      
      // collect broadcast data
      let title = self.titleField.text!
      let description = self.descriptionTextView.text!
      let price = "\(self.dollarsTextField.text!).\(self.centsTextField.text!)"
      let duration = "\(self.minutesTextField.text!):\(self.secondsTextField.text!)"
      let quantity = self.quantityTextField.text!
      
      // give the details to the broadcast
      self.broadcast.setDetails(title: title, description: description, price: price, duration: duration, quantity: quantity)
      
      return task
    }
  }
  
  /*!
   * Iterate over images that user selected and save to AWS S3
   * Store S3 image urls on the broadcast object for reference later
   */
  func saveImages(assets: [PHAsset]) -> AWSTask {
    var tasks = [AWSTask]()
    var assetCount = 0
    
    for asset in assets {
      // increment asset count for image storage on AWS S3
      assetCount++
      
      // create imageUrl for S3 bucket storage
      // add imageUrl to broadcast object for reference later
      let imageUrl = "\(self.broadcast.broadcastId)-\(assetCount)"
      self.broadcast.addImageUrl(imageUrl)
      
      // prepare request and fetch images using the respective photo asset
      let options = PHImageRequestOptions()
      options.networkAccessAllowed = true
      
      // grab image using the photo asset
      PHImageManager.defaultManager().requestImageDataForAsset(asset, options: options) {
        result, _, _, info in
        
        // create upload task to save the image to S3 bucket
        let task = S3Handler.sharedInstance.uploadImageData(result!, imageUrl: imageUrl)
        
        // add task to task group
        tasks.append(task)
      }
    }
    
    // complete after all images have been saved
    return AWSTask(forCompletionOfAllTasks: tasks)
  }
  
  func dismissKeyboardDidEndEditing(){
    // resign the keyboard if in editing mode
    // Causes the view (or one of its embedded text fields) to resign the first responder status.
    view.endEditing(true)
  }
 
  func alertWithTitle(title: String, message: String, handler: ((UIAlertAction!) -> Void)!) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: handler))
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
    return .Fade
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }

}

//MARK: TableView Delegate

extension SaleOptionsViewController {
  override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 30.0
  }
  
  override func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    return 30.0
  }
  
  override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 10.0
  }
  
  override func tableView(tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
    return 10.0
  }
  
  override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    if let headerView = view as? UITableViewHeaderFooterView {
      headerView.textLabel!.textColor = UIColor.blackColor()
      headerView.textLabel!.font = UIFont(name: "Lato-Bold", size: 14)
    }
  }
  
  /// needed to customize table view cell separator inset
  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if(self.tableView.respondsToSelector(Selector("setSeparatorInset:"))){
      cell.separatorInset = UIEdgeInsetsZero
    }
    
    if(self.tableView.respondsToSelector(Selector("setPreservesSuperviewLayoutMargins:"))){
      cell.preservesSuperviewLayoutMargins = false
    }
    
    if(cell.respondsToSelector(Selector("setLayoutMargins:"))){
      cell.layoutMargins = UIEdgeInsetsZero
    }
  }
}

//MARK: TextView and TextField Delegate

extension SaleOptionsViewController: UITextViewDelegate, UITextFieldDelegate {

  func textViewDidChange(textView: UITextView) {
    if textView is SaleDescriptionTextView {
      descriptionTextView.togglePlaceholder()
    }
  }
  
  func textViewDidBeginEditing(textView: UITextView) {
    /// clear warning if one exists
    if textView is SaleDescriptionTextView {
      descriptionTextView.clearWarning()
    }
    
    if (minutesTextField.text!.length != 0
        && secondsTextField.text!.length == 0) {
        secondsTextField.text = secondsTextField.text!.stringByAppendingString("00")
    } else if (secondsTextField.text!.length != 0
              && minutesTextField.text!.length == 0) {
        minutesTextField.text = minutesTextField.text!.stringByAppendingString("00")
    } else if (dollarsTextField.text!.length != 0
              && centsTextField.text!.length == 0) {
        centsTextField.text = centsTextField.text!.stringByAppendingString("00")
    } else if (centsTextField.text!.length != 0
              && dollarsTextField.text!.length == 0) {
        dollarsTextField.text = dollarsTextField.text!.stringByAppendingString("0")
    }
  }
  
  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
    if let tag = SaleOptionTag(rawValue: textField.tag) {
      let textCount = textField.text!.length
      
      switch tag {
      case .Minutes, .Seconds, .Cents:
        // flag for when a backspace should jump the user to the previous textField
        // set to true when the user is deleting the last character in the minutes, seconds or cents field
        if (tag == .Seconds || tag == .Cents) {
          _shouldJumpFieldOnDelete[tag] = (textField.text!.length == 1 && string.length == 0) ? false : true
        }
        
        // limit to 2 numbers
        let newLength = textCount + string.length - range.length
        return newLength <= 2
      case .Dollars, .Quantity:
        // limit to 5 numbers
        let newLength = textCount + string.length - range.length
        return newLength <= 5
      default:
        break
      }
    }
    
    // do not limit otherwise
    return true
  }
}


