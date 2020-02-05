//
// Created by Hunaid Hassan on 23/01/2020.
//

import Foundation

class BlobUploadOperation: AsyncOperation {
    private let job: UploadJob

    init(job: UploadJob) {
        self.job = job
    }

    override func main() {
        guard let data = try? Data(contentsOf: job.filePath) else {
            error = OperationError.fileRead
            state = .finished
            return
        }
        job.blockBlob.upload(from: data) { error in
            if (error == nil) {
                self.finish()
            }else {
                self.error = OperationError.upload(error!.localizedDescription)
                self.retryIfPossible()
            }
        }
    }
}
