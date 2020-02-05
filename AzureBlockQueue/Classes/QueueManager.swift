//
//  QueueManager.swift
//  AZSClient
//
//  Created by Hunaid Hassan on 22/01/2020.
//

import Foundation
import Reachability

public typealias JobCompletionHandler = (Error?) -> Void

public class QueueManager {
    private let operationQueue = OperationQueue()
    private let reachability = try! Reachability()

    public var concurrentOperations: Int {
        get { operationQueue.maxConcurrentOperationCount }
        set {
            operationQueue.maxConcurrentOperationCount = newValue
        }
    }
    
    public init(){
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
          try reachability.startNotifier()
        }catch{
          print("could not start reachability notifier")
        }
    }

    /**
        Add an upload job to upload queue which will divide the data in blocks if need be and upload them
        - Parameter job: Job to be queued
        - Parameter priority: Priority for this job
        - Parameter blockSize: Block size

        # Note
        Single blob will be uploaded atomically
    */
    public func add(job: UploadJob, priority: Operation.QueuePriority, blockSize: Int, completionHandler: @escaping JobCompletionHandler) throws {
        let attr = try FileManager.default.attributesOfItem(atPath: job.filePath.path)
        let totalSize = attr[FileAttributeKey.size] as! UInt64
        
        if totalSize <= blockSize {
            let operation = BlobUploadOperation(job: job)
            operation.queuePriority = priority
            operation.completionBlock = {
                completionHandler(operation.error)
            }
            operationQueue.addOperation(operation)
        }else {
            var offset: UInt64 = 0
            var ops: [BlockUploadOperation] = []
            while offset < totalSize {
                let operation = BlockUploadOperation(job: job, offset: offset, blockSize: blockSize)
                operation.queuePriority = priority
                ops.append(operation)
                offset += UInt64(blockSize)
            }
            let listOperation = BlockListUploadOperation(blockBlob: job.blockBlob, blockIds: ops.map{ $0.id })
            listOperation.completionBlock = {
                completionHandler(listOperation.error)
            }
            ops.forEach { listOperation.addDependency($0) }
            ops.forEach { op in
                op.completionBlock = {
                    if op.error != nil {
                        listOperation.cancel()
                        listOperation.dependencies.forEach{ $0.cancel() }
                    }
                    completionHandler(op.error)
                }
            }
            operationQueue.addOperations(ops, waitUntilFinished: false)
            operationQueue.addOperation(listOperation)
        }
    }
    
    @objc func reachabilityChanged(note: Notification) {
      let reachability = note.object as! Reachability
      switch reachability.connection {
          case .wifi:
            fallthrough
          case .cellular:
            operationQueue.isSuspended = false
          case .unavailable:
            fallthrough
          case .none:
            operationQueue.isSuspended = true
            break
        }
    }
}
