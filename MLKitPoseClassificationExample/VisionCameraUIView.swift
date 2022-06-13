//
//  VisionCameraUIView.swift
//  Dopamining
//
//  Created by Louis Stanko on 19.05.22.
//

import UIKit
import AVFoundation
import Vision
import MLKitPoseDetection
import MLKit
import SwiftUI

/// Does the Vision Recognition, and Camera Preview.
struct VisionCameraView: UIViewRepresentable {
	
	typealias UIViewType = VisionCameraUIView
	
	func makeUIView(context: UIViewRepresentableContext<VisionCameraView>) -> VisionCameraUIView {
		VisionCameraUIView()
	}
	
	/// Since VisionCameraView only supplies the VideoStream, it doesn't need to listen to
	/// changes from the UI
	func updateUIView(_ uiView: VisionCameraUIView, context: UIViewRepresentableContext<VisionCameraView>) {
	}
}

class VisionCameraUIView: UIView {
    private var captureSession: AVCaptureSession?
    /// Canvas where the recognized pose estimation keypoints are drawn onto
    private var detectionOverlay: CALayer! = CALayer()
    var bufferSize: CGSize = .zero
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "com.throvn.VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var videoOutputProcesser: VisionVideoOutputProcessor?
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		return layer as! AVCaptureVideoPreviewLayer
    }

	let poseClassifierProcessor: PoseClassifierProcessor = PoseClassifierProcessor(isStreamMode: true)
    
    init() {
        super.init(frame: .zero)
        var allowedAccess = false
		
		layer.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
		
        let blocker = DispatchGroup()
        blocker.enter()
        AVCaptureDevice.requestAccess(for: .video) { flag in
            allowedAccess = flag
            blocker.leave()
        }
        blocker.wait()

        if !allowedAccess {
            print("!!! NO ACCESS TO CAMERA")
            return
        }

        // setup session
        let session = AVCaptureSession()
        session.beginConfiguration()

		let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
		// let videoDevice: AVCaptureDevice? = AVCaptureDevice.devices(for: .video)[1]
        guard videoDevice != nil, let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), session.canAddInput(videoDeviceInput) else {
            print("!!! NO CAMERA DETECTED")
            return
        }
        session.addInput(videoDeviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            
            videoOutputProcesser = VisionVideoOutputProcessor(givenParent: self)
            videoDataOutput.setSampleBufferDelegate(videoOutputProcesser, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            print("Buffer size: \(bufferSize.width) height: \(bufferSize.height)")
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        
        session.commitConfiguration()
        self.captureSession = session
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        print("did Move To Superview")
        if nil != self.superview {
            self.videoPreviewLayer.videoGravity = .resizeAspectFill
            self.videoPreviewLayer.session = self.captureSession

            detectionOverlay.bounds = CGRect(x: 0.0,
                                             y: 0.0,
                                             width: bufferSize.width,
                                             height: bufferSize.height)
            self.videoPreviewLayer.addSublayer(detectionOverlay)
            
            self.captureSession?.startRunning()
        } else {
            self.captureSession?.stopRunning()
        }
    }
    
	
	private enum Constant {
		static let smallDotRadius: CGFloat = 15.0
		static let lineWidth: CGFloat = 5.0
	}
	
	private lazy var annotationOverlayView: UIView = {
		let annotationOverlayView = UIView(frame: .zero)
		annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
		return annotationOverlayView
	}()
	
	private func normalizedPoint(
		fromVisionPoint point: VisionPoint,
		width: CGFloat,
		height: CGFloat
	) -> CGPoint {
		let cgPoint = CGPoint(x: point.x, y: point.y)
		var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
		normalizedPoint = videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
		return normalizedPoint
	}
	
    /// Processes a single observation and writes the results on screen
    /// - Parameter observation: Observation to process
    func processObservation(_ poses: [Pose]) {
		weak var weakSelf = self
		guard let strongSelf = weakSelf else {
			print("Self is nil!")
			return
		}
		
		// If no pose is detected, clear the screen
		if poses.isEmpty {
			DispatchQueue.main.async {
				for view in strongSelf.annotationOverlayView.subviews {
					view.removeFromSuperview()
				}
			}
			return
		}
		
		// Pose detected. Currently, only single person detection is supported.
		poses.forEach { pose in
			DispatchQueue.main.async {
				let poseOverlayView = UIUtilities.createPoseOverlayView(
					forPose: pose,
					inViewWithBounds: strongSelf.videoPreviewLayer.bounds,
					lineWidth: Constant.lineWidth,
					dotRadius: Constant.smallDotRadius,
					positionTransformationClosure: { (position) -> CGPoint in
						return strongSelf.normalizedPoint(
							fromVisionPoint: position, width: self.bufferSize.width, height: self.bufferSize.height)
					}
				)
				
				// let classificationResult: [String] = []
				let result: [String] = self.poseClassifierProcessor.getPoseResult(pose: pose)
				 print("Result: \(result)")
				
				for view in strongSelf.annotationOverlayView.subviews {
					view.removeFromSuperview()
				}
				strongSelf.annotationOverlayView.addSubview(poseOverlayView)
			}
		}
		DispatchQueue.main.async {
			strongSelf.videoPreviewLayer.addSublayer(self.annotationOverlayView.layer)
		}
    }
}
