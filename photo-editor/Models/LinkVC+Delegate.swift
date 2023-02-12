//
//  LinkVC+Delegate.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 30.07.2022.
//

import Foundation

protocol LinkDelegate {
    
    func setData(link: URL, text: String?, textViewID: String)
    
}
