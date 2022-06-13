//
//  MLKitHelper.swift
//  Dopamining
//
//  Created by Louis Stanko on 07.06.22.
//

import Foundation
import MLKit

/// Utility methods for operations on {@link PointF3D}.
class MLKitUtils {
	
	static func subtract(_ b: PointF3D, _ a: PointF3D) -> PointF3D {
		return PointF3D(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)
	}
	
	static func multiply(_ a: PointF3D, _ multiple: Float) -> PointF3D {
		return PointF3D(x: a.x * multiple, y: a.y * multiple, z: a.z * multiple)
	}
	
	static func multiply(_ a: PointF3D, _ multiple: PointF3D) -> PointF3D {
		return PointF3D(x: a.x * multiple.x, y: a.y * multiple.y, z: a.z * multiple.z)
	}
	
	static func average(_ a: PointF3D, _ b: PointF3D) -> PointF3D {
		return PointF3D(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5, z: (a.z + b.z) * 0.5)
	}
	
	static func l2Norm2D(_ point: PointF3D) -> Float {
		return hypot(point.x, point.y)
	}
	
	static func subtractAbs(_ a: PointF3D, _ b: PointF3D) -> PointF3D {
		// return PointF3D(x: abs(a.x - b.x), y: abs(a.y - b.x), z: abs(a.z - b.z))
		return subtract(a, b)
	}
	
	static func maxAbs(_ point: PointF3D) -> Float {
		return max(max(abs(point.x), abs(point.y)), abs(point.z))
	}
	
	static func sumAbs(point: PointF3D) -> Float {
		return abs(point.x) + abs(point.y) + abs(point.z)
	}
	
	// TODO: Is this the same as =>
	// public static void subtractAll(PointF3D p, List<PointF3D> pointsList) {
	//   ListIterator<PointF3D> iterator = pointsList.listIterator();
	//   while (iterator.hasNext()) {
	//	    iterator.set(subtract(p, iterator.next()));
	//   }
	// }
	static func subtractAll(_ p: PointF3D, _ pointsList: [PointF3D]) -> [PointF3D] {
		var subtractedPointsList: [PointF3D] = []
		for index in pointsList.indices {
			subtractedPointsList.append(Self.subtract(p, pointsList[index]))
		}
		
		return subtractedPointsList
	}
	
	static func multiplyAll(pointsList: [PointF3D], multiple: Float) -> [PointF3D] {
		var multipliedPointsList: [PointF3D] = []
		for index in pointsList.indices {
			multipliedPointsList.append(Self.multiply(pointsList[index], multiple))
		}
		
		return multipliedPointsList
	}
	
	static func multiplyAll(pointsList: [PointF3D], multiple: PointF3D) -> [PointF3D] {
		var multipliedPointsList: [PointF3D] = []
		for index in pointsList.indices {
			multipliedPointsList.append(Self.multiply(pointsList[index], multiple))
		}
		
		return multipliedPointsList
	}
}

class PointF3D: CustomStringConvertible {
	
	var x: Float
	var y: Float
	var z: Float
	
	init(x: Float, y: Float, z: Float) {
		self.x = x
		self.y = y
		self.z = z
	}
	
	init(_ point: Vision3DPoint) {
		x = Float(point.x)
		y = Float(point.y)
		z = Float(point.z)
	}
	
	var description: String {
		return "[x: \(x), y: \(y), z: \(z)]"
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
