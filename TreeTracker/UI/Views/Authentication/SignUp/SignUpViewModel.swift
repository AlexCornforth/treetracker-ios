//
//  SignUpViewModel.swift
//  TreeTracker
//
//  Created by Alex Cornforth on 15/05/2020.
//  Copyright © 2020 Greenstand. All rights reserved.
//

import UIKit

protocol SignUpViewModelCoordinatorDelegate: class {
    func signUpViewModel(_ signUpViewModel: SignUpViewModel, didSignUpWithusername planter: Planter)
}

protocol SignUpViewModelViewDelegate: class {
    func signUpViewModel(_ signUpViewModel: SignUpViewModel, didReceiveError error: Error)
    func signUpViewModel(_ signUpViewModel: SignUpViewModel, didValidateFirstName result: Validation.Result)
    func signUpViewModel(_ signUpViewModel: SignUpViewModel, didValidateLastName result: Validation.Result)
    func signUpViewModel(_ signUpViewModel: SignUpViewModel, didValidateOrganizationName result: Validation.Result)
    func signUpViewModel(_ signUpViewModel: SignUpViewModel, didUpdateSignUpEnabled enabled: Bool)
}

class SignUpViewModel {

    private let signUpService: SignUpService
    private let username: Username

    weak var coordinatorDelegate: SignUpViewModelCoordinatorDelegate?
    weak var viewDelegate: SignUpViewModelViewDelegate?

    init(username: Username, signUpService: SignUpService) {
        self.username = username
        self.signUpService = signUpService
    }

    let title: String = L10n.SignUp.title

    var usernameText: String {
        return username.value
    }

    var usernameIcon: UIImage {
        switch username {
        case .email:
            return Asset.Assets.mail.image
        case .phoneNumber:
            return Asset.Assets.phone.image
        }
    }

    var firstName: String = "" {
        didSet {
            viewDelegate?.signUpViewModel(self, didValidateFirstName: firstNameValid)
            viewDelegate?.signUpViewModel(self, didUpdateSignUpEnabled: signUpEnabled)
        }
    }
    var lastName: String = "" {
        didSet {
            viewDelegate?.signUpViewModel(self, didValidateLastName: lastNameValid)
            viewDelegate?.signUpViewModel(self, didUpdateSignUpEnabled: signUpEnabled)
        }
    }
    var organizationName: String = "" {
        didSet {
            viewDelegate?.signUpViewModel(self, didValidateOrganizationName: organizationNameValid)
            viewDelegate?.signUpViewModel(self, didUpdateSignUpEnabled: signUpEnabled)
        }
    }

    func signUp() {

        signUpService.signUp(withDetails: signUpDetails) { (result) in
            switch result {
            case .success(let username):
                coordinatorDelegate?.signUpViewModel(self, didSignUpWithusername: username)
            case .failure(let error):
                viewDelegate?.signUpViewModel(self, didReceiveError: error)
            }
        }
    }
}

// MARK: - Private
private extension SignUpViewModel {

    var firstNameValid: Validation.Result {
        return name.firstNameValid
    }

    var lastNameValid: Validation.Result {
        return name.lastNameValid
    }

    var organizationNameValid: Validation.Result {
        return organization.isValid
    }

    var signUpEnabled: Bool {
        switch (name.isValid, organization.isValid) {
        case (.valid, .valid),
             (.valid, .empty):
            return true
        default:
            return false
        }
    }

    var name: Name {
        return Name(
            firstName: firstName,
            lastName: lastName
        )
    }

    var organization: Organization {
        return Organization(
            name: organizationName
        )
    }

    var signUpDetails: SignUpDetails {
        return SignUpDetails(
            username: username,
            name: name,
            organization: organization
        )
    }
}
