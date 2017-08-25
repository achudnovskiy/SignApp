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
    @IBOutlet weak var fbStatusLabel: UILabel!
    @IBOutlet weak var termsConditionsLabel: UILabel!
    @IBOutlet weak var fbLoginButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var backgrounImageVIew: UIImageView!
    @IBOutlet weak var overlayView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fbStatusLabel.text = ""
        fbLoginButton.layer.cornerRadius = 5
        fbLoginButton.layer.masksToBounds = true
        
        backgroundImageView.isHidden = isAppIntro
        overlayView.isHidden = isAppIntro
    }

    var isAppIntro:Bool {
        return self.parent?.isKind(of: IntroViewController.self) == true
    }
  
    @IBAction func skipAction(_ sender: Any) {
        if let introVc = self.parent as? IntroViewController {
            introVc.skipRegistration()
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func fbLoginAction(_ sender: Any) {
        let loginManager = FBSDKLoginManager()
        loginManager.defaultAudience = .friends
        
        loginManager.logIn(withPublishPermissions: ["publish_actions"], from: self) { (result, error) in
            if error != nil {
                self.fbStatusLabel.text = "Something wrong happened"
                print("\(String(describing: error))")
                return
            }
            
            if result!.isCancelled  || !result!.grantedPermissions.contains("publish_actions"){
                self.fbStatusLabel.text = "Not enough permissions granted"
                return
            }
            
            if self.isAppIntro {
                self.fbStatusLabel.text = "Registered".uppercased()
                guard let introVc = self.parent as? IntroViewController else { return }
                introVc.skipRegistration()
            }
            else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
