//
//  ViewController.swift
//  SwiftBridgeDemo
//
//  Created by wz on 2017/11/28.
//  Copyright © 2017年 wz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    let downloadUrl = "http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.0.1.dmg"
    var task:YCDownloadTask? = nil
    
    @IBAction func start(_ sender: Any) {
        task = YCDownloader.downloader().download(withUrl: downloadUrl, progress: { (progress, task) in
            
            print(progress.fractionCompleted)
            
        }, completion: { (path, error) in
            if (error != nil) {
                print(error!)
            }else{
                print(path!)
            }
        })

        
    }
    @IBAction func pause(_ sender: Any) {
        if let dTask = task {
            YCDownloader.downloader().pause(dTask)
        }
        
    }
    
    @IBAction func resume(_ sender: Any) {
        if let dTask = task {
            YCDownloader.downloader().resumeTask(dTask)
        }
    }
    @IBAction func stop(_ sender: Any) {
        if let dTask = task {
            YCDownloader.downloader().cancel(dTask)
        }
    }
}


