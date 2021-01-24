//
//  UploadManager.swift
//  TreeTracker
//
//  Created by Alex Cornforth on 05/11/2020.
//  Copyright © 2020 Greenstand. All rights reserved.
//

import Foundation

protocol UploadManagerDelegate: class {
    func uploadManagerDidStartUploadingTrees(_ uploadManager: UploadManager)
    func uploadManagerDidStopUploadingTrees(_ uploadManager: UploadManager)
    func uploadManager(_ uploadManager: UploadManager, didError error: Error)
}

protocol UploadManaging: class {
    var delegate: UploadManagerDelegate? { get set }
    func startUploading()
    func stopUploading()
    var isUploading: Bool { get }
}

class UploadManager: UploadManaging {

    weak var delegate: UploadManagerDelegate?

    private let coredataManager: CoreDataManaging
    private let treeUploadService: TreeUploadService
    private let planterUploadService: PlanterUploadService
    private(set) var isUploading: Bool = false
    private lazy var uploadOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .background
        queue.name = "UploadManagerQueue"
        return queue
    }()

    init(treeUploadService: TreeUploadService, planterUploadService: PlanterUploadService, coredataManager: CoreDataManaging) {
        self.treeUploadService = treeUploadService
        self.planterUploadService = planterUploadService
        self.coredataManager = coredataManager
    }

    func startUploading() {

        guard !isUploading else {
            return
        }

        Logger.log("UploadManager: Uploads started")
        isUploading = true
        delegate?.uploadManagerDidStartUploadingTrees(self)

        let uploadOperation = BlockOperation {
            for value in 0...100 {
                sleep(1)
                print(value)
            }
        }
//
//        let uploadOperation = UploadOperation(
//            planterUploadService: planterUploadService,
//            treeUploadService: treeUploadService
//        )

        let finishOperation = BlockOperation {
            DispatchQueue.main.async {
                Logger.log("UploadManager: Uploads complete")
                self.stopUpoading()
            }
        }
        finishOperation.addDependency(uploadOperation)

        uploadOperationQueue.addOperations(
            [
                uploadOperation,
                finishOperation
            ],
            waitUntilFinished: false
        )
    }

    func stopUploading() {
        guard isUploading else {
            return
        }
        Logger.log("UploadManager: Uploads stopped")
        uploadOperationQueue.cancelAllOperations()
        stopUpoading()
    }

    deinit {
        print("UploadManager deinit")
    }
}

private extension UploadManager {

    func stopUpoading() {
        isUploading = false
        delegate?.uploadManagerDidStopUploadingTrees(self)
    }
}
