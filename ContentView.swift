import SwiftUI

struct ContentView: View {
    @State private var text: String = ""
    @State private var selectedURL: URL?
    @State private var showPicker: Bool = false
    @State private var showCreationError: Bool = false
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

                Button(action: { showPicker = true }) {
                    Image(systemName: "folder.open")
                }
                Spacer()
                if isEditing {
                    Button("Help") {
                        withAnimation {
                            showHelp.toggle()
                        }
                    }
                }
                Toggle(isOn: $isEditing) {
                    Image(systemName: "pencil")
                }
                .disabled(selectedURL == nil)
                .padding(.leading, 8)
            }
            .padding()

            if isEditing {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        TextEditor(text: $text)
                            .frame(width: showHelp ? geo.size.width * 2/3 : geo.size.width)
                            .border(Color.gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.yellow, lineWidth: 1)
                            )
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
                    /* if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) { */
                    if let attributed = try? AttributedString(styledMarkdown: text) {
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
        .padding()
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $showPicker) {
            FilePicker { url in
                selectedURL = url
                loadText(from: url)
                showPicker = false
            }
        }
        .alert("Failed to create file", isPresented: $showCreationError) {
            Button("OK", role: .cancel) {}
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

    private func createNewFile() {
        let fm = FileManager.default
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let fileName = "GemText \(dateFormatter.string(from: Date())).md"

        var directory: URL
        if let icloudURL = fm.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/GemText", isDirectory: true) {
            directory = icloudURL
        } else if let localURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("GemText", isDirectory: true) {
            directory = localURL
        } else {
            showCreationError = true
            return
        }

        do {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent(fileName)
            if !fm.fileExists(atPath: fileURL.path) {
                fm.createFile(atPath: fileURL.path, contents: Data())
            }
            selectedURL = fileURL
            loadText(from: fileURL)
            isEditing = true
        } catch {
            showCreationError = true
        }
    }

    private func saveText() {
        guard let url = selectedURL else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}
