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

import CoreImage

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
	
	let coreImageContext: CIContext
    
    init(givenParent: VisionCameraUIView) {
        parent = givenParent
		
		// Base pose detector with streaming, when depending on the PoseDetection SDK
		options.detectorMode = .stream
		poseDetector = PoseDetector.poseDetector(options: options)
		
		// for rotating the sample buffer
		if let metalDevice = MTLCreateSystemDefaultDevice() {
			coreImageContext = CIContext(mtlDevice: metalDevice)
		} else {
			coreImageContext = CIContext(options: nil)
		}
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
	///
	/// This took me ages, but somehow the output is 90deg rotated.
	/// And although it's a quick and dirty solution, rotating the sample buffer helped.
	/// If you have any suggestions and or know swift better then me, PRs are sooooooo welcome!
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		let pixelBuffer: CVPixelBuffer = self.rotate(sampleBuffer)!
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
		let image = self.convert(cmage: ciImage)
		let visionImage = VisionImage(image: image)
		
		visionImage.orientation = imageOrientation(
			deviceOrientation: UIDevice.current.orientation,
			cameraPosition: AVCaptureDevice.Position.front)
		
		var poses: [Pose]
		do {
			poses = try poseDetector.results(in: visionImage)
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
	
	/// Convert CIImage to UIImage
	private func convert(cmage: CIImage) -> UIImage {
		let context = CIContext(options: nil)
		let cgImage = context.createCGImage(cmage, from: cmage.extent)!
		let image = UIImage(cgImage: cgImage)
		return image
	}
	
	/// Rotates the sample buffer by 90 deg. Without this, the pose detection works like shit.
	/// - Parameter sampleBuffer
	/// - Returns: the rotated samplebuffer as CVPixelBuffer or nil
	private func rotate(_ sampleBuffer: CMSampleBuffer) -> CVPixelBuffer? {
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return nil
		}
		var newPixelBuffer: CVPixelBuffer?
		let error = CVPixelBufferCreate(kCFAllocatorDefault,
										CVPixelBufferGetHeight(pixelBuffer),
										CVPixelBufferGetWidth(pixelBuffer),
										kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
										nil,
										&newPixelBuffer)
		guard error == kCVReturnSuccess,
			  let buffer = newPixelBuffer else {
			return nil
		}
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
		coreImageContext.render(ciImage, to: buffer)
		return buffer
	}
}
