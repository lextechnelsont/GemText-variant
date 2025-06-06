import SwiftUI

struct ContentView: View {
    @State private var text: String = ""
    @State private var selectedURL: URL?
    @State private var showPicker: Bool = false
    @State private var showCreationError: Bool = false
    @State private var isEditing: Bool = false
    @State private var showHelp: Bool = false
    @Environment(\.scenePhase) private var scenePhase
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
        VStack(alignment: .center) {
            HStack {
                if !isEditing {
                    Button(action: { showPicker = true }) {
                        Image(systemName: "folder")
                            .tint(.accentColor)
                    }
                }
                if isEditing {
                    Button(action: { withAnimation { showHelp.toggle() } }) {
                            Image(systemName: "questionmark.square")
                                .tint(.accentColor)
                        }
                }
                if let url = selectedURL {
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity)
                }
                Toggle(isOn: $isEditing) {
                    Image(systemName: "pencil")
                          .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .disabled(selectedURL == nil)
            }
            .padding()

            if isEditing {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        TextEditor(text: $text)
                            .contentMargins(16)
                            .frame(width: showHelp ? geo.size.width * 2/3 : geo.size.width)
                            .cornerRadius(12)
                        if showHelp {
                            ScrollView {
                                Text(helpText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading)
                                    .font(.caption)
                                    .monospaced()
                            }
                            .frame(width: geo.size.width * 1/3)
                            .padding(.trailing)
                            .transition(.move(edge: .trailing))
                        }
                    }
                    .animation(.default, value: showHelp)
                }
            } else if text == "" && isEditing == false {
                VStack(alignment: .center) {
                    Spacer()
                    Image("Image Asset")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 320)
                    Text("A minimalist markdown and plain text editor")
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    Button("Open .txt or .md File") {
                        showPicker = true
                    }
                    .foregroundStyle(.black)
                    .buttonStyle(.borderedProminent)
                    Spacer()
                } .frame(width: .infinity, height: .infinity)
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
                /*
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor, lineWidth: 2)
                ) */
                .padding()
                 
            }
        }
        .padding()
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && isEditing {
                saveText()
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
