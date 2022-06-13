//
// CHECKED
//  RepetitionCounter.swift
//  Dopamining
//
//  Created by Louis Stanko on 07.06.22.
//

import Foundation

class RepetitionCounter {
	// These thresholds can be tuned in conjunction with the Top K values in {@link PoseClassifier}.
	// The default Top K value is 10 so the range here is [0-10].
	private static let DEFAULT_ENTER_THRESHOLD: Float = 6.0
	private static let DEFAULT_EXIT_THRESHOLD: Float = 4.0
	
	private final var className: String
	private final var enterThreshold: Float
	private final var exitThreshold: Float
	
	private var numRepeats: Int
	private var poseEntered: Bool
	
	convenience init(className: String) {
		self.init(className: className, enterThreshold: Self.DEFAULT_ENTER_THRESHOLD, exitThreshold: Self.DEFAULT_EXIT_THRESHOLD)
	}
	
	init(className: String, enterThreshold: Float, exitThreshold: Float) {
		self.className = className
		self.enterThreshold = enterThreshold
		self.exitThreshold = exitThreshold
		numRepeats = 0
		poseEntered = false
	}
	
	func addClassificationResult(classificationResult: ClassificationResult) -> Int {
		let poseConfidence: Float = classificationResult.getClassConfidence(className: className)
		if !poseEntered {
			poseEntered = poseConfidence > enterThreshold
			return numRepeats
		}
		
		if poseConfidence < exitThreshold {
			numRepeats += 1
			poseEntered = false
		}
		
		return numRepeats
	}
	
	func getClassName() -> String {
		className
	}
	
	func getNumRepeates() -> Int {
		numRepeats
	}
}
