//
//  UILabel+Gradient.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 01.08.2022.
//

import Foundation
import UIKit

extension UILabel {
    
    func drawGradientColor(colors: [CGColor]) {
        let currentContext = UIGraphicsGetCurrentContext()
        currentContext?.saveGState()
        defer { currentContext?.restoreGState() }
        
        let size = bounds.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil) else {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()
        context?.drawLinearGradient(gradient, start: CGPoint(x: size.width/2, y: 0), end: CGPoint(x: size.width/2, y: size.height), options: [])
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = gradientImage else {
            return
        }
        self.textColor = UIColor(patternImage: image)
    }
}
