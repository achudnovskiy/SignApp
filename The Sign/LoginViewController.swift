//
//  LoginViewController.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-03-01.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var fbErrorLabel: UILabel!
    @IBOutlet weak var termsConditionsLabel: UILabel!
    @IBOutlet weak var fbLoginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fbLoginButton.layer.cornerRadius = 5
        fbLoginButton.layer.masksToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func fbLoginAction(_ sender: Any) {
        let loginManager = FBSDKLoginManager()
        loginManager.defaultAudience = .friends
        
        loginManager.logIn(withPublishPermissions: ["publish_actions"], from: self) { (result, error) in
            if error != nil {
                print("\(String(describing: error))")
                return
            }
            
            if result!.isCancelled  || !result!.grantedPermissions.contains("publish_actions"){
                self.fbErrorLabel.text = "Not enough permissions granted"
            }
        }
    }
}
