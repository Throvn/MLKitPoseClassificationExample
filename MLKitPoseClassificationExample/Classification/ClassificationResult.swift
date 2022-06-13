//
//  CHECKED
//  ClassificationResult.swift
//  Dopamining
//
//  Created by Louis Stanko on 07.06.22.
//

import Foundation

class ClassificationResult {
	// For an entry in this map, the key is the class name, and the value is how many times this class
	// appears in the top K nearest neighbors. The value is in range [0, K] and could be a float after
	// EMA smoothing. We use this number to represent the confidence of a pose being in this class.
	private final var classConfidences: [String: Float] = [:]
	
	func getAllClasses() -> Set<String> {
		return Set(classConfidences.keys)
	}
	
	func getClassConfidence(className: String) -> Float {
		return classConfidences[className] ?? 0.0
	}
	
	func getMaxConfidenceClass() -> String {
		// TODO: make sure its the same as =>
		// return max(
		// classConfidences.entrySet(),
		// (entry1, entry2) -> (int) (entry1.getValue() - entry2.getValue()))
		//	.getKey();
		return classConfidences.max { entry1, entry2 in
			return entry1.value - entry2.value < 0
		}!.key
	}
	
	func incrementClassConfidence(className: String) {
		classConfidences[className] = classConfidences[className] != nil ? classConfidences[className]! + 1 : 1
	}
	
	func putClassConfidence(className: String, confidence: Float) {
		classConfidences[className] = confidence
	}
}
