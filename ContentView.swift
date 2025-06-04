import SwiftUI

struct ContentView: View {
    @State private var text: String = ""
    @State private var selectedURL: URL?
    @State private var showPicker: Bool = false
    @State private var isEditing: Bool = false
    @State private var showHelp: Bool = false
    private let helpText: String

    init() {
        if let url = Bundle.main.url(forResource: "markdown-examples", withExtension: "txt"),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            self.helpText = contents
        } else {
            self.helpText = ""
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button("Open File") {
                    showPicker = true
                }
                HStack {
                    Toggle("", isOn: $isEditing)
                        .disabled(selectedURL == nil)
                }
                if isEditing {
                    Button("Help") {
                        withAnimation {
                            showHelp.toggle()
                        }
                    }
                }
                /*
                Button("Save") {
                    saveText()
                }
                .disabled(selectedURL == nil)
                */
            }
            .padding()

            if isEditing {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        TextEditor(text: $text)
                            .frame(width: showHelp ? geo.size.width * 2/3 : geo.size.width)
                            .border(Color.gray)
                        if showHelp {
                            ScrollView {
                                Text(helpText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                            .frame(width: geo.size.width * 1/3)
                            .border(Color.gray)
                            .transition(.move(edge: .trailing))
                        }
                    }
                    .animation(.default, value: showHelp)
                }
                .padding()
            } else {
                ScrollView {
                    // From Marco Eidinger blog
                    if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                        Text(attributed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    } else {
                        Text(text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
                .border(Color.gray)
                .padding()
            }
        }
        .sheet(isPresented: $showPicker) {
            FilePicker { url in
                selectedURL = url
                loadText(from: url)
                showPicker = false
            }
        }
        .onChange(of: isEditing) { _, editing in
            if editing == false {
                saveText()
                if let url = selectedURL {
                    loadText(from: url)
                }
            }
        }
    }

    private func loadText(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        if let data = try? Data(contentsOf: url),
           let str = String(data: data, encoding: .utf8) {
            text = str
        }
    }

    private func saveText() {
        guard let url = selectedURL else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}
