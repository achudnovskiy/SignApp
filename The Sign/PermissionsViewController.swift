//
//  PermissionsViewController.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-07-17.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import UserNotifications
import CoreLocation

class PermissionsViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var locationPermissionLabel: UILabel!
    @IBOutlet weak var notificationsPermssionLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.startButton.isHidden = !isAppIntro
        
        NotificationCenter.default.addObserver(self, selector: #selector(processUpdateUserPermissionsNotification(_:)), name: kNotificationPermissionsUpdate, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { 
            self.requestLocationnPermissions(completion: {() in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.requestNotificationPermissions(completion: nil)
                }
            })
        }
        
        User.current.evaluatePermissions()
    }
    
    var isAppIntro:Bool {
        return self.parent?.isKind(of: IntroViewController.self) == true
    }
    

    func requestNotificationPermissions(completion:(() -> Void)?) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { (granted, error) in
            DispatchQueue.main.async {
                if granted {
                    self.notificationsPermssionLabel.text = "GRANTED"
                }
                else {
                    self.notificationsPermssionLabel.text = "DENIED"
                }
            }
            if completion != nil {
                completion!()
            }
        }
    }
    
    func requestLocationnPermissions(completion:(() -> Void)?) {
        LocationTracker.sharedInstance.requestPermission { (granted) in
            DispatchQueue.main.async {
                if granted {
                    self.locationPermissionLabel.text = "GRANTED"
                }
                else {
                    self.locationPermissionLabel.text = "DENIED"
                }
            }

            if completion != nil {
                completion!()
            }
        }
    }
    
    
    @IBAction func finishAction(_ sender: Any) {
        guard let introVc = self.parent as? IntroViewController else { return }
        introVc.finishIntro()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func processUpdateUserPermissionsNotification(_ notification:Notification) {
        DispatchQueue.main.async {
            self.locationPermissionLabel.text     = User.current.locatingPermitted.rawValue.uppercased()
            self.notificationsPermssionLabel.text = User.current.notificationsPermitted.rawValue.uppercased()
        }
    }

}
