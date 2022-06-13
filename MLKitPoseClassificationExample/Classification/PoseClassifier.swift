//
//  CHECKED - But unsure!
//  PoseClassifier.swift
//  Dopamining
//
//  Created by Louis Stanko on 07.06.22.
//

import Foundation
import MLKit

func maxSort(_ a: Pair<PoseSample,Float>, _ b: Pair<PoseSample,Float>) -> Bool {
	return a.second > b.second
}

class PoseClassifier {
	private static let TAG: String = "PoseClassifier"
	private static let MAX_DISTANCE_TOP_K: Int = 30 // 30
	private static let MEAN_DISTANCE_TOP_K: Int = 10 // 10
	// Note Z has a lower weight as it is generally less accurate than X & Y.
	private static let AXES_WEIGHTS: PointF3D = PointF3D(x: 1, y: 1, z: 0.2)
	
	private final var poseSamples: [PoseSample]
	private final var maxDistanceTopK: Int
	private final var meanDistanceTopK: Int
	private final var axesWeights: PointF3D
	
	convenience init(_ poseSamples: [PoseSample]) {
		self.init(poseSamples, Self.MAX_DISTANCE_TOP_K, Self.MEAN_DISTANCE_TOP_K, Self.AXES_WEIGHTS)
	}
	
	init(_ poseSamples: [PoseSample], _ maxDistanceTopK: Int, _ meanDistanceTopK: Int, _ axesWeights: PointF3D) {
		self.poseSamples = poseSamples
		self.maxDistanceTopK = maxDistanceTopK
		self.meanDistanceTopK = meanDistanceTopK
		self.axesWeights = axesWeights
	}
	
	private static func extractPoseLandmarks(pose: Pose) -> [PointF3D] {
		let landmarksRaw: [PoseLandmark] = [pose.landmark(ofType: .nose), pose.landmark(ofType: .leftEyeInner), pose.landmark(ofType: .leftEye), pose.landmark(ofType: .leftEyeOuter), pose.landmark(ofType: .rightEyeInner), pose.landmark(ofType: .rightEye), pose.landmark(ofType: .rightEyeOuter), pose.landmark(ofType: .leftEar), pose.landmark(ofType: .rightEar), pose.landmark(ofType: .mouthLeft), pose.landmark(ofType: .mouthRight), pose.landmark(ofType: .leftShoulder), pose.landmark(ofType: .rightShoulder), pose.landmark(ofType: .leftElbow), pose.landmark(ofType: .rightElbow), pose.landmark(ofType: .leftWrist), pose.landmark(ofType: .rightWrist), pose.landmark(ofType: .leftPinkyFinger), pose.landmark(ofType: .rightPinkyFinger), pose.landmark(ofType: .leftIndexFinger), pose.landmark(ofType: .rightIndexFinger), pose.landmark(ofType: .leftThumb), pose.landmark(ofType: .rightThumb), pose.landmark(ofType: .leftHip), pose.landmark(ofType: .rightHip), pose.landmark(ofType: .leftKnee), pose.landmark(ofType: .rightKnee), pose.landmark(ofType: .leftAnkle), pose.landmark(ofType: .rightAnkle), pose.landmark(ofType: .leftHeel), pose.landmark(ofType: .rightHeel), pose.landmark(ofType: .leftToe), pose.landmark(ofType: .rightToe)]
		var landmarks: [PointF3D] = []
		for poseLandmark in landmarksRaw {
			landmarks.append(PointF3D(poseLandmark.position))
		}
		return landmarks
	}

	/// Returns the max range of confidence values.
	///
	/// Since we calculate confidence by counting {@link PoseSample}s that survived
	/// outlier-filtering by maxDistanceTopK and meanDistanceTopK, this range is the minimum of two.
	func confidenceRange() -> Int {
		return min(maxDistanceTopK, meanDistanceTopK)
	}
	
	func classify(pose: Pose) -> ClassificationResult {
		return classify(landmarks: Self.extractPoseLandmarks(pose: pose))
	}
	
