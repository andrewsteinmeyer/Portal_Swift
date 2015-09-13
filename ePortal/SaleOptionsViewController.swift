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
}

class SaleOptionsViewController: UITableViewController, UITextViewDelegate, UITextFieldDelegate {
  
  @IBOutlet weak var titleField: UITextField!
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var dollarSignLabel: UILabel!
  @IBOutlet weak var timeColonLabel: UILabel!
  @IBOutlet weak var priceDotLabel: UILabel!
  @IBOutlet weak var minutesTextField: SaleOptionTextField!
  @IBOutlet weak var secondsTextField: SaleOptionTextField!
  @IBOutlet weak var dollarsTextField: SaleOptionTextField!
  @IBOutlet weak var centsTextField: SaleOptionTextField!
  @IBOutlet weak var quantityTextField: SaleOptionTextField!
  @IBOutlet weak var broadcastButton: DesignableButton!
  
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
  private var _placeholderLabel: UILabel!
  
  @IBAction func closeSale(sender: AnyObject) {
    self.delegate?.saleOptionsViewControllerDidCancelSale()
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func startBroadcast(sender: AnyObject) {
    // notify observers when camera is dismissed (BroadcastViewController)
    NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.StartPublishingBroadcast, object: nil)
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Looks for taps on view to dismiss keyboard
    // don't cancel touches in view so that we do not impede tap on photo picker
    var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboardDidEndEditing")
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  
    // track textFields
    _textFields = [minutesTextField, secondsTextField, dollarsTextField, centsTextField, quantityTextField, titleField]
    
    // set appearance and focus on titleField
    configureAppearance()
    titleField.becomeFirstResponder()
  }
  
  func configureAppearance() {
    // set delegates for text
    descriptionTextView.delegate = self
    minutesTextField.delegate = self
    secondsTextField.delegate = self
    dollarsTextField.delegate = self
    centsTextField.delegate = self
    quantityTextField.delegate = self
    
    // title should have theme color tint
    titleField.tintColor = UIColor.themeColor()
    
    // set description text appearance
    descriptionTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
    descriptionTextView.layer.borderWidth = 0.75
    descriptionTextView.layer.cornerRadius = 3
    descriptionTextView.tintColor = UIColor.themeColor()
   
    // set placeholder appearance
    // placeholder is visible inside description text until user enters a description
    _placeholderLabel = UILabel(frame: CGRectMake(0, 0, descriptionTextView.bounds.width - 10, descriptionTextView.bounds.height))
    _placeholderLabel.numberOfLines = 0
    _placeholderLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
    _placeholderLabel.text = "Enter a description to let everyone know more about your product!"
    _placeholderLabel.font = UIFont(name: "Lato-Regular", size: 14)
    _placeholderLabel.sizeToFit()
    _placeholderLabel.frame.origin = CGPointMake(5, descriptionTextView.font.pointSize / 2)
    _placeholderLabel.textColor = UIColor.lightGrayColor()
    _placeholderLabel.hidden = count(descriptionTextView.text) != 0
    descriptionTextView.addSubview(_placeholderLabel)
    
    // add navigation between text fields
    addKeyboardNavigationButtons()
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
          var prev = UIBarButtonItem(title: "Previous", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("goToPrevField"))
          var flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
          var next = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("goToNextField"))
          items = [prev, flexSpace, next]
          textField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
          
