//
//  PreviewVC+Ges.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation
import UIKit

extension PreviewVC: UIGestureRecognizerDelegate {
    //Translation is moving object
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        if !textEditMode, let view = recognizer.view {
            moveView(view: view, recognizer: recognizer)
        }
    }
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if !textEditMode, let view = recognizer.view {
            if let textView = view as? AdvancedTextView {

                switch textView.type {
                case .text:
                    self.activeTextView = textView
                    self.textEditMode = true
                    textView.becomeFirstResponder()
                    if #available(iOS 10.0, *) {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                    }
                case .link:
                    print("link")
                    guard let url = textView.linkURL, UIApplication.shared.canOpenURL(url) else {
                        return
                    }
                    UIApplication.shared.open(url)
                case .mention:
                    self.toolBarType = .mention
                    self.textEditMode = true
                    self.activeTextView = textView
                    textView.becomeFirstResponder()
                    if #available(iOS 10.0, *) {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                    }
                }
                
                
            }
        }
    }
    
    @objc func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        guard let view = sender.view as? AdvancedTextView else {
            return
        }
        
        view.transform = view.transform.scaledBy(x: sender.scale, y: sender.scale)
        sender.scale = 1
    }
    
    @objc func handleRotationGesture(_ sender: UIRotationGestureRecognizer) {
        guard let view = sender.view as? AdvancedTextView, let existTextView = NewMediaManager.shared.newMedia[mediaIndex].textViews.filter({$0.id == view.id}).first else {
            return
        }
        var originalRotation = CGFloat()
        switch sender.state {
        case .began:
            sender.rotation = view.lastRotation ?? 0
            originalRotation = sender.rotation
        case .changed:
            let scale = CGAffineTransform(scaleX: view.currentScale.x, y: view.currentScale.y)
            let newRotation = sender.rotation + originalRotation

            view.transform = scale.rotated(by: newRotation)
        case .ended:
            view.lastRotation = sender.rotation
            existTextView.lastRotation = sender.rotation
        default:
            break
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func moveView(view: UIView, recognizer: UIPanGestureRecognizer)  {
        
        guard let textView = view as? AdvancedTextView, let existTextView = NewMediaManager.shared.newMedia[mediaIndex].textViews.filter({$0.id == textView.id}).first else {
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            self.deleteImageView.alpha = 0.7
        }
        
        view.superview?.bringSubviewToFront(view)
        let pointToSuperView = recognizer.location(in: self.view)
        
        view.center = CGPoint(x: view.center.x + recognizer.translation(in: previewView).x, y: view.center.y + recognizer.translation(in: previewView).y)
        
        recognizer.setTranslation(CGPoint.zero, in: previewView)
        
        if let previousPoint = existTextView.lastPanPoint {
            //View is going into deleteView
            if deleteImageView.frame.contains(pointToSuperView) && !deleteImageView.frame.contains(previousPoint) {
                if #available(iOS 10.0, *) {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                }
                UIView.animate(withDuration: 0.3, animations: {
                    view.transform = view.transform.scaledBy(x: 0.25, y: 0.25)
                    view.center = recognizer.location(in: self.previewView)
                })
            }
            //View is going out of deleteView
            else if deleteImageView.frame.contains(previousPoint) && !deleteImageView.frame.contains(pointToSuperView) {
                //Scale to original Size
                UIView.animate(withDuration: 0.3, animations: {
                    view.transform = view.transform.scaledBy(x: 4, y: 4)
                    view.center = recognizer.location(in: self.previewView)
                })
            }
        }
        existTextView.lastPanPoint = pointToSuperView
        
        if recognizer.state == .ended {
            existTextView.lastPanPoint = nil
            UIView.animate(withDuration: 0.3) {
                self.deleteImageView.alpha = 0
            }
            let point = recognizer.location(in: self.view)
            existTextView.lastPoint = point
            
            if deleteImageView.frame.contains(point) {
                view.removeFromSuperview()
                NewMediaManager.shared.newMedia[mediaIndex].textViews = NewMediaManager.shared.newMedia[mediaIndex].textViews.filter({$0.id != existTextView.id})
                if #available(iOS 10.0, *) {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }
    
}
