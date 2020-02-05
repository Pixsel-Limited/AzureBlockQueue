//
// Created by Hunaid Hassan on 23/01/2020.
//

import Foundation
import Reachability

class AsyncOperation: Operation {
    @objc enum OperationState: Int {
        case ready
        case executing
        case finished
    }
    
    enum OperationError: Error {
        case fileRead
        case upload(String)
    }

    private let stateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".rw.state", attributes: .concurrent)
    
    var error: OperationError?
    
    private var _state: OperationState = .ready
    @objc dynamic var state: OperationState {
        get { return stateQueue.sync { _state } }
        set { stateQueue.async(flags: .barrier) { self._state = newValue } }
    }
    
    override var isAsynchronous: Bool { true }
    
    open         override var isReady:        Bool { return state == .ready && super.isReady }
    public final override var isExecuting:    Bool { return state == .executing }
    public final override var isFinished:     Bool { return state == .finished }
    
    private var retriesRemaining: Int = 5
    private var isSuspended = false
    let reachability = try! Reachability()
    
    override init() {
        super.init()
        reachability.whenReachable = { reachability in
            if reachability.connection != .unavailable && self.isSuspended == true {
                self.isSuspended = false
                self.main()
            }
        }
        try! reachability.startNotifier()
    }
    
    open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }

        return super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    public final override func start() {
        if isCancelled {
            state = .finished
            return
        }

        state = .executing
        main()
    }
    
    func finish() {
        state = .finished
    }
    
    func retryIfPossible() {
        retriesRemaining -= 1
        if retriesRemaining == 0 {
            finish()
            return
        }
        if reachability.connection != .unavailable {
            main()
        }else {
            isSuspended = true
        }
    }
}
