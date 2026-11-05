import SwiftUI
import WidgetKit

@main
struct StarterSurfacesBundle: WidgetBundle {
  var body: some Widget {
    SurfaceWidget()
    if #available(iOS 16.2, *) {
      SurfaceLiveActivity()
    }
  }
}
