import UIKit

// MARK: - CGPoint Extensions
extension CGPoint {
  /// Calculates the Euclidean distance between two points
  /// - Parameter to: The target point to calculate distance to
  /// - Returns: The distance between the points
  func distance(to point: CGPoint) -> CGFloat {
    sqrt(distanceSquared(to: point))
  }
  
  /// Calculates the squared distance between two points (more performant when exact distance isn't needed)
  /// - Parameter to: The target point to calculate squared distance to
  /// - Returns: The squared distance between the points
  func distanceSquared(to point: CGPoint) -> CGFloat {
    let deltaX = x - point.x
    let deltaY = y - point.y
    
    return deltaX * deltaX + deltaY * deltaY
  }
}

// MARK: - Vision Coordinate Conversion
/// Converts a point from Vision coordinate space (normalized 0-1) to screen coordinate space
/// - Parameters:
///   - point: The point in Vision coordinate space (normalized 0-1)
///   - frameSize: The size of the frame to scale to
/// - Returns: The converted point in screen coordinate space
func convertPointFromVision(point: CGPoint, frameSize: CGSize) -> CGPoint {
  // Vision coordinates are normalized (0-1) with origin at bottom-left
  // UIKit coordinates have origin at top-left, so we need to flip Y
  let normalizedPoint = CGPoint(x: point.x, y: 1 - point.y)
  
  return CGPoint(
    x: normalizedPoint.x * frameSize.width,
    y: normalizedPoint.y * frameSize.height
  )
}
