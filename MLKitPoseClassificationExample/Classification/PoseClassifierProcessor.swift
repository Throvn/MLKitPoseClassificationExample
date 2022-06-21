//
//  CHECKED
//  PoseClassifierProcessor.swift
//  Dopamining
//
//  Created by Louis Stanko on 07.06.22.
//

import Foundation
import MLKit

class PoseClassifierProcessor {
	private let TAG = "PoseClassifierProcessor"
	private static let POSE_SAMPLES_FILE: String = "fitness_pose_samples"
	private static let POSE_SAMPLES_FILE_EXT: String = "csv"
	
	// Specify classes for which we want rep counting.
	// These are the labels in the given {@code POSE_SAMPLES_FILE}. You can set your own class labels
	// for your pose samples.
	private static let SQUAT_CLASS: String = "squats_down"
	private static let POSE_CLASSES: [String] = [
		SQUAT_CLASS
	]
	
	private final var isStreamMode: Bool
	
	private var emaSmoothing: EMASmoothing?
	private var repCounters: [RepetitionCounter] = []
	private var poseClassifier: PoseClassifier?
	private var lastRepResult: String = ""
	
	// @WorkerThread
	init(isStreamMode: Bool) {
		self.isStreamMode = isStreamMode
		if isStreamMode {
			emaSmoothing = EMASmoothing()
		}
		loadPoseSamples()
	}
	
	private func loadPoseSamples() {
		var poseSamples: [PoseSample] = []
		
		// TODO: Check if this is working correctly later
		// TODO: Replace hardcoded values with static variables later
		var text: String
		do {
			if let path = Bundle.main.path(forResource: Self.POSE_SAMPLES_FILE, ofType: Self.POSE_SAMPLES_FILE_EXT) {
				text = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
			} else {
				print(TAG, "Could not find file.")
				return
			}
		} catch {
			print(TAG, "Error when loading pose samples.")
			return
		}
		
		let lines: [String] = text
			.split(separator: "\n", omittingEmptySubsequences: true)
			.map(String.init)
		
		for csvLine in lines {
			// If line is not a valid {@link PoseSample}, we'll get null and skip adding to the list.
			let poseSample: PoseSample? = PoseSample.getPoseSample(csvLine, seperator: ",")
			if let poseSample = poseSample {
				poseSamples.append(poseSample)
			}
		}
		print(poseSamples.count)
		poseClassifier = PoseClassifier(poseSamples)
		
		if isStreamMode {
			for className in Self.POSE_CLASSES {
				repCounters.append(RepetitionCounter(className: className))
			}
		}
	}
	
	/**
	 * Given a new {@link Pose} input, returns a list of formatted {@link String}s with Pose
	 * classification results.
	 *
	 * <p>Currently it returns up to 2 strings as following:
	 * 0: PoseClass : X reps
	 * 1: PoseClass : [0.0-1.0] confidence
	 */
	// @WorkerThread
	func getPoseResult(pose: Pose) -> [String] {
		var result: [String] = []
		var classification: ClassificationResult = poseClassifier!.classify(pose: pose)
		
		// Update {@link RepetitionCounter}s if {@code isStreamMode}.
		if isStreamMode {
			// Feed pose to smoothing even if no pose found.
			classification = emaSmoothing!.getSmoothedResult(classificationResult: classification)
			
			// Return early without updating repCounter if no pose found.
			if pose.landmarks.isEmpty {
				result.append(lastRepResult)
                print("empty landmarks 1")
				return result
			}
			
			for repCounter in repCounters {
				let repsBefore: Int = repCounter.getNumRepeates()
				let repsAfter: Int = repCounter.addClassificationResult(classificationResult: classification)
				if repsAfter > repsBefore {
					// Update the UI Here if a rep was counted!
					print(repCounter.getClassName(), "]]] Rep was counted: \(repsAfter)")
					lastRepResult = "\(repCounter.getClassName()) : \(repsAfter) reps"
					break
				}
			}
			result.append(lastRepResult)
		}
		
		// Add maxConfidence class of current frame to result if pose if found.
		if !pose.landmarks.isEmpty {
			let maxConfidenceClass: String = classification.getMaxConfidenceClass()
			let maxConfidenceClassResult: String = "\(maxConfidenceClass) : \(classification.getClassConfidence(className: maxConfidenceClass) / Float(poseClassifier!.confidenceRange())) confidence"
			result.append(maxConfidenceClassResult)
		}
        else{
            print("empty landmarks 2")
        }
		
		return result
	}
}
