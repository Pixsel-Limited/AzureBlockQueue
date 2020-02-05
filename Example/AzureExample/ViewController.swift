//
//  ViewController.swift
//  AzureExample
//
//  Created by Hunaid Hassan on 23/01/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AZSClient
import AzureBlockQueue

class ViewController: UIViewController {
    @IBOutlet var progressView: UIProgressView!
    
    let queueManager = QueueManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.mediaTypes = ["public.image", "public.movie"]
        pickerController.sourceType = .photoLibrary
        self.present(pickerController, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        dismiss(animated: true, completion: nil)
        
        var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileName = "\(UUID().uuidString).jpg"
        url.appendPathComponent(fileName)
        try! image.jpegData(compressionQuality: 1)?.write(to: url)
        print(url)
        
        let account = try! AZSCloudStorageAccount(fromConnectionString: "CONNECTIONSTRING")
        let container = AZSCloudBlobContainer(name: "CONTAINERNAME", client: account.getBlobClient())
        let blockBlob = container.blockBlobReference(fromName: fileName)
        try! self.queueManager.add(job: UploadJob(blockBlob: blockBlob, path: url), priority: .veryHigh, blockSize: 240000) { error in
            if error != nil {
                print(error!.localizedDescription)
            }
            DispatchQueue.main.async {
                self.progressView.progress = 1
            }
        }
    }
}
