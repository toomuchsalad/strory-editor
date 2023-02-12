//
//  FontSlider.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 03.08.2022.
//

import Foundation
import UIKit

class FontSliderVC: UIViewController {
    
    @IBOutlet weak var sliderBgView: UIView!
    @IBOutlet weak var sliderView: UISlider!
    
    var previousValue: Float?
    
    var delegate: SliderDegegate?
    
    override func viewDidLoad() {
        
        UIView.performWithoutAnimation {
            sliderView.transform = CGAffineTransform(rotationAngle: -.pi/2)
        }
        
        sliderBgView.backgroundColor = .clear
        sliderBgView.clipsToBounds = true
        sliderBgView.layer.cornerRadius = 2
        
        let width = sliderBgView.frame.size.width
        let height = sliderBgView.frame.size.height
        let path = CGMutablePath()
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width/2, y: height))
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = UIColor.white.withAlphaComponent(0.6).cgColor
        
        sliderBgView.layer.insertSublayer(shape, at: 0)
        
        self.sliderView.setValue(previousValue ?? 1, animated: false)
        
        if let previousValue = previousValue {
            sliderView.setValue(previousValue, animated: false)
        } else {
            sliderView.setValue(Float((38 - 16)) / 32, animated: false)
        }
                
    }
    
    @IBAction func sliderViewAction(_ sender: UISlider) {
        delegate?.setFontSizeVlaue(value: sender.value)
    }
    
    
}


