/*
* Copyright (c) 2014 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit

extension UIColor {
  func colorForTranslucency() -> UIColor {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0
    
    self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
    
    return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
  }
  
  class func rgba(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
    return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
  }
  
  class func themeColor() -> UIColor {
    //return rgba(227, green: 144, blue: 101, alpha: 1)
    //return rgba(249, green: 141, blue: 50, alpha: 1)
    //return rgba(240, green: 136, blue: 49, alpha: 1)
    return rgba(254, green: 112, blue: 89, alpha: 1)
  }
  
  class func thinbuttonColor() -> UIColor {
    return rgba(36, green: 127, blue: 194, alpha: 1)
  }
  
  class func saleItemTextColor() -> UIColor {
    return rgba(220, green: 198, blue: 178, alpha: 0.7)
  }
  
  class func saleItemPlaceholderTextColor() -> UIColor {
    return saleItemTextColor()
  }
  
  class func labelTextColor() -> UIColor {
    return rgba(229, green: 226, blue: 227, alpha: 0.9)
  }
  
  class func defaultSeparatorColor() -> UIColor {
    return rgba(200, green: 199, blue: 204, alpha: 1)
  }
  
  class func nightTimeTextBackgroundColor() -> UIColor {
    return rgba(245, green: 238, blue: 220, alpha: 1)
  }
  
  class func nightTimeTextColor() -> UIColor {
    return rgba(50, green: 20, blue: 0, alpha: 1)
  }
  
  class func nightTimeTintColor() -> UIColor {
    return rgba(182, green: 126, blue: 44, alpha: 1)
  }
}