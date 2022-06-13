//
//  CHECKED
//  PoseSample.swift
//  Dopamining
//
//  Created by Louis Stanko on 07.06.22.
//

import Foundation
import MLKit

/// Deads Pose samples from a csv file.
class PoseSample {
	
	private static var TAG: String = "PoseSample"
	private static var NUM_LANDMARKS: Int = 33
	private static var NUM_DIMS: Int = 3 // x,y,z
	
	private final var name: String
	private final var className: String
	private final var embedding: [PointF3D]
	
	init(name: String, className: String, landmarks: [PointF3D]) {
		self.name = name
		self.className = className
		self.embedding = PoseEmbedding.getPoseEmbedding(landmarks: landmarks)
	}
	
	func getName() -> String {
		name
	}
	
	func getClassName() -> String {
		className
	}
	
	func getEmbedding() -> [PointF3D] {
		embedding
	}
	
	/// Creates a PoseSample from a CSV File line
	/// - Parameters:
	///   - csvLine: The line wich should be parsed
	///   - seperator: The CHARACTER which is split by! Only the first character is used!
	/// - Returns: The newly created pose sample
	static func getPoseSample(_ csvLine: String, seperator: String) -> PoseSample? {
		let tokens: [String] = csvLine.split(separator: ",", maxSplits: 10000000, omittingEmptySubsequences: true).map(String.init)
		// Format is expected to be Name,Class,X1,Y1,Z1,X2,Y2,Z2...
		// + 2 is for Name & Class.
		if tokens.count != (NUM_LANDMARKS * NUM_DIMS) + 2 {
			print(TAG, "Invalid number of tokens for PoseSample")
			return nil
		}
		
		let name: String = tokens[0]
		let className: String = tokens[1]
		var landmarks: [PointF3D] = []
		// Read from the third token, first 2 tokens are name and class.
		for i in stride(from: 2, to: tokens.count, by: NUM_DIMS) {
			
			// TODO: Do error handling here properly
			// FUCK SWIFT ERROR HANDLING => HOW CAN THEY EVEN FUCK THIS UP?
			// print(TAG, "Invalid value " + tokens[i] + " for landmark position.")
			landmarks.append(PointF3D(x: Float(tokens[i])!,
											  y: Float(tokens[i + 1])!,
											  z: Float(tokens[i + 2])!))
		}
		return PoseSample(name: name, className: className, landmarks: landmarks)
	}
}
