//
//  GlassEffectContainer.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import SwiftUI

struct GlassEffectContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if #available(iOS 26.0, *) {
            // Use iOS 26 Liquid Glass effect
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        } else {
            // Fallback for older iOS versions
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
}

@available(iOS 26, *)
struct GlassButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(.glass)
    }
}

struct FallbackButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    GlassEffectContainer {
        VStack {
            Text("Glass Effect")
                .font(.headline)
            Text("This container has a glass effect")
                .font(.caption)
        }
        .padding()
    }
}
