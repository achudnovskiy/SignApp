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
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
         FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
         // Optional: Place the button in the center of your view.
         loginButton.center = self.view.center;
         [self.view addSubview:loginButton];
         */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func fbLoginAction() {
        let loginManager = FBSDKLoginManager()
        loginManager.defaultAudience = .friends
        
        /*
         FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
         // Optional: Place the button in the center of your view.
         loginButton.center = self.view.center;
         [self.view addSubview:loginButton];
         */
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
