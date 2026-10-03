import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var command = ""
    @State private var status = "Готов. Напишите команду или выберите действие."
    @State private var selectedFile: URL?
    @State private var csvPreview = ""
    @State private var showingFilePicker = false
    @State private var showingFolderPicker = false

    private let commonApps = ["Finder", "Safari", "Numbers", "Microsoft Excel", "1C"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: 34))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Sol — помощник для macOS").font(.title2.bold())
                    Text("Файлы • приложения • таблицы • веб-поиск").foregroundStyle(.secondary)
                }
                Spacer()
            }
            HStack {
                TextField("Например: открой Safari или найди файл отчёт.csv", text: $command)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { runCommand() }
                Button("Выполнить") { runCommand() }
            }
            GroupBox("Быстрые действия") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    Button { showingFilePicker = true } label: {
                        Label("Выбрать и открыть файл", systemImage: "doc").frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button { showingFolderPicker = true } label: {
                        Label("Открыть папку", systemImage: "folder").frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button { openApp("Safari") } label: {
                        Label("Открыть браузер", systemImage: "safari").frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button { openWebSearch(command.isEmpty ? "поиск" : command) } label: {
                        Label("Искать в интернете", systemImage: "magnifyingglass").frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.buttonStyle(.bordered)
            }
            GroupBox("Приложения") {
                HStack {
                    ForEach(commonApps, id: \.self) { app in Button(app) { openApp(app) } }
                }.buttonStyle(.bordered)
            }
            GroupBox("Выбранный файл") {
                if let selectedFile {
                    Text(selectedFile.path).textSelection(.enabled).font(.callout)
                    if !csvPreview.isEmpty {
                        ScrollView {
                            Text(csvPreview).font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        }.frame(maxHeight: 160)
                    }
                } else {
                    Text("Файл пока не выбран.").foregroundStyle(.secondary)
                }
            }
            GroupBox("Состояние") {
                Text(status).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                selectedFile = url
                csvPreview = url.pathExtension.lowercased() == "csv" ? readCSVPreview(url) : ""
                let opened = NSWorkspace.shared.open(url)
                status = opened ? "Файл передан приложению macOS для открытия: \(url.lastPathComponent)" : "macOS не смогла открыть файл: \(url.path)"
            case .failure(let error): status = "Не удалось выбрать файл: \(error.localizedDescription)"
            }
        }
        .fileImporter(isPresented: $showingFolderPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                selectedFile = url
                let opened = NSWorkspace.shared.open(url)
                status = opened ? "Папка открыта в Finder: \(url.path)" : "Не удалось открыть папку."
            case .failure(let error): status = "Не удалось выбрать папку: \(error.localizedDescription)"
            }
        }
    }

    private func runCommand() {
        let text = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { status = "Введите команду."; return }
        let lower = text.lowercased()
        if lower.contains("safari") || lower.contains("браузер") { openApp("Safari") }
        else if lower.contains("finder") || lower.contains("файлов") { openApp("Finder") }
        else if lower.contains("numbers") { openApp("Numbers") }
        else if lower.contains("excel") { openApp("Microsoft Excel") }
        else if lower.contains("1с") || lower.contains("1c") { openApp("1C") }
        else if lower.contains("поиск") || lower.contains("найди в интернете") { openWebSearch(text) }
        else if lower.contains("выбери файл") || lower.contains("открой файл") { showingFilePicker = true }
        else if lower.contains("папк") { showingFolderPicker = true }
        else { status = "Команда пока не поддерживается. Попробуйте открыть Safari/Finder/Numbers/Excel/1С, выбрать файл или папку либо выполнить поиск." }
    }

    private func openApp(_ name: String) {
        let bundleID: String
        switch name {
        case "Finder": bundleID = "com.apple.finder"
        case "Safari": bundleID = "com.apple.Safari"
        case "Numbers": bundleID = "com.apple.iWork.Numbers"
        case "Microsoft Excel": bundleID = "com.microsoft.Excel"
        default: bundleID = "ru.soul.unknown"
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let ok = NSWorkspace.shared.open(url)
            status = ok ? "Запущено приложение: \(name)" : "Не удалось запустить \(name)."
            return
        }
        let candidates = ["/Applications/\(name).app", "/System/Applications/\(name).app",
                          "/Applications/Microsoft Excel.app", "/Applications/1C.app", "/Applications/1cv8.app"]
        if let path = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            let ok = NSWorkspace.shared.open(URL(fileURLWithPath: path))
            status = ok ? "Запущено приложение: \(name)" : "Не удалось открыть \(path)"
        } else {
            status = "Не нашёл приложение «\(name)». Проверьте, установлено ли оно на Mac; имя приложения 1С может отличаться."
        }
    }

    private func openWebSearch(_ query: String) {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components?.url else { status = "Не удалось подготовить запрос."; return }
        NSWorkspace.shared.open(url)
        status = "Открыл веб-поиск по запросу: \(query)"
    }

    private func readCSVPreview(_ url: URL) -> String {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return content.components(separatedBy: .newlines).prefix(30).joined(separator: "\\n")
        } catch {
            return "Не удалось прочитать CSV как UTF-8: \(error.localizedDescription)"
        }
    }
}
