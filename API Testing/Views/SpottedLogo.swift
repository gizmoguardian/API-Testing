import SwiftUI

struct SpottedLogo: View {
    var height: CGFloat = 60
    
    var body: some View {
        VStack(spacing: 20) {
            Image("spotted-logo")
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue, .blue.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .blue.opacity(0.5), radius: 5)
            
            Text("Spotted")
                .font(.system(size: height * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .shadow(color: .blue.opacity(0.2), radius: 10)
        )
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        SpottedLogo(height: 80)
            .padding()
    }
} 
