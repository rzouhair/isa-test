//
//  ChatView.swift
//  swiftquill
//
//  Created by user on 14/2/2025.
//

import SwiftUI

struct ChatView: View {
    @Environment(AIService.self) private var service
    @State private var newMessage = ""
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(service.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.top)
            }
            .scrollIndicators(.hidden)
            
            HStack {
                TextField("Type a message...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                
                Button {
                    Task { await sendMessage() }
                } label: {
                    if service.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                    }
                }
                .disabled(service.isLoading || newMessage.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .alert("Error", isPresented: .constant(service.error != nil)) {
            Button("OK", role: .cancel) { service.error = nil }
        } message: {
            Text(service.error?.localizedDescription ?? "Unknown error")
        }
    }
    
    private func sendMessage() async {
        let text = newMessage
        newMessage = ""
        await service.sendMessage(text)
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let functionName = message.functionName {
                    Text(functionName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(message.content)
                
                if let functionCall = message.functionCall {
                    VStack(alignment: .leading) {
                        Text("Function call:")
                            .font(.caption)
                        Text(functionCall.name)
                        Text(functionCall.arguments)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
            .foregroundStyle(message.role == .user ? Color.white : Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            if message.role != .user {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    ChatView()
        .environment(AIService(provider: OpenAIProvider(apiKey: Constants.openAIKey)))
}
