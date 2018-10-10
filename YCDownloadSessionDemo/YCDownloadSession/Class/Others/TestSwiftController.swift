//
//  TestSwiftController.swift
//  YCDownloadSessionDemo
//
//  Created by wz on 2018/10/10.
//  Copyright © 2018年 onezen.cc. All rights reserved.
//

import UIKit
import YCDownloadSession

class TestSwiftController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        YCDownloader.downloader().download(withUrl: "", progress: { (progress, task) in
            print(progress.completedUnitCount)
        }) { (localPath, err) in
            if err != nil {
                 print(err!)
            }else{
               print(localPath ?? "localPath nil")
            }
        }
    }
    
    func logInfo() {
        print("Hello, here is Swift log")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
