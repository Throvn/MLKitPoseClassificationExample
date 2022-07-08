//
//  CHECKED
//  PoseEmbedding.swift
//  Dopamining
//
//  Created by Louis Stanko on 07.06.22.
//

import Foundation
import MLKit
import simd

/// Generates embedding for given list of Pose landmarks.
class PoseEmbedding {
	// Multiplier to apply to the torso to get minimal body size. Picked this by experimentation.
	private static let TORSO_MULTIPLIER: Float = 2.5
	
	static func getPoseEmbedding(landmarks: [simd_float3]) -> [simd_float3] {
		let normalizedLandmarks: [simd_float3] = normalize(landmarks)
		
		return getEmbedding(normalizedLandmarks)
	}
	
	private static func normalize(_ landmarks: [simd_float3]) -> [simd_float3] {
		var normalizedLandmarks: [simd_float3] = landmarks
		
		// Normalize translation.
		let center: simd_float3 = MLKitUtils.average(landmarks[PoseLmType.leftHip.rawValue], landmarks[PoseLmType.rightHip.rawValue])
		normalizedLandmarks = MLKitUtils.subtractAll(center, normalizedLandmarks)
		
		// Normalize scale
		normalizedLandmarks = MLKitUtils.multiplyAll(pointsList: normalizedLandmarks, multiple: 1 / getPoseSize(normalizedLandmarks))
		
		// Multiplication by 100 is not required, but makes it easier to debug.
		normalizedLandmarks = MLKitUtils.multiplyAll(pointsList: normalizedLandmarks, multiple: 100);
		// print(normalizedLandmarks)
		return normalizedLandmarks
	}
	
	// Translation normalization should've been done prior to calling this method.
	private static func getPoseSize(_ landmarks: [simd_float3]) -> Float {
		// Note: This approach uses only 2D landmarks to compute pose size as using Z wasn't helpful
		// in our experimentation but you're welcome to tweak.
		let hipsCenter: simd_float3 = MLKitUtils.average(landmarks[PoseLmType.leftHip.rawValue], landmarks[PoseLmType.rightHip.rawValue])
		
		let shouldersCenter = MLKitUtils.average(landmarks[PoseLmType.leftShoulder.rawValue], landmarks[PoseLmType.rightShoulder.rawValue])
		
		let torsoSize: Float = MLKitUtils.l2Norm2D(MLKitUtils.subtract(hipsCenter, shouldersCenter))
		
		var maxDistance: Float = torsoSize * TORSO_MULTIPLIER
		
		// torsoSize * TORSO_MULTIPLIER is the floor we want based on experimentation but actual size
		// can be bigger for a given pose depending on extension of limbs etc so we calculate that.
		for landmark in landmarks {
			let distance: Float = MLKitUtils.l2Norm2D(MLKitUtils.subtract(hipsCenter, landmark))
			if distance > maxDistance {
				maxDistance = distance
			}
		}
		return maxDistance
	}
	
	private static func getEmbedding(_ lm: [simd_float3]) -> [simd_float3] {
		var embedding: [simd_float3] = []
		
		// We use several pairwise 3D distances to form pose embedding. These were selected
		// based on experimentation for best results with our default pose classes as captured in the
		// pose samples csv. Feel free to play with this and add or remove for your use-cases.
		
		// We group our distances by number of joints between the pairs.
		// One joint.
		embedding.append(MLKitUtils.subtractAbs(
			MLKitUtils.average(lm[PoseLmType.leftHip.rawValue], lm[PoseLmType.rightHip.rawValue]),
			MLKitUtils.average(lm[PoseLmType.leftShoulder.rawValue], lm[PoseLmType.rightShoulder.rawValue])
		))
		
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftShoulder.rawValue], lm[PoseLmType.leftElbow.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.rightShoulder.rawValue], lm[PoseLmType.rightElbow.rawValue]))
		
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftElbow.rawValue], lm[PoseLmType.leftWrist.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.rightElbow.rawValue], lm[PoseLmType.rightWrist.rawValue]))
		
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftHip.rawValue], lm[PoseLmType.leftKnee.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.rightHip.rawValue], lm[PoseLmType.rightKnee.rawValue]))
		
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftKnee.rawValue], lm[PoseLmType.leftAnkle.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.rightKnee.rawValue], lm[PoseLmType.rightAnkle.rawValue]))
		
		// Two joints.
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftShoulder.rawValue], lm[PoseLmType.leftWrist.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.rightShoulder.rawValue], lm[PoseLmType.rightWrist.rawValue]))
		
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftHip.rawValue], lm[PoseLmType.leftAnkle.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.rightHip.rawValue], lm[PoseLmType.rightAnkle.rawValue]))
		
		// Four joints.
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftHip.rawValue], lm[PoseLmType.leftWrist.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.rightHip.rawValue], lm[PoseLmType.rightWrist.rawValue]))
		
		// Five joints.
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftShoulder.rawValue], lm[PoseLmType.leftAnkle.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.rightShoulder.rawValue], lm[PoseLmType.rightAnkle.rawValue]))
		
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftHip.rawValue], lm[PoseLmType.leftWrist.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.rightHip.rawValue], lm[PoseLmType.rightWrist.rawValue]))
		
		// Cross body.
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftElbow.rawValue], lm[PoseLmType.rightElbow.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftKnee.rawValue], lm[PoseLmType.rightKnee.rawValue]))
		
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftWrist.rawValue], lm[PoseLmType.rightWrist.rawValue]))
		embedding.append(MLKitUtils.subtractAbs(
			lm[PoseLmType.leftAnkle.rawValue], lm[PoseLmType.rightAnkle.rawValue]))
		return embedding
	}
	
	private init() {}
}
