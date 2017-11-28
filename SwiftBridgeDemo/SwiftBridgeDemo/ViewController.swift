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
    
    @IBAction func start(_ sender: Any) {
        YCDownloadSession.downloadSession().startDownload(withUrl: downloadUrl, delegate: self, saveName: nil)
    }
    @IBAction func pause(_ sender: Any) {
        YCDownloadSession.downloadSession().pauseDownload(withUrl: downloadUrl)
    }
    
    @IBAction func resume(_ sender: Any) {
        YCDownloadSession.downloadSession().resumeDownload(withUrl: downloadUrl, delegate: self, saveName: nil)
    }
    @IBAction func stop(_ sender: Any) {
        YCDownloadSession.downloadSession().stopDownload(withUrl: downloadUrl)
    }
}


extension ViewController : YCDownloadTaskDelegate{
    
    func downloadCreated(_ task: YCDownloadTask!) {
        print("start download: \(task.downloadURL)")
    }
    
    func downloadStatusChanged(_ status: YCDownloadStatus, downloadTask task: YCDownloadTask!) {
        print("downloadStatusChanged: \(task.downloadStatus)")
    }
    
    func downloadProgress(_ task: YCDownloadTask!, downloadedSize: UInt, fileSize: UInt) {
        
        print("download progress: \(downloadedSize / fileSize)")
    }
    
}

