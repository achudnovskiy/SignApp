//
//  AppDelegate.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-09.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import UserNotifications
import FBSDKCoreKit
import Branch

let regionRadius:Double = 30
let kUserNotificationSignId = "Notificaiton_SignId"



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self

//        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
//            print(settings)
//        }
        User.current.locationPermissionCheck = {() in return CLLocationManager.authorizationStatus() == .authorizedAlways}
//        User.current.notificationPermissionCheck = {() in return }
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        setupLocalNotifications()
        setupLocationMonitoring()
        
        
        let branch: Branch = Branch.getInstance()
        branch.initSession(launchOptions: launchOptions, automaticallyDisplayDeepLinkController: true, deepLinkHandler: { params, error in
            if error == nil {
                // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
                // params will be empty if no data found
                // ... insert custom logic here ...
                print("params: %@", params!.description)
            }
        })
        
        
        return true
    }
    
    //MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            let signId = response.notification.request.content.userInfo[kUserNotificationSignId]!
            
            NotificationCenter.default.post(name: kNotificationScrollToSign, object: nil, userInfo: [kNotificationScrollToSignId:signId])
        }
        else if (response.actionIdentifier == UNNotificationDismissActionIdentifier) {
        
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        SignDataSource.sharedInstance.saveData(notifyUI: false)
    }

    
    //MARK: - Location Monitoring
    
    func setupLocationMonitoring() {

        LocationTracker.sharedInstance.startMonitoringForLocations() { (location) in
            
            if SignDataSource.sharedInstance.collectSignWithId(location.objectId) == false {
                print("Couldn't discover sign with id \(location.objectId)")
                return
            }
            
            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = location.name
            notificationContent.subtitle = "You got the new sign!"
//             notificationContent.attachments
            // notificationContent.body - add for more descriptive notifcation
            // notificationContent.categoryIdentifier - Add for actions i.e. add or skip the sign
            notificationContent.userInfo = [kUserNotificationSignId: location.objectId]

            
            let notificationRequest = UNNotificationRequest(identifier: "SignDiscover", content: notificationContent, trigger: nil)
            UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: { (error) in
                if (error != nil) {
                    NSLog("Error with delivering the notification, details: \(String(describing: error))")
                }
            })
        }
    }
    
    func requestLocationPermissions() {
//        UIApplication.shared.currentUserNotificationSettings
    }
    
    
    //  let settingsURL = URL(string: UIApplicationOpenSettingsURLString)!
    //  UIApplication.shared.open(settingsURL, options: [:], detectionHandler: nil)

    func notifyAboutPermissionProblem() {
        
    }
    
    //MARK: - Local Notificaitons
    
    func setupLocalNotifications()
    {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { (granted, error) in
            if granted {
                
            }
            else {
                // TODO: Prompt user about not having permissions
            }
        }
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        Branch.getInstance().handleDeepLink(url);

        return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }
    
    // Respond to Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        // pass the url to the handle deep link call
        Branch.getInstance().continue(userActivity)
        
        return true
    }
    
    // TODO: update the content of the already notification
    
    


   

}

