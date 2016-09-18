//
//  ViewController.swift
//  PickerDemo
//
//  Created by LiuBin on 1/21/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

import UIKit

class ViewController: NBUCameraViewController {
     override func viewDidLoad() {
        super.viewDidLoad()
        
          if(self.cameraView != nil){
            cameraView!.savePicturesToLibrary = true;
            cameraView!.saveResultBlock  =
                {
                    image, metadata, url, error in
                    func ddd( image:UIImage,  metadata:NSDictionary, url:NSURL, error:NSError){

                    }
            }
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
