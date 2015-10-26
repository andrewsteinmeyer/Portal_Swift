//
//  S3Handler.swift
//  ePortal
//
//  Created by Andrew Steinmeyer on 9/27/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

/*!
* Responsible for invoking calls out to AWS S3
*/
final class S3Handler {
  
  private var _S3TransferUtility: AWSS3TransferUtility!
  
  private init() {
    _S3TransferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
  }
  
  func uploadImageData(data: NSData, imageUrl: String) -> AWSTask {
    
    return _S3TransferUtility!.uploadData(data,
                                          bucket: Constants.AWS.S3.SaleImagesBucket,
                                          key: imageUrl,
                                          contentType: "image/jpeg",
                                          expression: nil,
                                          completionHander: nil)
      .continueWithBlock() {
        task in
        
        print("done uploading image to S3")
        
        return nil
    }
  }
  
  func downloadImageForCell(cell: DiscoverCollectionViewCell, withBucketKey key: String) {
    // setup completionHandler for when the image has finished downloading from AWS S3
    let completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock = {
      (task: AWSS3TransferUtilityDownloadTask, location: NSURL?, data: NSData?, error: NSError?) in
      dispatch_async(GlobalMainQueue) {
        
        if let imageData = data {
          cell.productImageView.image = UIImage(data: imageData)
          
          // send notification to Discover Collection view once the image has downloaded
          // Discover Collection view will need to reload the cell
          //NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.S3ImageDownloadComplete, object: self, userInfo: ["cell": cell])
        }
      }
    }
    
    // download picture from AWS S3
    _S3TransferUtility!
      .downloadDataFromBucket(Constants.AWS.S3.SaleImagesBucket,
        key: key,
        expression: nil,
        completionHander: completionHandler)
      .continueWithBlock() {
        task in
        
        if task.error != nil {
          NSLog("error \(task.error)")
        }
        if task.result != nil {
          print("success downloading image!")
        }
        
        //TODO: Store downloadTask to pause, resume, cancel the download
        
        return nil
    }
  }
  
  //MARK: Singleton
  
  class var sharedInstance: S3Handler {
    struct SingletonWrapper {
      static let singleton = S3Handler()
    }
    return SingletonWrapper.singleton
  }
  
}