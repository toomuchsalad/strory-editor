//
//  NotificationNames.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation

extension Notification.Name {
    static let mediaLibraryAccessChanged = Notification.Name(rawValue: "mediaLibraryAccessChanged")
    static let newMediaDidChanged = Notification.Name(rawValue: "newMediaDidChanged")
    static let setSliderValue = Notification.Name(rawValue: "newSliderValue")
    static let videoDone = Notification.Name(rawValue: "videoDone")
    static let videoSaved = Notification.Name(rawValue: "videoSaved")
    static let videoError = Notification.Name(rawValue: "videoError")
    static let multiPhotoSaved = Notification.Name(rawValue: "multiPhotoSaved")
}
