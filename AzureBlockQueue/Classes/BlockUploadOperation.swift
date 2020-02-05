//
// Created by Hunaid Hassan on 22/01/2020.
//

import AZSClient

class BlockUploadOperation: AsyncOperation {
    let id = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    
    private let job: UploadJob
    private let offset: UInt64
    private let blockSize: Int

    init(job: UploadJob, offset: UInt64, blockSize: Int) {
        self.job = job
        self.blockSize = blockSize
        self.offset = offset
    }

    override func main() {
        guard let handle = try? FileHandle(forReadingFrom: job.filePath) else {
            error = OperationError.fileRead
            state = .finished
            return
        }
        handle.seek(toFileOffset: offset)
        let data = handle.readData(ofLength: blockSize)
        job.blockBlob.uploadBlock(from: data, blockID: id) { error in
            if (error == nil) {
                self.finish()
            }else {
                self.error = OperationError.upload(error!.localizedDescription)
                self.retryIfPossible()
            }
        }
    }
}
