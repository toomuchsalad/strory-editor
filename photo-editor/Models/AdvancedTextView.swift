//
//  AdvancedTextView.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation
import UIKit

class AdvancedTextView: UITextView {

    var id: String!
    var lastSize: CGSize?
    var lastPanPoint: CGPoint?
    var lastPoint: CGPoint?
    var lastTextViewTransform: CGAffineTransform?
    var lastTextViewTransCenter: CGPoint?
    var lastRotation: CGFloat?

    var type: TextViewType = .text
    var linkURL: URL?
    
    var textAlpha: Float = 1 {
        didSet {
            self.textColor = self.textColor?.withAlphaComponent(CGFloat(textAlpha))
        }
    }
    
    var bgAlpha: Float = 1 {
        didSet {
            self.backgroundColor = self.backgroundColor?.withAlphaComponent(CGFloat(bgAlpha))
        }
    }
    
    var currentScale: CGPoint {
        let a = transform.a
        let b = transform.b
        let c = transform.c
        let d = transform.d

        let sx = sqrt(a * a + b * b)
        let sy = sqrt(c * c + d * d)

        return CGPoint(x: sx, y: sy)
    }
    
}

extension AdvancedTextView {
    
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


