//
//  BlockListUploadOperation.swift
//  AzureBlockQueue
//
//  Created by Hunaid Hassan on 24/01/2020.
//

import AZSClient

class BlockListUploadOperation: AsyncOperation {
    private let ids: [String]
    private let blockBlob: AZSCloudBlockBlob
    
    init(blockBlob: AZSCloudBlockBlob, blockIds: [String]) {
        self.ids = blockIds
        self.blockBlob = blockBlob
    }
    
    override func main() {
        blockBlob.uploadBlockList(from: ids.map{ AZSBlockListItem(blockID: $0, blockListMode: .latest) }) { (error) in
            if (error == nil) {
                self.finish()
            }else {
                self.error = OperationError.upload(error!.localizedDescription)
                self.retryIfPossible()
            }
        }
    }
}
