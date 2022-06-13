//
//  VisionVideoProcesser.swift
//  Dopamining
//
//  Created by Louis Stanko on 19.05.22.
//

import Foundation
import AVFoundation
import Vision
import UIKit

import MLKitPoseDetection
import MLKitVision

/// Handles incoming captured Images and delegates them to the Vision recognizer.
/// Afterwards the results are sent back to the parent.
class VisionVideoOutputProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// The parent which invokes this class. Needed because a lot of parent variables need to be updated. Which boils down to calling the method processObservation in the parent.
    /// I know that this is bad code, but AVFoundation is a piece of sh**
    let parent: VisionCameraUIView
	
	let options = PoseDetectorOptions()
	let poseDetector: PoseDetector
    
    init(givenParent: VisionCameraUIView) {
        parent = givenParent
		
		// Base pose detector with streaming, when depending on the PoseDetection SDK
		options.detectorMode = .stream
		poseDetector = PoseDetector.poseDetector(options: options)
    }
	
	func imageOrientation(
		deviceOrientation: UIDeviceOrientation,
		cameraPosition: AVCaptureDevice.Position
	) -> UIImage.Orientation {
		switch deviceOrientation {
		case .portrait:
			return cameraPosition == .front ? .leftMirrored : .right
		case .landscapeLeft:
			return cameraPosition == .front ? .downMirrored : .up
		case .portraitUpsideDown:
			return cameraPosition == .front ? .rightMirrored : .left
		case .landscapeRight:
			return cameraPosition == .front ? .upMirrored : .down
		case .faceDown, .faceUp, .unknown:
			return .up
		@unknown default:
			fatalError()
		}
	}
	
    
    /// Runs the Vision Model on top of the captured output
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
		
		let image = VisionImage(buffer: sampleBuffer)
		image.orientation = imageOrientation(
			deviceOrientation: UIDevice.current.orientation,
			cameraPosition: AVCaptureDevice.Position.front)
		
		var poses: [Pose]
		do {
			poses = try poseDetector.results(in: image)
		} catch let error {
			print("Failed to detect pose with error: \(error.localizedDescription).")
			return
		}
		
		parent.processObservation(poses)
    }
    
    /// Fires when a frame was dropped.
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("frame dropped")
    }
}
