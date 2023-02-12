//
//  MediaModel.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation
import UIKit

struct MediaModel {
    var videoURL: URL?
    var image: UIImage?
    var textViews: [AdvancedTextView] {
        didSet {
            let ids = textViews.map { $0.id }
            print(ids)
        }
    }
}
