import RealityKit
import ARKit
import Vision

final class SessionHandler: NSObject, ObservableObject, ARSessionDelegate {
  weak var arView: ARView?
  private var boxEntity: ModelEntity?
  // The pixel buffer being held for analysis; used to serialize Vision requests.
  private var currentBuffer: CVPixelBuffer?
  private var ringPipView: UIView!
  
  private lazy var handPoseRequest: VNDetectHumanHandPoseRequest = {
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 1
    return request
  }()
  
  func createCircleForThumb(view: UIView) {
    ringPipView = createFingerView(in: view)
  }
  
  
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    // Do not enqueue other buffers for processing while another Vision task is still running.
    // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
    guard currentBuffer == nil, case .normal = frame.camera.trackingState else { return }
    
    // Retain the image buffer for Vision processing.
    self.currentBuffer = frame.capturedImage
    classifyFinger()
  }
  
  func classifyFinger() {
    guard let currentBuffer = currentBuffer else {
      fatalError("There no buffer available")
    }
    
    let handler = VNImageRequestHandler(
      cvPixelBuffer: currentBuffer,
      orientation: .right,
      options: [:]
    )
    
    DispatchQueue.global().async { [weak self] in
      do {
        try self?.performRequest(handler: handler)
      } catch {
        print("Error performing hand pose detection: \(error)")
      }
    }
  }
  
  
  private func performRequest(handler: VNImageRequestHandler) throws {
    // Release the pixel buffer when done, allowing the next buffer to be processed.
    defer { self.currentBuffer = nil }
    
    try handler.perform([handPoseRequest])
    
    if let observation = handPoseRequest.results?.first as? VNHumanHandPoseObservation {
      let jointPoints = try observation.recognizedPoints(.all)
      DispatchQueue.main.async { [weak self] in
        self?.updateFingerTipPositions(jointPoints)
      }
    } else {
      print("\(Date.now): No hands")
      ringPipView.isHidden = true
    }
  }
  
  private func updateFingerTipPositions(
    _ jointPoints: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]
  ) {
    if let jointPoint = jointPoints[.ringPIP] {
      
      obtainJointPointAndUpdatePosition(jointPoint, layer: ringPipView)
      
      guard let arView else { return }
      
      if boxEntity == nil {
        attachMeshToScene(in: arView)
      } else {
        updateBoxPosition(jointPoint)
      }
    }
  }
  
  private func obtainJointPointAndUpdatePosition(_ jointPoint: VNRecognizedPoint, layer: UIView) {
    let screenFingerTipPoint = convertPointFromVision(point: jointPoint.location, frameSize: UIScreen.main.bounds.size)
    layer.frame.origin = screenFingerTipPoint
    layer.isHidden = false
  }
  
  private func createFingerView(in view: UIView) -> UIView {
    let finger = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
    
    finger.backgroundColor = .green
    finger.layer.cornerRadius = 10
    finger.isHidden = true
    view.addSubview(finger)
    
    return finger
  }
  
  func attachMeshToScene(in arView: ARView) {
    // Create an anchor entity at the raycasted position
    let anchorEntity = AnchorEntity()
    
    // Create the box entity
    let boxMesh = MeshResource.generateBox(size: 0.02, cornerRadius: 0.005)
    let boxMaterial = SimpleMaterial(color: .red, roughness: 0.15, isMetallic: false)
    self.boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
    self.boxEntity?.name = "Box"
    
    // Add the box entity to the anchor
    if let boxEntity = boxEntity {
      anchorEntity.addChild(boxEntity)
    }
    
    // Add the anchor to the scene
    arView.scene.addAnchor(anchorEntity)
  }
  
  func updateBoxPosition(_ visionPoint: VNRecognizedPoint) {
    guard let arView = arView, let boxEntity = boxEntity else { return }
    
    // Convert the Vision point to screen space
    let screenPoint = convertPointFromVision(
      point: CGPoint(x: visionPoint.x, y: visionPoint.y),
      frameSize: arView.frame.size
    )
    
    // Perform raycast to find the world position
    let raycastResults = arView.raycast(from: screenPoint, allowing: .estimatedPlane, alignment: .any)
    
    
    // Check if we have a valid raycast result
    guard let result = raycastResults.first else {
      print("No raycast result")
      return
    }
    // Get the world position from the raycast result
    
    let worldTransform = result.worldTransform.columns.3
    let position : SIMD3<Float> = simd_make_float3(worldTransform.x, worldTransform.y, worldTransform.z)
    
    // Update the model position (for example, if you have a model entity named `boxEntity`)
    DispatchQueue.main.async {
      boxEntity.position = position
    }
  }
}

