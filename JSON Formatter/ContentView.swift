import JSONValue
import SwiftUI

struct ContentView: View {

    @State private var option: Option = .prettify
    @State private var text: String = .init()

    @FocusState private var textEditorFocused: Bool

    var body: some View {
        VStack {
            picker
            textEditor
            quit
        }
        .padding()
        .background(.background)
        .task {
            textEditorFocused = true
        }
        // https://clive819.github.io/posts/common-swiftui-pitfalls-onchange-modifier-plus-task/
        .task(id: text) {
            await format(text: text, option: option)
        }
        .task(id: option) {
            await format(text: text, option: option)
        }
    }
}

// MARK: - Subviews

fileprivate extension ContentView {

    @ViewBuilder var picker: some View {
        Picker("", selection: $option) {
            ForEach(Option.allCases) {
                Text($0.rawValue)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    @ViewBuilder var textEditor: some View {
        VStack {
            TextEditor(text: $text)
                .background(.regularMaterial)
                .focused($textEditorFocused)

            Text("For a better experience, simply paste your JSON directly instead of typing it out. :)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .frame(height: 400)
    }

    @ViewBuilder var quit: some View {
        Button("Quit") {
            exit(0)
        }
    }
}

// MARK: - Helpers

fileprivate extension ContentView {

    nonisolated func format(text: String, option: Option) async {
        guard !text.isEmpty else { return }

        do {
            let json = try JSONDecoder().decode(JSONValue.self, from: .init(text.utf8))

            let encoder = JSONEncoder()
            switch option {
                case .prettify:
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                case .minify:
                    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            }
            let data = try encoder.encode(json)

            try Task.checkCancellation()

            // Only enter actor when we need to.
            // https://clive819.github.io/posts/mastering-swift-concurrency/#best-practices-1
            await MainActor.run {
                self.text = String(decoding: data, as: UTF8.self)
            }
        } catch is CancellationError {
            // no-op
        } catch {
            await MainActor.run {
                self.text = "Invalid JSON"
            }
        }
    }
}

// MARK: - Type Definitions

fileprivate extension ContentView {

    enum Option: String, CaseIterable, Identifiable, Hashable {
        case prettify
        case minify

        var id: Self { self }
    }
}
