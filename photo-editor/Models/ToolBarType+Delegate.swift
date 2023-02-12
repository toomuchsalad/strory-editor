//
//  ToolBarType.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation
import UIKit

enum ToolBarType {
    case textColor
    case bgColor
    case font
    case mention
    case none
}

protocol ToolBarDelegate {
    
    func textColorDidChanged(color: UIColor)
    
    func bgColorDidChanged(color: UIColor)
    
    func fontDidChanged(font: UIFont)
    
    func tagDidSelected(username: String)
    
    func startMentionMode()
    
}
