//
//  Paldean_PicnicsApp.swift
//  Paldean Picnics
//
//  Created by Penelope on 10/4/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct Paldean_PicnicsApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State()) {
                AppFeature()
            })
        }
    }
}
