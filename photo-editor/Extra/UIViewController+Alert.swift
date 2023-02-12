//
//  UIViewController+Alert.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 28.07.2022.
//

import Foundation
import UIKit
    
public func showAlert(title:String?, body:String?) {
    
    let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
    let ok = UIAlertAction(title: "Ok", style: .default)
    alert.addAction(ok)
    
    UIApplication.shared.topMostViewController()?.present(alert, animated: true)
    
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return self.keyWindow?.rootViewController?.topMostViewController()
    }
}
