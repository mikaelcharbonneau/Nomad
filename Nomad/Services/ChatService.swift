//
//  ChatService.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation

@Observable
@MainActor
class ChatService {
    var messages: [ChatMessage] = []
    var isTyping = false

    private let aiService = AIService()
    private let listingsService = ListingsService.shared
    private var conversationHistory: [[String: Any]] = []

    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        conversationHistory.append(["role": "user", "content": text])

        isTyping = true

        if aiService.isAvailable {
            await sendAIMessage(text)
        } else {
            try? await Task.sleep(for: .seconds(1.2))
            let response = generateFallbackResponse(for: text)
            isTyping = false
            messages.append(response)
            conversationHistory.append(["role": "assistant", "content": response.content])
        }
    }

    func clearChat() {
        messages.removeAll()
        conversationHistory.removeAll()
    }

    private func sendAIMessage(_ text: String) async {
        var fullText = ""
        var toolCallProperties: [Property] = []
        var assistantIndex: Int?

        let apiMessages = buildAPIMessages()
        let tools = buildToolDefinitions()
        let stream = aiService.streamChat(messages: apiMessages, tools: tools)

        for await event in stream {
            switch event {
            case .textDelta(let delta):
                if assistantIndex == nil {
                    isTyping = false
                    let msg = ChatMessage(content: delta, isUser: false, isStreaming: true)
                    messages.append(msg)
                    assistantIndex = messages.count - 1
                    fullText = delta
                } else {
                    fullText += delta
                    messages[assistantIndex!].content = fullText
                }

            case .toolCall(let info):
                if info.name == "showProperties" {
                    let props = executeShowProperties(argsJSON: info.argsJSON)
                    toolCallProperties = props
                    if let idx = assistantIndex {
                        messages[idx].properties = props
                    } else {
                        isTyping = false
                        let msg = ChatMessage(content: "", isUser: false, properties: props, isStreaming: true)
                        messages.append(msg)
                        assistantIndex = messages.count - 1
                    }
                }

            case .error:
                isTyping = false
                if assistantIndex == nil {
                    let fallback = generateFallbackResponse(for: text)
                    messages.append(fallback)
                    conversationHistory.append(["role": "assistant", "content": fallback.content])
                    return
                } else {
                    messages[assistantIndex!].isStreaming = false
                }

            case .finish:
                break
            }
        }

        if let idx = assistantIndex {
            messages[idx].isStreaming = false
        } else {
            isTyping = false
            let fallback = generateFallbackResponse(for: text)
            messages.append(fallback)
            fullText = fallback.content
            toolCallProperties = fallback.properties
        }

        isTyping = false
        conversationHistory.append(["role": "assistant", "content": fullText])
    }

    private func buildAPIMessages() -> [[String: Any]] {
        var apiMessages: [[String: Any]] = []
        apiMessages.append(["role": "system", "content": buildSystemPrompt()])
        apiMessages.append(contentsOf: conversationHistory)
        return apiMessages
    }

    private func buildSystemPrompt() -> String {
        var prompt = """
        You are Nomad, a friendly and knowledgeable real estate assistant helping users find their perfect property in Quebec, Canada. You speak naturally and conversationally, like a knowledgeable friend who happens to be a real estate expert.

        When users ask about properties, ALWAYS use the showProperties tool to display matching listings. Select the most relevant property IDs based on the user's criteria. Keep your text responses concise — 1-3 sentences max — and let the property cards do the heavy lifting.

        Here is the current listing database you can reference:
        """

        for property in listingsService.properties {
            prompt += "\n- ID: \(property.id) | \(property.title) | \(property.formattedPrice) | \(property.city), \(property.region) | \(property.bedrooms)bd/\(property.bathrooms)ba | \(property.squareFeet)sqft | Type: \(property.propertyType.rawValue) | \(property.listingType.rawValue)"
            if property.isWaterfront { prompt += " | Waterfront" }
            if property.hasPool { prompt += " | Pool" }
            if property.hasElevator { prompt += " | Elevator" }
            if property.isPetFriendly { prompt += " | Pet-friendly" }
            if property.isFeatured { prompt += " | Featured" }
            if property.lotSize > 0 { prompt += " | Lot: \(property.lotSize)sqft" }
        }

        prompt += """

        Guidelines:
        - When showing properties, call showProperties with the relevant property IDs
        - Be warm, helpful, and concise
        - If the user asks something unrelated to real estate, politely steer the conversation back
        - Use property IDs from the database above when calling the tool
        - You can recommend properties proactively if they match the conversation context
        """

        return prompt
    }

    private func buildToolDefinitions() -> [String: Any] {
        [
            "showProperties": [
                "description": "Display property listing cards to the user. Call this whenever you want to show or recommend properties. Pass an array of property IDs from the database.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "propertyIds": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Array of property IDs to display (e.g. [\"p1\", \"p3\", \"p9\"]). Select IDs that best match the user's request."
                        ]
                    ],
                    "required": ["propertyIds"]
                ] as [String: Any]
            ] as [String: Any]
        ]
    }

    private func executeShowProperties(argsJSON: String) -> [Property] {
        guard let data = argsJSON.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ids = args["propertyIds"] as? [String] else {
            return Array(listingsService.properties.shuffled().prefix(3))
        }

        let matched = ids.compactMap { id in listingsService.properties.first { $0.id == id } }
        return matched.isEmpty ? Array(listingsService.properties.shuffled().prefix(3)) : matched
    }

    private func generateFallbackResponse(for query: String) -> ChatMessage {
        let lower = query.lowercased()
        let allProps = listingsService.properties

        if lower.contains("waterfront") || lower.contains("lake") || lower.contains("water") {
            let matching = allProps.filter { $0.isWaterfront || $0.description.lowercased().contains("lake") || $0.description.lowercased().contains("water") }
            return ChatMessage(
                content: "I found \(matching.count) waterfront or lake-adjacent properties for you! Here are some beautiful options with stunning water views:",
                isUser: false,
                properties: Array(matching.prefix(5))
            )
        }

        if lower.contains("cheap") || lower.contains("affordable") || lower.contains("budget") || lower.contains("under") {
            let matching = allProps.filter { $0.price < 400000 && $0.listingType == .sale }.sorted { $0.price < $1.price }
            return ChatMessage(
                content: "Here are the most affordable properties I found. These offer great value for your budget:",
                isUser: false,
                properties: Array(matching.prefix(5))
            )
        }

        if lower.contains("luxury") || lower.contains("expensive") || lower.contains("premium") || lower.contains("high end") {
            let matching = allProps.filter { $0.price > 800000 }.sorted { $0.price > $1.price }
            return ChatMessage(
                content: "Here are the premium luxury listings currently available:",
                isUser: false,
                properties: Array(matching.prefix(5))
            )
        }

        if lower.contains("condo") || lower.contains("apartment") {
            let matching = allProps.filter { $0.propertyType == .condo || $0.propertyType == .loft }
            return ChatMessage(
                content: "I found \(matching.count) condos and lofts that might interest you:",
                isUser: false,
                properties: Array(matching.prefix(5))
            )
        }

        if lower.contains("family") || lower.contains("kids") || lower.contains("children") || lower.contains("bedroom") {
            let matching = allProps.filter { $0.bedrooms >= 3 }.sorted { $0.bedrooms > $1.bedrooms }
            return ChatMessage(
                content: "For families, I'd recommend these spacious homes with 3+ bedrooms:",
                isUser: false,
                properties: Array(matching.prefix(5))
            )
        }

        if lower.contains("montreal") {
            let matching = allProps.filter { $0.city == "Montreal" }
            return ChatMessage(
                content: "Here are the properties available in Montreal:",
                isUser: false,
                properties: Array(matching.prefix(5))
            )
        }

        if lower.contains("rent") {
            let matching = allProps.filter { $0.listingType == .rent }
            return ChatMessage(
                content: "Here are the rental properties currently available:",
                isUser: false,
                properties: Array(matching.prefix(5))
            )
        }

        let randomSelection = Array(allProps.shuffled().prefix(3))
        return ChatMessage(
            content: "Here are some properties you might like. Feel free to ask about specific locations, price ranges, or property types!",
            isUser: false,
            properties: randomSelection
        )
    }
}
