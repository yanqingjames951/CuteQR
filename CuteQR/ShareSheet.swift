import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    let callback: UIActivityViewController.CompletionWithItemsHandler?
    
    init(
        items: [Any],
        excludedActivityTypes: [UIActivity.ActivityType]? = nil,
        callback: UIActivityViewController.CompletionWithItemsHandler? = nil
    ) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
        self.callback = callback
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
