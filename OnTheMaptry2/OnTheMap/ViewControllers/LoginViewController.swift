//
//  LoginViewController.swift
//  on the map
//
//  Created by fatoom on 10/10/1440 AH.
//  Copyright © 1440 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var buttonSignUp: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userEmail.delegate = self
        userPassword.delegate = self
        
        buttonLogin.roundCorners()
    }
    
    // MARK: - Actions
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        
        activityIndicator.startAnimating()
        enableControllers(false)
        
        guard  let email = userEmail.text, !email.isEmpty else {
            activityIndicator.stopAnimating()
            enableControllers(true)
            showInfo(withTitle: "Field required", withMessage: "Please fill in your email.")
            return
        }
        guard  let password = userPassword.text, !password.isEmpty else {
            activityIndicator.stopAnimating()
            enableControllers(true)
            showInfo(withTitle: "Field required", withMessage: "Please fill in your password.")
            return
        }
        authenticateUser(email: email, password: password)
    }
    
    @IBAction func signUpPressed(_ sender: AnyObject) {
        openWithSafari("https://auth.udacity.com/sign-up")
    }
    
    // MARK: - Helpers
    
    private func authenticateUser(email: String, password: String) {
        Client.shared().authenticateWith(userEmail: email, andPassword: password) { (success, errorMessage) in
            if success {
                self.performUIUpdatesOnMain {
                    self.userEmail.text = ""
                    self.userPassword.text = ""
                }
                self.performSegue(withIdentifier: "showMap", sender: nil)
            } else {
                self.performUIUpdatesOnMain {
                    self.showInfo(withTitle: "Login falied", withMessage: errorMessage ?? "Error while performing login.")
                }
            }
            self.performUIUpdatesOnMain {
                self.activityIndicator.stopAnimating()
            }
            self.enableControllers(true)
        }
    }
    
    private func enableControllers(_ enable: Bool) {
        self.enableUI(views: userEmail, userPassword, buttonLogin, buttonSignUp, enable: enable)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

