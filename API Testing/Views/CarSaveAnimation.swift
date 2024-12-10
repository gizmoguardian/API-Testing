import SwiftUI

struct CarSaveAnimation: View {
    @Binding var isShowing: Bool
    let onCompletion: () -> Void
    
    @State private var offset: CGFloat = -400  // Back to single CGFloat for horizontal movement
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .opacity(isShowing ? 1 : 0)
            
            Image(systemName: "car.side.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150)
                .foregroundColor(.blue)
                .scaleEffect(x: -1, y: 1)  // Keep the horizontal flip
                .offset(x: offset)  // Just horizontal offset
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        offset = -400  // Start from left
        scale = 1
        opacity = 1
        
        withAnimation(.easeOut(duration: 0.8)) {
            offset = 400  // End at right
            scale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isShowing = false
            onCompletion()
        }
    }
} 