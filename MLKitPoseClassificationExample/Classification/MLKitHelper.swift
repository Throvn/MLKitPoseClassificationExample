//
//  MLKitHelper.swift
//  Dopamining
//
//  Created by Louis Stanko on 07.06.22.
//

import Foundation
import MLKit
import simd

/// Utility methods for operations on {@link simd_float3}.
class MLKitUtils {
	
	static func subtract(_ b: simd_float3, _ a: simd_float3) -> simd_float3 {
		return a - b
	}
	
	static func multiply(_ a: simd_float3, _ multiple: Float) -> simd_float3 {
		return a * multiple
	}
	
	static func multiply(_ a: simd_float3, _ multiple: simd_float3) -> simd_float3 {
		return a * multiple
	}
	
	static func average(_ a: simd_float3, _ b: simd_float3) -> simd_float3 {
		return (a * b) / 0.5
	}
	
	static func l2Norm2D(_ point: simd_float3) -> Float {
		return hypot(point.x, point.y)
	}
	
	// TODO: This is not really abs!!!!
	static func subtractAbs(_ a: simd_float3, _ b: simd_float3) -> simd_float3 {
		// return simd_float3(x: abs(a.x - b.x), y: abs(a.y - b.x), z: abs(a.z - b.z))
		return a - b
	}
	
	static func maxAbs(_ point: simd_float3) -> Float {
		return max(max(abs(point.x), abs(point.y)), abs(point.z))
	}
	
	static func sumAbs(point: simd_float3) -> Float {
		return abs(point.x) + abs(point.y) + abs(point.z)
	}
	
	// TODO: Is this the same as =>
	// public static void subtractAll(simd_float3 p, List<simd_float3> pointsList) {
	//   ListIterator<simd_float3> iterator = pointsList.listIterator();
	//   while (iterator.hasNext()) {
	//	    iterator.set(subtract(p, iterator.next()));
	//   }
	// }
	static func subtractAll(_ p: simd_float3, _ pointsList: [simd_float3]) -> [simd_float3] {
		var subtractedPointsList: [simd_float3] = []
		for index in pointsList.indices {
			subtractedPointsList.append(p - pointsList[index])
		}
		
		return subtractedPointsList
	}
	
	static func multiplyAll(pointsList: [simd_float3], multiple: Float) -> [simd_float3] {
		var multipliedPointsList: [simd_float3] = []
		for index in pointsList.indices {
			multipliedPointsList.append(pointsList[index] * multiple)
		}
		
		return multipliedPointsList
	}
	
	static func multiplyAll(pointsList: [simd_float3], multiple: simd_float3) -> [simd_float3] {
		var multipliedPointsList: [simd_float3] = []
		for index in pointsList.indices {
			multipliedPointsList.append(pointsList[index] * multiple)
		}
		
		return multipliedPointsList
	}
}

enum PoseLmType: Int {
	case nose = 0
	case leftEyeInner
	case leftEye
	case leftEyeOuter
	case rightEyeInner
	case rightEye
	case rightEyeOuter
	case leftEar
	case rightEar
	case mouthLeft
	case mouthRight
	case leftShoulder
	case rightShoulder
	case leftElbow
	case rightElbow
	case leftWrist
	case rightWrist
	case leftPinkyFinger
	case rightPinkyFinger
	case leftIndexFinger
	case rightIndexFinger
	case leftThumb
	case rightThumb
	case leftHip
	case rightHip
	case leftKnee
	case rightKnee
	case leftAnkle
	case rightAnkle
	case leftHeel
	case rightHeel
	case leftToe
	case rightToe
}
