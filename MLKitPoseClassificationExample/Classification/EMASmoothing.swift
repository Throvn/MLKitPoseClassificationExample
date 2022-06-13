//
//  CHECKED
//  EMASmoothing.swift
//  Dopamining
//
//  Created by Louis Stanko on 07.06.22.
//

import Foundation

/// Runs EMA smoothing over a window with given stream of pose classification results.
class EMASmoothing {
	private static let DEFAULT_WINDOW_SIZE: Int = 10
	private static let DEFAULT_ALPHA: Float = 0.2
	
	private static let RESET_THRESHOLD_MS: Int = 100
	
	private final var windowSize: Int
	private final var alpha: Float
	
	private final var window: [ClassificationResult?] // ClassificationResult
	
	private var lastInputMs: Int = 0
	
	convenience init() {
		self.init(Self.DEFAULT_WINDOW_SIZE, Self.DEFAULT_ALPHA)
	}
	
	init(_ windowSize: Int, _ alpha: Float) {
		self.windowSize = windowSize
		self.alpha = alpha
		
		self.window = Array(repeating: nil, count: windowSize)
	}
	
	func getSmoothedResult(classificationResult: ClassificationResult) -> ClassificationResult {
		// Resets memory if the input is too far away from the previous one in time.
		// else try: https://stackoverflow.com/questions/43276555/how-to-get-exact-time-since-ios-device-booted
		let nowMs: Int = Int(ProcessInfo.processInfo.systemUptime * 1000)
		if nowMs - lastInputMs > Self.RESET_THRESHOLD_MS {
			window.removeAll()
		}
		lastInputMs = nowMs
		
		// If we are at window size, remove the last (oldest) result.
		if window.count == windowSize {
			_ = window.popLast()
		}
		
		// Insert at the beginning of the window.
		window.insert(classificationResult, at: 0)
		
		var allClasses: Set<String> = []
		for result in window {
			allClasses.formUnion(result!.getAllClasses())
		}
		
		let smoothedResult: ClassificationResult = ClassificationResult()
		
		for className in allClasses {
			var factor: Float = 1.0
			var topSum: Float = 0.0
			var bottomSum: Float = 0.0
			
			for result in window {
				let value: Float = result!.getClassConfidence(className: className)
				
				topSum += factor * value
				bottomSum += factor
				
				factor = factor * (1.0 - alpha)
			}
			smoothedResult.putClassConfidence(className: className, confidence: topSum / bottomSum)
		}
		
		return smoothedResult
	}
}
