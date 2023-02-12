//
//  SliderVC.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 03.08.2022.
//

import Foundation
import UIKit

class AlphaSliderVC: UIViewController {
    
    @IBOutlet weak var sliderBgView: UIView!
    @IBOutlet weak var sliderView: UISlider!
    
    var previousValue: Float?
    
    var delegate: SliderDegegate?
    
    override func viewDidLoad() {
        
        UIView.performWithoutAnimation {
            sliderView.transform = CGAffineTransform(rotationAngle: -.pi/2)
        }
        
        sliderBgView.backgroundColor = .clear
        sliderBgView.layer.cornerRadius = 4
        sliderBgView.clipsToBounds = true
//        sliderBgView.layer.borderColor = UIColor.white.cgColor
//        sliderBgView.layer.borderWidth = 0.5
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.01).cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.sliderBgView.bounds
        
        self.sliderBgView.layer.insertSublayer(gradientLayer, at:0)
        
        self.sliderView.setValue(previousValue ?? 1, animated: false)
                
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeSliderValue(notif:)), name: .setSliderValue, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .setSliderValue, object: nil)
    }
    
    @objc func changeSliderValue(notif: Notification) {
        guard let info = notif.userInfo, let value = info["newValue"] as? Float else {
            return
        }
        sliderView.setValue(value, animated: true)
    }
    
    @IBAction func sliderViewAction(_ sender: UISlider) {
        delegate?.setAlphaValue(alpha: sender.value)
    }
    
    
}
