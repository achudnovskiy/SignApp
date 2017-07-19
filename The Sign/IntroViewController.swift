//
//  IntroViewController.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-07-16.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit

class IntroViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var loginViewController:UIViewController!
    var permissionViewController:UIViewController!
    var currentPageIndex = 0
    var pageControllers:[UIViewController] = []
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return viewController == loginViewController ?  permissionViewController : nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return viewController == permissionViewController ?  loginViewController : nil
    }

    func loadControllers() -> [UIViewController] {
        loginViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginScreen")
        permissionViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "permissionScreen")
        return [loginViewController, permissionViewController]
    }
    
    func skipRegistration() {
        setViewControllers([permissionViewController], direction: .forward, animated: true, completion: nil)
    }
    
    func finishIntro() {
        UserDefaults.standard.set(true, forKey: "introCompleted")
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pageControllers = loadControllers()
        
        self.delegate = self
        self.dataSource = self
        setViewControllers([loginViewController], direction: .forward, animated: true, completion: nil)
        
        let backgroundImage = #imageLiteral(resourceName: "DefaultBackgroundImage").optimizedImage().applyDefaultEffect()
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.frame = self.view.bounds
        self.view.addSubview(backgroundImageView)
        self.view.sendSubview(toBack: backgroundImageView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 2
    }
    

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0 
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
