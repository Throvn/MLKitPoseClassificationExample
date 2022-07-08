//
//  MLKitPoseClassificationExampleApp.swift
//  MLKitPoseClassificationExample
//
//  Created by Louis Stanko on 13.06.22.
//

import SwiftUI

@main
struct MLKitPoseClassificationExampleApp: App {
    var body: some Scene {
        WindowGroup {
			VStack {
				Text("MLKitPoseClassificationExample")
				VisionCameraView()
			}
        }
    }
}
