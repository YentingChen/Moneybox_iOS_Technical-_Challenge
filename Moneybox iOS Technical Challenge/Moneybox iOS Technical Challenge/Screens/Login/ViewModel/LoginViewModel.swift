//
//  LoginViewModel.swift
//  Moneybox iOS Technical Challenge
//
//  Created by Yenting Chen on 2022/1/22.
//

import Foundation


/// LoginViewModel Input value and action
protocol LoginViewModelInputType {
    
    var emailInput: Bindable<String?> { get  }
    var passwordInput: Bindable<String?> { get }
    
    func loginButtonDidTapped()
}

/// LoginViewModel Output value and action
protocol LoginViewModelOutputType {
    
    var showLoadingIndicator: Bindable<Bool> { get }
    var buttonIsSendableOutput: Bindable<Bool> { get }
    var hideKeyboard: (() -> Void)? { get }
    
}

protocol LoginViewModelType: LoginViewModelInputType, LoginViewModelOutputType, ShowingAlertOutput {}

class LoginViewModel: LoginViewModelType {
    
    var showAlert: ((_ alert: SingleButtonAlert) -> Void)?
    
    var hideKeyboard: (() -> Void)?
    
    var showLoadingIndicator: Bindable<Bool> = Bindable(false)
    
    var emailInput: Bindable<String?> = Bindable(nil)
    
    var passwordInput: Bindable<String?> = Bindable(nil)
    
    var buttonIsSendableOutput: Bindable<Bool> = Bindable(false)
    
    var navigator: LoginNavigator
    
    let networkService = NetworkService<LoginRequest, LoginResponse>()
    
    let authSevice: AuthServiceType
    
    init(navigator: LoginNavigator, authService: AuthServiceType = AuthService.share) {
        
        self.navigator = navigator
        self.authSevice = authService
        
        bindInputValue()
    }
    
    func loginButtonDidTapped() {
        
        hideKeyboard?()
        
        if let emailInput = emailInput.value, let passwordInput = self.passwordInput.value {
            
            if emailInput.isValidEmail() {
                
                postLoginRequest(email: emailInput, password: passwordInput)
                
            } else {
                
                errorAlert(message: "wrong email format, please enter it again")
                
            }
            
        }
        
    }
    
    private func storeDatainAuthService(response: LoginResponse) {
        
        authSevice.bearerToken = response.session?.bearerToken
        authSevice.userDisplayName = response.user?.firstName
        
    }
    
    private func fininishLoginFlow() {
        
        DispatchQueue.main.async {
            
            self.navigator.finishLoginFlow()
            
        }
    }
    
    func postLoginRequest(email: String, password: String) {
        
        let request = LoginRequest(userEmail: email, userPassword: password)
        
        self.showLoadingIndicator.value = true
        networkService.load(request: request) { [weak self] result in
            
            self?.showLoadingIndicator.value = false
            
            switch result {
                
            case .success(let response):
                
                guard let response = response else {
                    self?.errorAlert(message: "response is nil!")
                    return
                }
                    
                self?.storeDatainAuthService(response: response)
                
                self?.fininishLoginFlow()

                
            case .failure(let error):
                
                self?.apiResponseErrorAlert(error: error)
            }
        }
        
    }
    
    private func bindInputValue() {
        
        emailInput.bindAndFire { [unowned self] email in
            
            self.checkIsSendable()
            
        }
        
        passwordInput.bindAndFire { [unowned self] email in
            
            self.checkIsSendable()
            
        }
    }
    
    /// Check if email and password both contain value, then button is sendable
    private func checkIsSendable() {
        
        if let email = emailInput.value, let password = passwordInput.value, !password.isEmpty, !email.isEmpty {
            
            self.buttonIsSendableOutput.value = true
            
        } else {
            
            self.buttonIsSendableOutput.value = false
        }
        
    }
    
}

extension String {
    func isValidEmail() -> Bool {
        // here, `try!` will always succeed because the pattern is valid
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }
}
