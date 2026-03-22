import SwiftUI

@Observable
final class AppState {
    var items: [ClipboardItem] = []
    var searchText: String = ""
    var maxHistoryCount: Int = 500
    var recordImages: Bool = true
}
