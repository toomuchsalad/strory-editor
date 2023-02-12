//
//  UIDevice.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 15.08.2022.
//

import Foundation
import UIKit

public func deviceHasHomeButton() -> Bool {
    if #available(iOS 11.0, *),
       UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > 0 {
        return true
    }
    return false
}
