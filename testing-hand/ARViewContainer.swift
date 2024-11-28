import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
  @EnvironmentObject var sessionHandler: SessionHandler
  
  func makeUIView(context: Context) -> ARView {
    let arView = ARView(frame: .zero)
    arView.renderOptions = [.disableMotionBlur,
                            .disableDepthOfField,
                            .disablePersonOcclusion,
                            .disableGroundingShadows,
                            .disableFaceMesh,
                            .disableHDR,
                            .disableCameraGrain
    ]
    
    arView.debugOptions = [.showFeaturePoints, .showStatistics]
    
    // Capture the default value after initialize the view.
    let defaultScaleFactor = arView.contentScaleFactor
    // Scale factor is to 50% of the default value to reduce rendering resolution.
    arView.contentScaleFactor = 0.5 * defaultScaleFactor
    
    let config = ARWorldTrackingConfiguration()
    config.isLightEstimationEnabled = true
    arView.session.run(config)
    arView.session.delegate = sessionHandler
    
    sessionHandler.createCircleForThumb(view: arView)
    sessionHandler.arView = arView
    
    return arView
  }
  
  func updateUIView(_ uiView: ARView, context: Context) {}
}

// https://developer.apple.com/documentation/arkit/arkit_in_ios/content_anchors/recognizing_and_labeling_arbitrary_objects
// https://stackoverflow.com/questions/44976459/vision-framework-with-arkit-and-coreml
