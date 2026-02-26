import SwiftUI

struct AgentView: View {
    @Environment(AppViewModel.self) private var appVM

    @State private var inputText = ""
    @State private var selectedProperty: Property?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            chatMessages
                .safeAreaInset(edge: .bottom) {
                    inputBar
                }
                .nomadScreenBackground()
                .navigationTitle("Agent")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if !appVM.chatService.messages.isEmpty {
                            NomadIconCircleButton(icon: "arrow.counterclockwise") {
                                appVM.chatService.clearChat()
                            }
                            .accessibilityLabel("Clear conversation")
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
                LazyVStack(spacing: NomadSpacing.md) {
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
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.top, NomadSpacing.md)
                .padding(.bottom, NomadSpacing.md)
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
                    withAnimation {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var welcomeMessage: some View {
        HStack(alignment: .top, spacing: NomadSpacing.sm) {
            agentAvatar(size: 36, iconFont: .system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: NomadSpacing.sm) {
                Text("Nomad Agent")
                    .font(NomadTypography.bodyStrong)
                    .foregroundStyle(NomadColor.Text.primary)

                Text("Hi, I'm your real estate assistant. Ask anything about properties and I can help by location, budget, and features.")
                    .font(NomadTypography.body)
                    .foregroundStyle(NomadColor.Text.primary)
                    .lineSpacing(3)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: NomadSpacing.xs) {
                        SuggestionChip(text: "Luxury homes") {
                            sendMessage("Show me luxury homes")
                        }
                        SuggestionChip(text: "Affordable") {
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
        .padding(NomadSpacing.md)
        .nomadCardSurface(level: .level1, radius: NomadRadius.card)
    }

    @ViewBuilder
    private func chatBubble(_ message: ChatMessage) -> some View {
        if message.isUser {
            HStack {
                Spacer(minLength: 72)

                Text(message.content)
                    .font(NomadTypography.body)
                    .foregroundStyle(NomadColor.Background.surface)
                    .padding(.horizontal, NomadSpacing.md)
                    .padding(.vertical, NomadSpacing.sm)
                    .background(NomadColor.Accent.primary, in: .rect(cornerRadius: NomadRadius.card))
            }
        } else {
            VStack(alignment: .leading, spacing: NomadSpacing.sm) {
                HStack(alignment: .top, spacing: NomadSpacing.sm) {
                    agentAvatar(size: 30, iconFont: .system(size: 12, weight: .semibold))

                    VStack(alignment: .leading, spacing: NomadSpacing.xxs) {
                        if !message.content.isEmpty {
                            HStack(spacing: 0) {
                                Text(message.content)
                                    .font(NomadTypography.body)
                                    .foregroundStyle(NomadColor.Text.primary)
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
                        HStack(spacing: NomadSpacing.sm) {
                            ForEach(message.properties) { property in
                                Button {
                                    selectedProperty = property
                                } label: {
                                    NomadPropertyCard(property: property, variant: .compact)
                                        .frame(width: 220)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .contentMargins(.horizontal, 0)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(NomadSpacing.md)
            .nomadCardSurface(level: .level1, radius: NomadRadius.card)
        }
    }

    private var streamingCursor: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(NomadColor.Accent.primary)
            .frame(width: 2, height: 18)
            .opacity(0.8)
    }

    private func agentAvatar(size: CGFloat, iconFont: Font) -> some View {
        Image(systemName: "building.2.fill")
            .font(iconFont)
            .foregroundStyle(NomadColor.Accent.primary)
            .frame(width: size, height: size)
            .background(NomadColor.Accent.soft, in: .circle)
    }

    private var typingIndicator: some View {
        HStack(spacing: NomadSpacing.sm) {
            agentAvatar(size: 28, iconFont: .system(size: 12, weight: .semibold))

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(NomadColor.Text.tertiary.opacity(0.6))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, NomadSpacing.md)
            .padding(.vertical, NomadSpacing.sm)
            .background(NomadColor.Background.surfaceMuted, in: .rect(cornerRadius: NomadRadius.control))

            Spacer(minLength: 0)
        }
    }

    private var inputBar: some View {
        HStack(spacing: NomadSpacing.sm) {
            TextField("Ask about properties...", text: $inputText)
                .focused($isInputFocused)
                .font(NomadTypography.body)
                .padding(.horizontal, NomadSpacing.md)
                .frame(minHeight: 48)
                .background(NomadColor.Background.surfaceMuted, in: .capsule)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage(inputText)
                }

            Button {
                sendMessage(inputText)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NomadColor.Background.surface)
                    .frame(width: 44, height: 44)
                    .background(canSend ? NomadColor.Accent.primary : NomadColor.Text.tertiary, in: .circle)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, NomadSpacing.pageHorizontal)
        .padding(.vertical, NomadSpacing.sm)
        .background(.ultraThinMaterial)
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
        NomadChip(text: text, isSelected: false, isCompact: true, action: action)
    }
}