	func classify(landmarks: [PointF3D]) -> ClassificationResult {
		let result: ClassificationResult = ClassificationResult()
		
		// Return early if no landmarks detected.
		if landmarks.isEmpty {
			return result
		}
		
		// We do flipping on X-axis so we are horizontal (mirror) invariant.
		var flippedLandmarks: [PointF3D] = landmarks
		flippedLandmarks = MLKitUtils.multiplyAll(pointsList: flippedLandmarks, multiple: PointF3D(x: -1, y: 1, z: 1))
		
		let embedding: [PointF3D] = PoseEmbedding.getPoseEmbedding(landmarks: landmarks)
		let flippedEmbedding: [PointF3D] = PoseEmbedding.getPoseEmbedding(landmarks: flippedLandmarks)
		
		// Classification is done in two stages:
		//  * First we pick top-K samples by MAX distance. It allows to remove samples that are almost
		//    the same as given pose, but maybe has few joints bent in the other direction.
		//  * Then we pick top-K samples by MEAN distance. After outliers are removed, we pick samples
		//    that are closest by average.
		
		// Keeps max distance on top so we can pop it when top_k size is reached.
		var maxDistances: PriorityQueue<Pair<PoseSample, Float>> = PriorityQueue(sort: maxSort)
		
		for poseSample in poseSamples {
			let sampleEmbedding: [PointF3D] = poseSample.getEmbedding()
			
			var originalMax: Float = 0.0
			var flippedMax: Float = 0.0
			for i in 0..<embedding.count {
				originalMax = max(
					originalMax, MLKitUtils.maxAbs(MLKitUtils.multiply(MLKitUtils.subtract(embedding[i], sampleEmbedding[i]), axesWeights)))
				flippedMax = max(flippedMax, MLKitUtils.maxAbs(MLKitUtils.multiply(MLKitUtils.subtract(flippedEmbedding[i], sampleEmbedding[i]), axesWeights)))
			}
			// Set the max distance as min of original and flipped max distance.
			maxDistances.enqueue(Pair(poseSample, min(originalMax, flippedMax)))
			// We only want to retain top n so pop the highest distance.
			if maxDistances.count > maxDistanceTopK {
				_ = maxDistances.dequeue()
			}
		}
		
		// Keeps higher mean distances on top so we can pop it when top_k size is reached.
		var meanDistances: PriorityQueue<Pair<PoseSample, Float>> = PriorityQueue(sort: maxSort)
		// Retrive top K poseSamples by **least** mean distance to remove outliers.
		for sampleDistances in maxDistances.heap.nodes {
			let poseSample: PoseSample = sampleDistances.first
			let sampleEmbedding: [PointF3D] = poseSample.getEmbedding()
			
			var originalSum: Float = 0.0
			var flippedSum: Float = 0.0
			
			for i in 0..<embedding.count {
				originalSum += MLKitUtils.sumAbs(point: MLKitUtils.multiply(MLKitUtils.subtract(embedding[i], sampleEmbedding[i]), axesWeights))
				flippedSum += MLKitUtils.sumAbs(point: MLKitUtils.multiply(MLKitUtils.subtract(flippedEmbedding[i], sampleEmbedding[i]), axesWeights))
			}
			// Set the mean distance as min of original and flipped mean distances.
			let meanDistance: Float = min(originalSum, flippedSum) / (Float(embedding.count) * 2.0)
			meanDistances.enqueue(Pair(poseSample, meanDistance))
			// We only want to retain top k so pop the highest mean distance.
			if meanDistances.count > meanDistanceTopK {
				_ = meanDistances.dequeue()
			}
		}
		
		
		for sampleDistances in meanDistances.heap.nodes {
			let className: String = sampleDistances.first.getClassName()
			result.incrementClassConfidence(className: className)
		}
		return result
	}
}

class Pair<T, K> {
	var first: T
	var second: K
    var description : String
	init (_ a: T, _ b: K) {
		first = a
		second = b
        description = "\(a) \(b)"
	}
}
