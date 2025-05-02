import SwiftUI

@MainActor
final class CopiedMessageManager: ObservableObject {
    @Published var showCopiedMessage = false
    private var timer: Timer?
    
    func showMessage() {
        showCopiedMessage = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.showCopiedMessage = false
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
