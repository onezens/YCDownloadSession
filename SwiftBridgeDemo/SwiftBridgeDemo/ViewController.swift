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
        task = YCDownloadSession.downloadSession().startDownload(withUrl: downloadUrl, fileId: "qq.dmg", delegate: self)
        
    }
    @IBAction func pause(_ sender: Any) {
        task?.pause()
    }
    
    @IBAction func resume(_ sender: Any) {
        task?.resume()
    }
    @IBAction func stop(_ sender: Any) {
        YCDownloadSession.downloadSession().stopDownload(with: task)
    }
}


extension ViewController : YCDownloadTaskDelegate{
    
    func downloadCreated(_ task: YCDownloadTask!) {
        print("start download: \(task.downloadURL)")
    }
    
    func downloadStatusChanged(_ status: YCDownloadStatus, downloadTask task: YCDownloadTask!) {
        print("downloadStatusChanged: \(task.downloadStatus.rawValue)")
    }
    
    func downloadProgress(_ task: YCDownloadTask!, downloadedSize: UInt, fileSize: UInt) {
        
        print("download progress: \(Float(downloadedSize) / Float(fileSize))")
    }
    
}

