import SwiftUI
import Vision
import AppKit
import CryptoKit

struct Shot: Codable, Identifiable {
    var id: String
    var name: String
    var text: String
    var topic: String
    var date: Date
}
@MainActor final class Library: ObservableObject {
    @Published var shots: [Shot] = []
    @Published var busy = false
    @Published var status = "Import screenshots to make their text searchable."
    @Published var query = ""
    @Published var topic = "All"
    let root: URL
    var filtered: [Shot] { shots.filter { (topic == "All" || $0.topic == topic) && (query.isEmpty || ($0.name+" "+$0.text).localizedCaseInsensitiveContains(query)) } }
    init() {
        root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("NetCoderMikeScreenshotLibrary", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let index = root.appendingPathComponent("index.json")
            if FileManager.default.fileExists(atPath: index.path) { shots = try JSONDecoder().decode([Shot].self, from: Data(contentsOf: index)) }
        } catch { status = "Could not load library: \(error.localizedDescription)" }
    }
    func imageURL(_ shot: Shot) -> URL { root.appendingPathComponent(shot.id+".png") }
    func save() throws { try JSONEncoder().encode(shots).write(to: root.appendingPathComponent("index.json"), options: .atomic) }
    func pick() {
        guard !busy else { return }
        let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.canChooseDirectories = false; panel.allowedContentTypes = [.png, .jpeg, .tiff]
        guard panel.runModal() == .OK else { return }
        let urls = panel.urls; busy = true
        Task {
            for url in urls {
                status = "Recognizing \(url.lastPathComponent)…"
                do {
                    let shot = try await Task.detached(priority: .userInitiated) { () throws -> (Shot, Data) in
                        let bytes = try Data(contentsOf: url)
                        guard bytes.count <= 40*1024*1024 else { throw NSError(domain: "Image exceeds 40 MiB", code: 1) }
                        let id = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
                        guard let image = NSImage(data: bytes), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil), let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else { throw NSError(domain: "Unreadable image", code: 2) }
                        let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate; request.usesLanguageCorrection = true
                        try VNImageRequestHandler(cgImage: cg).perform([request])
                        let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                        let lower = text.lowercased()
                        let topic = ["Code": ["function", "import", "class ", "const "], "Receipts": ["total", "subtotal", "receipt"], "Travel": ["flight", "boarding", "hotel"]].sorted { $0.key < $1.key }.first { $0.value.contains { lower.contains($0) } }?.key ?? "General"
                        return (Shot(id: id, name: url.lastPathComponent, text: text, topic: topic, date: Date()), png)
                    }.value
                    if !shots.contains(where: { $0.id == shot.0.id }) {
                        try shot.1.write(to: imageURL(shot.0), options: .atomic)
                        shots.insert(shot.0, at: 0)
                        do { try save() } catch { shots.removeAll { $0.id == shot.0.id }; throw error }
                    }
                } catch { status = "Import failed: \(error.localizedDescription)"; busy = false; return }
            }
            busy = false; status = "Library contains \(shots.count) screenshots. OCR runs entirely on this Mac."
        }
    }
    func remove(_ shot: Shot) {
        let old = shots; shots.removeAll { $0.id == shot.id }
        do { try save(); try? FileManager.default.removeItem(at: imageURL(shot)) }
        catch { shots = old; status = "Delete failed: \(error.localizedDescription)" }
    }
}
struct ContentView: View {
    @StateObject private var library = Library()
    @State private var selected: Shot?
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading) {
                Text("Screenshot Library").font(.largeTitle.bold())
                Button(library.busy ? "Importing…" : "Import screenshots", action: library.pick).disabled(library.busy)
                TextField("Search recognized text", text: $library.query)
                Picker("Topic", selection: $library.topic) { ForEach(["All", "Code", "Receipts", "Travel", "General"], id: \.self) { Text($0) } }
                List(library.filtered) { shot in
                    Button { selected = shot } label: { VStack(alignment: .leading) { Text(shot.name).bold(); Text(shot.topic).font(.caption) } }.buttonStyle(.plain)
                }
                Text(library.status).font(.caption).foregroundStyle(.secondary)
            }.padding().frame(minWidth: 280)
        } detail: {
            if let shot = selected {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(shot.name).font(.title)
                        if let image = NSImage(contentsOf: library.imageURL(shot)) { Image(nsImage: image).resizable().scaledToFit().frame(maxHeight: 420) }
                        Text(shot.text.isEmpty ? "No text recognized." : shot.text).textSelection(.enabled)
                        HStack { Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([library.imageURL(shot)]) }; Button("Delete", role: .destructive) { library.remove(shot); selected = nil }.disabled(library.busy) }
                    }.padding()
                }
            } else { Text("Select a screenshot to inspect its text.").foregroundStyle(.secondary) }
        }.frame(minWidth: 950, minHeight: 650)
    }
}
@main struct ScreenshotLibraryApp: App { var body: some Scene { WindowGroup { ContentView() } } }
