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
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .opacity(0.8)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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