        case .Quantity:
          var prev = UIBarButtonItem(title: "Previous", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("goToPrevField"))
          var flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
          var done = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: Selector("dismissKeyboard"))
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
          if (secondsTextField.text.length == 0
              && minutesTextField.text.length == 0) {
            timeColonLabel.textColor = UIColor.lightGrayColor()
          }
        case .Dollars, .Cents:
          if (centsTextField.text.length == 0
            && dollarsTextField.text.length == 0) {
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
  
  func setActiveTextField(textField: UITextField) {
    _activeTextField = textField
    
    if let tag = SaleOptionTag(rawValue: textField.tag) {
      if (tag != .Cents
        && centsTextField.text.length == 0
        && dollarsTextField.text.length != 0) {
        centsTextField.text = centsTextField.text.stringByAppendingString("00")
      }
      else if (tag != .Dollars
        && dollarsTextField.text.length == 0
        && centsTextField.text.length != 0) {
          dollarsTextField.text = dollarsTextField.text.stringByAppendingString("0")
      }
      else if (tag != .Seconds
        && secondsTextField.text.length == 0
        && minutesTextField.text.length != 0) {
        secondsTextField.text = secondsTextField.text.stringByAppendingString("00")
      }
      else if (tag != .Minutes
        && minutesTextField.text.length == 0
        && secondsTextField.text.length != 0) {
        minutesTextField.text = minutesTextField.text.stringByAppendingString("00")
      }
    }
  }
  
  func sanitizeInput(textField: UITextField) {
    if let tag = SaleOptionTag(rawValue: textField.tag) {
      switch tag {
      case .Seconds, .Cents:
        // add a zero if only one digit was entered
        let length = count(textField.text.utf16)
        if (length == 1) {
          textField.text = textField.text.stringByAppendingString("0")
        }
      case .Quantity:
        if (quantityTextField.text != nil && quantityTextField.text.toInt() <= 0 ) {
          self.alertWithTitle("Sale quantity must be greater than zero.", message: "You are planning on selling something, right?")
        }
      default:
        // do nothing for other textFields
        break
      }
      
      if (tag == .Seconds) {
        if (minutesTextField.text.length != 0 && secondsTextField.text.length == 0) {
          secondsTextField.text = secondsTextField.text.stringByAppendingString("00")
        } else if (secondsTextField.text.toInt() > 59) {
          secondsTextField.text = "59"
        }
      } else if (tag == .Cents
        && dollarsTextField.text.length != 0
        && centsTextField.text.length == 0) {
        centsTextField.text = centsTextField.text.stringByAppendingString("00")
      }
    }
  }
  
  func textFieldDidChange(textField: UITextField) {
    if let tag = SaleOptionTag(rawValue: textField.tag) {
      let textCount = textField.text.length
      
      switch tag {
      case .Minutes, .Seconds:
        timeColonLabel.textColor = (minutesTextField.text.length != 0 || secondsTextField.text.length != 0) ? UIColor.blackColor() : UIColor.lightGrayColor()
        if (textCount == 2) {
          goToNextField()
        }
      case .Dollars, .Cents:
        if (dollarsTextField.text.length != 0 || centsTextField.text.length != 0) {
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
        let textCount = textField.text.length
        
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
  
  func dismissKeyboardDidEndEditing(){
    // resign the keyboard if in editing mode
    // Causes the view (or one of its embedded text fields) to resign the first responder status.
    view.endEditing(true)
  }
 
  func alertWithTitle(title: String, message: String) {
    var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    
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

extension SaleOptionsViewController: UITableViewDelegate {
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
      headerView.textLabel.textColor = UIColor.blackColor()
      headerView.textLabel.font = UIFont(name: "Lato-Bold", size: 14)
    }
  }
  
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
    _placeholderLabel.hidden = count(descriptionTextView.text) != 0
  }
  
  func textViewDidBeginEditing(textView: UITextView) {
    if (minutesTextField.text.length != 0
        && secondsTextField.text.length == 0) {
        secondsTextField.text = secondsTextField.text.stringByAppendingString("00")
    } else if (secondsTextField.text.length != 0
              && minutesTextField.text.length == 0) {
        minutesTextField.text = minutesTextField.text.stringByAppendingString("00")
    } else if (dollarsTextField.text.length != 0
              && centsTextField.text.length == 0) {
        centsTextField.text = centsTextField.text.stringByAppendingString("00")
    } else if (centsTextField.text.length != 0
              && dollarsTextField.text.length == 0) {
        dollarsTextField.text = dollarsTextField.text.stringByAppendingString("0")
    }
  }
  
  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
    if let tag = SaleOptionTag(rawValue: textField.tag) {
      let textCount = textField.text.length
      
      switch tag {
      case .Minutes, .Seconds, .Cents:
        // flag for if backspace should jump the user to the previous textField
        if (tag == .Seconds || tag == .Cents) {
          _shouldJumpFieldOnDelete[tag] = (textField.text.length == 1 && string.length == 0) ? false : true
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


