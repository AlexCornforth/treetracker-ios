//
//  RootCoordinator.swift
//  TreeTracker
//
//  Created by Alex Cornforth on 02/05/2020.
//  Copyright © 2020 Greenstand. All rights reserved.
//

import UIKit

class RootCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []
    let configuration: CoordinatorConfigurable
    private let coreDataManager: CoreDataManaging
    private let currentPlanterService: CurrentPlanterService
    private let awsS3Client: AWSS3Client

    required init(configuration: CoordinatorConfigurable, coreDataManager: CoreDataManaging, awsS3Client: AWSS3Client) {
        self.configuration = configuration
        self.coreDataManager = coreDataManager
        self.currentPlanterService = LocalCurrentPlanterService(coreDataManager: coreDataManager)
        self.awsS3Client = awsS3Client
    }

    func start() {
        guard let currentPlanter = currentPlanterService.currentPlanter() else {
            showSignIn()
            return
        }
        showHome(planter: currentPlanter)
    }
}

// MARK: - Navigation
private extension RootCoordinator {

    func showLoadingViewController() {
        // Currently we don't use the loading view.
        // Lets keep it though for future use.
        configuration.navigationController.viewControllers = [
            loadingViewController
        ]
    }

    func showSignIn() {
        startCoordinator(coordinator: signInCoordinator)
    }

    func showHome(planter: Planter) {
        startCoordinator(coordinator: homeCoordinator(planter: planter))
    }
}

// MARK: - View Controllers
private extension RootCoordinator {

    var loadingViewController: UIViewController {
        return StoryboardScene.Loading.initialScene.instantiate()
    }
}

// MARK: - Child Coordinators
private extension RootCoordinator {

    var signInCoordinator: Coordinator {
        let signInCoordinator = SignInCoordinator(
            configuration: configuration,
            coreDataManager: coreDataManager
        )
        signInCoordinator.delegate = self
        return signInCoordinator
    }

    func homeCoordinator(planter: Planter) -> Coordinator {

        let imageUploadService = AWSS3ImageUploadService(s3Client: awsS3Client)
        let bundleUploadService = AWSS3BundleUploadService(s3Client: awsS3Client)

        let treeUploadService = LocalTreeUploadService(
            coreDataManager: coreDataManager,
            bundleUploadService: bundleUploadService,
            imageUploadService: imageUploadService,
            documentManager: DocumentManager()
        )

        let planterUploadService = LocalPlanterUploadService(
            coreDataManager: coreDataManager,
            imageUploadService: imageUploadService,
            bundleUploadService: bundleUploadService,
            documentManager: DocumentManager(),
            planter: planter
        )

        let uploadManager = UploadManager(
            treeUploadService: treeUploadService,
            planterUploadService: planterUploadService,
            coredataManager: coreDataManager
        )

        let homeCoordinator = HomeCoordinator(
            configuration: configuration,
            coreDataManager: coreDataManager,
            planter: planter,
            uploadManager: uploadManager
        )

        homeCoordinator.delegate = self
        return homeCoordinator
    }
}

// MARK: - SignInCoordinatorDelegate
extension RootCoordinator: SignInCoordinatorDelegate {

    func signInCoordinator(_ signInCoordinator: SignInCoordinator, didSignInPlanter planter: Planter) {
        currentPlanterService.updateCurrentPlanter(planter: planter)
        childCoordinators.removeAll()
        showHome(planter: planter)
    }
}

// MARK: - HomeCoordinatorDelegate
extension RootCoordinator: HomeCoordinatorDelegate {

    func homeCoordinatorDidLogout(_ homeCoordinator: HomeCoordinator) {
        currentPlanterService.clearCurrentPlanter()
        childCoordinators.removeAll()
        showSignIn()
    }
}
