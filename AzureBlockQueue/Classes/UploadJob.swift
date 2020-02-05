//
//  UploadJob.swift
//  AzureBlockQueue
//
//  Created by Hunaid Hassan on 22/01/2020.
//

import AZSClient

public class UploadJob {
    let blockBlob: AZSCloudBlockBlob
    let filePath: URL
    /**
    Creates a new upload job. You need to manually queue it using `QueueManager`
    
    - Parameter blockBlob: The blob you need to upload to
    - Parameter path: Path to the file
    */
    public init(blockBlob: AZSCloudBlockBlob, path: URL) {
        self.blockBlob = blockBlob
        self.filePath = path
    }
}
