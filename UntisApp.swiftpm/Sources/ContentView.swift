import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = UntisViewModel()

    var body: some View {
        if viewModel.isLoggedIn {
            TimetableView(viewModel: viewModel)
        } else {
            LoginView(viewModel: viewModel)
        }
    }
}
