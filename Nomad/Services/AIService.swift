//
//  ToolCallInfo.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation

nonisolated struct ToolCallInfo: Sendable {
    let id: String
    let name: String
    let argsJSON: String
}

nonisolated enum StreamEvent: Sendable {
    case textDelta(String)
    case toolCall(ToolCallInfo)
    case finish
    case error(String)
}

class AIService {
    private var baseURL: String {
        Config.EXPO_PUBLIC_TOOLKIT_URL
    }

    var isAvailable: Bool {
        !baseURL.isEmpty
    }

    func streamChat(messages: [[String: Any]], tools: [String: Any]? = nil) -> AsyncStream<StreamEvent> {
        AsyncStream { continuation in
            Task { [baseURL] in
                guard !baseURL.isEmpty, let url = URL(string: "\(baseURL)/agent/chat") else {
                    continuation.yield(.error("AI service not configured"))
                    continuation.finish()
                    return
                }

                var body: [String: Any] = ["messages": messages]
                if let tools { body["tools"] = tools }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 60

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                } catch {
                    continuation.yield(.error("Failed to encode request"))
                    continuation.finish()
                    return
                }

                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.yield(.error("Invalid response"))
                        continuation.finish()
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        continuation.yield(.error("Server error (\(httpResponse.statusCode))"))
                        continuation.finish()
                        return
                    }

                    var buffer = ""
                    for try await byte in bytes {
                        let char = Character(UnicodeScalar(byte))
                        if char == "\n" {
                            if !buffer.isEmpty {
                                for event in AIService.parseLine(buffer) {
                                    continuation.yield(event)
                                }
                                buffer = ""
                            }
                        } else {
                            buffer.append(char)
                        }
                    }

                    if !buffer.isEmpty {
                        for event in AIService.parseLine(buffer) {
                            continuation.yield(event)
                        }
                    }

                    continuation.yield(.finish)
                    continuation.finish()
                } catch {
                    continuation.yield(.error(error.localizedDescription))
                    continuation.finish()
                }
            }
        }
    }

    nonisolated private static func parseLine(_ line: String) -> [StreamEvent] {
        guard line.count >= 2 else { return [] }

        let firstChar = line[line.startIndex]
        let secondIndex = line.index(after: line.startIndex)
        guard line[secondIndex] == ":" else { return [] }

        let valueString = String(line[line.index(after: secondIndex)...])

        switch firstChar {
        case "0":
            guard let data = valueString.data(using: .utf8) else { return [] }
            if let text = try? JSONSerialization.jsonObject(with: data) as? String {
                return [.textDelta(text)]
            }
            return []

        case "9", "c":
            guard let data = valueString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let toolCallId = json["toolCallId"] as? String,
                  let toolName = json["toolName"] as? String else {
                return []
            }
            let args = json["args"] ?? [String: Any]()
            let argsJSON: String
            if let argsData = try? JSONSerialization.data(withJSONObject: args),
               let str = String(data: argsData, encoding: .utf8) {
                argsJSON = str
            } else {
                argsJSON = "{}"
            }
            return [.toolCall(ToolCallInfo(id: toolCallId, name: toolName, argsJSON: argsJSON))]

        case "e", "3":
            guard let data = valueString.data(using: .utf8) else { return [.error(valueString)] }
            if let errorText = try? JSONSerialization.jsonObject(with: data) as? String {
                return [.error(errorText)]
            }
            return [.error(valueString)]

        case "d":
            return [.finish]

        default:
            return []
        }
    }
}
