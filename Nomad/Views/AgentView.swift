//
//  AgentView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct AgentView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var inputText = ""
    @State private var selectedProperty: Property?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                NomadTheme.offWhite.ignoresSafeArea()

                VStack(spacing: 0) {
                    chatMessages
                    inputBar
                }
            }
            .navigationTitle("Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !appVM.chatService.messages.isEmpty {
                        Button {
                            appVM.chatService.clearChat()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(NomadTheme.lightGrey)
                        }
                    }
                }
            }
            .fullScreenCover(item: $selectedProperty) { property in
                PropertyDetailView(property: property, appVM: appVM)
            }
        }
    }

    private var chatMessages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    welcomeMessage

                    ForEach(appVM.chatService.messages) { message in
                        chatBubble(message)
                            .id(message.id)
                    }

                    if appVM.chatService.isTyping {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: appVM.chatService.messages.count) {
                withAnimation(.easeOut(duration: 0.25)) {
                    if let last = appVM.chatService.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: appVM.chatService.messages.last?.content) {
                if let last = appVM.chatService.messages.last, last.isStreaming {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .onChange(of: appVM.chatService.isTyping) { _, isTyping in
                if isTyping {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    private var welcomeMessage: some View {
        HStack(alignment: .top, spacing: 10) {
            agentAvatar(size: 36, iconFont: .title3)

            VStack(alignment: .leading, spacing: 10) {
                Text("Nomad Agent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NomadTheme.darkText)

                Text("Hi! I'm your real estate assistant. Ask me anything about properties — I can help you find homes by location, price, features, and more.")
                    .font(.body)
                    .foregroundStyle(NomadTheme.darkText)
                    .lineSpacing(3)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        SuggestionChip(text: "Show luxury homes") {
                            sendMessage("Show me luxury homes")
                        }
                        SuggestionChip(text: "Affordable options") {
                            sendMessage("Show me affordable properties under $400K")
                        }
                        SuggestionChip(text: "Waterfront") {
                            sendMessage("Find waterfront properties")
                        }
                        SuggestionChip(text: "Montreal condos") {
                            sendMessage("Show me condos in Montreal")
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.white, in: .rect(cornerRadius: 20))
    }

    @ViewBuilder
    private func chatBubble(_ message: ChatMessage) -> some View {
        if message.isUser {
            HStack {
                Spacer(minLength: 60)
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(NomadTheme.darkGreen, in: .rect(cornerRadius: 20))
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    agentAvatar(size: 28, iconFont: .caption)

                    VStack(alignment: .leading, spacing: 4) {
                        if !message.content.isEmpty {
                            HStack(spacing: 0) {
                                Text(message.content)
                                    .font(.body)
                                    .foregroundStyle(NomadTheme.darkText)
                                    .lineSpacing(3)

                                if message.isStreaming {
                                    streamingCursor
                                }
                            }
                        } else if message.isStreaming && message.properties.isEmpty {
                            streamingCursor
                        }
                    }

                    Spacer(minLength: 0)
                }

                if !message.properties.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(message.properties) { property in
                                Button {
                                    selectedProperty = property
                                } label: {
                                    MiniPropertyCard(property: property)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .contentMargins(.horizontal, 0)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(14)
            .background(.white, in: .rect(cornerRadius: 20))
        }
    }

    private var streamingCursor: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(NomadTheme.darkGreen)
            .frame(width: 2, height: 18)
            .opacity(0.8)
    }

    private func agentAvatar(size: CGFloat, iconFont: Font) -> some View {
        Image(systemName: "building.2.fill")
            .font(iconFont)
            .foregroundStyle(NomadTheme.darkGreen)
            .frame(width: size, height: size)
            .background(NomadTheme.lightGreen.opacity(0.3), in: .circle)
    }

    private var typingIndicator: some View {
        HStack(spacing: 10) {
            agentAvatar(size: 28, iconFont: .caption)

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(NomadTheme.lightGrey.opacity(0.6))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))

            Spacer()
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about properties...", text: $inputText)
                .focused($isInputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground), in: .capsule)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage(inputText)
                }

            Button {
                sendMessage(inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(canSend ? NomadTheme.darkGreen : NomadTheme.lightGrey)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !appVM.chatService.isTyping
    }

    private func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let message = text
        inputText = ""
        Task {
            await appVM.chatService.sendMessage(message)
        }
    }
}

struct SuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(NomadTheme.darkGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(NomadTheme.lightGreen.opacity(0.3), in: .capsule)
        }
    }
}
