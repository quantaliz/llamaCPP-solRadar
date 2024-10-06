//
//  llamaUIApp.swift
//  llamaUI
//
//  Ported by r on 19/8/2024.
//  MIT license
//  Original code: https://github.com/ggerganov/llama.cpp/tree/master/examples/llama.swiftui
//

import Foundation

struct Model: Identifiable {
    var id = UUID()
    var name: String
    var url: String
    var filename: String
    var status: String?
}

@MainActor
class LlamaState: ObservableObject {
    @Published var messageLog = ""
    @Published var cacheCleared = false
    @Published var downloadedModels: [Model] = []
    @Published var undownloadedModels: [Model] = []
    let NS_PER_S = 1_000_000_000.0

    var sysPromptLoaded = false
    private var llamaContext: LlamaContext?
    private var defaultModelUrl: URL? {
//        Bundle.main.url(forResource: "ggml-model", withExtension: "gguf", subdirectory: "models")
        URL(string:"/Users/rhvt/Dev/llm/models/Llama-3.1-8B-Instruct-IQ3_XS.gguf")
    }

    init() {
        loadModelsFromDisk()
        loadDefaultModels()
    }

    private func loadModelsFromDisk() {
        do {
            let documentsURL = getDocumentsDirectory()
            let modelURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for modelURL in modelURLs
            {
                // Filter for .gguf files
                guard modelURL.pathExtension.lowercased() == "gguf" else {
                    return
                }
                
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                downloadedModels.append(Model(name: modelName, url: "", filename: modelURL.lastPathComponent, status: "downloaded"))
            }
        } catch {
            print("Error loading models from disk: \(error)")
        }
    }

    private func loadDefaultModels() {
        do {
            try loadModel(modelUrl: defaultModelUrl)
        } catch {
            messageLog += "Error!\n"
        }

        for model in defaultModels {
            let fileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {

            } else {
                var undownloadedModel = model
                undownloadedModel.status = "download"
                undownloadedModels.append(undownloadedModel)
            }
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private let defaultModels: [Model] = [
        Model(name: "Llama-3.1-8B-Instruct (IQ3_XS, 3.52 GiB)",
              url: "https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF?download=true",
              filename: "Meta-Llama-3.1-8B-Instruct-IQ3_XS.gguf",
              status: "download"),
    ]
    
    func loadModel(modelUrl: URL?) throws {
        if let modelUrl {
            messageLog += "Loading model...\n"
            llamaContext = try LlamaContext.create_context(path: modelUrl.path())
            if let locLlamaContext = llamaContext  {
                messageLog += "Loaded model \(modelUrl.lastPathComponent)\n"
                
                // Assuming that the model is successfully loaded, update the downloaded models
                updateDownloadedModels(modelName: modelUrl.lastPathComponent, status: "downloaded")
            }
            else {
                messageLog += "Model with URL: \(modelUrl) could not be loaded\n"
            }
        } else {
            messageLog += "Load a model from the list below\n"
        }
    }


    private func updateDownloadedModels(modelName: String, status: String) {
        undownloadedModels.removeAll { $0.name == modelName }
    }


    func complete(text: String) async {
        guard let llamaContext else {
            return
        }
        
        var fullText = ""
        
        if sysPromptLoaded == false
        {
            fullText = await llamaContext.loadSysPrompt()
            fullText += LlamaContext.usrPrompt
            fullText += text
            fullText += LlamaContext.asstPrompt
            
            sysPromptLoaded = true
        }
        else {
            fullText = LlamaContext.usrPrompt
            fullText = text
            fullText += LlamaContext.asstPrompt
        }

        let t_start = DispatchTime.now().uptimeNanoseconds
        await llamaContext.completion_init(text: text)
        let t_heat_end = DispatchTime.now().uptimeNanoseconds
        let t_heat = Double(t_heat_end - t_start) / NS_PER_S

        messageLog += "\n\nUser: \(text) \n\nAssistant: "

        Task.detached {
            while await !llamaContext.is_done {
                let result = await llamaContext.completion_loop()
                await MainActor.run {
                    self.messageLog += "\(result)"
                }
            }

            let t_end = DispatchTime.now().uptimeNanoseconds
            let t_generation = Double(t_end - t_heat_end) / self.NS_PER_S
            let tokens_per_second = Double(await llamaContext.n_len) / t_generation

            await llamaContext.clear()

            await MainActor.run {
                self.messageLog += """
                    \n
                    Done
                    Heat up took \(t_heat)s
                    Generated \(tokens_per_second) t/s\n
                    """
            }
        }
    }

    func bench() async {
        guard let llamaContext else {
            return
        }

        messageLog += "\n"
        messageLog += "Running benchmark...\n"
        messageLog += "Model info: "
        messageLog += await llamaContext.model_info() + "\n"

        let t_start = DispatchTime.now().uptimeNanoseconds
        let _ = await llamaContext.bench(pp: 8, tg: 4, pl: 1) // heat up
        let t_end = DispatchTime.now().uptimeNanoseconds

        let t_heat = Double(t_end - t_start) / NS_PER_S
        messageLog += "Heat up time: \(t_heat) seconds, please wait...\n"

        // if more than 5 seconds, then we're probably running on a slow device
        if t_heat > 5.0 {
            messageLog += "Heat up time is too long, aborting benchmark\n"
            return
        }

        let result = await llamaContext.bench(pp: 512, tg: 128, pl: 1, nr: 3)

        messageLog += "\(result)"
        messageLog += "\n"
    }

    func clear() async {
        guard let llamaContext else {
            return
        }

        await llamaContext.clear()
        messageLog = ""
    }
}
