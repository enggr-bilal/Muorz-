import SwiftUI

struct MuorzCounter: View {
    @ObservedObject var muorzManager: MuorzManager
    @State private var showingPurchaseSheet = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var showAttentionAnimation = false
    @State private var attentionScale: CGFloat = 1.0
    @State private var lastMuorzCount: Int = 0
    @State private var coinDropAnimation = false
    @State private var coinDropScale: CGFloat = 1.0
    @State private var animatedMuorzCount: Int = 0
    @State private var startingMuorzCount: Int = 0
    
    var body: some View {
        VStack(alignment:.trailing, spacing: 6) {
            // Main Muorz Counter - Circle overlaying Capsule
            Button {
                showingPurchaseSheet = true
            } label: {
                ZStack(alignment: .leading) {
                    // Background Capsule (compact width)
                    HStack(spacing: 0) {
                        // Spacer to make room for the overlapping circle
                        Spacer(minLength: 50)
                             // More space for circle + spacing
                        
                        // Text content
                        Text(currentStatusText)
                            .font(.system(.subheadline, design: .serif))
                            .fontWeight(.semibold)
                            .foregroundColor(textColor)
                            .padding(.trailing, 12) // Right padding
                    }
                    .frame(height: 36) // Fixed height
                    .background(
                        Capsule()
                            .fill(capsuleBackgroundColor)
                           // .stroke(capsuleStrokeColor, lineWidth: 1.5)
                    )
                    
                    // Overlapping Circle on the left
                    ZStack {
                        // White background circle for clean number display
                        Circle()
                            
                            .fill(circleBackgroundColor)
                              .frame(width: 41, height: 41)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
                        
                        
                        // Number symbol
                        Image(systemName: currentIconName)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(symbolColor)
                    }
                    .scaleEffect(circleScaleValue)
                    .rotationEffect(.degrees(showAttentionAnimation ? 360 : 0))
                    .offset(x: -4) // Less offset for better proportions
                    .animation(.easeInOut(duration: 0.6), value: showAttentionAnimation)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: coinDropAnimation)
                }
                .fixedSize(horizontal: true, vertical: false) // Compact width
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                lastMuorzCount = muorzManager.remainingMuorz
                animatedMuorzCount = muorzManager.remainingMuorz
            }
            .onChange(of: muorzManager.remainingMuorz) { oldValue, newValue in
                // Trigger attention animation when Muorz decreases
                if newValue < lastMuorzCount {
                    triggerAttentionAnimation()
                }
                lastMuorzCount = newValue
                
                // Update animated count if not in coin drop animation
                if !coinDropAnimation {
                    animatedMuorzCount = newValue
                }
            }
            .onChange(of: muorzManager.pendingCoinDrop) { oldValue, newValue in
                if newValue > 0 {
                    startCoinDropAnimation(count: newValue)
                    muorzManager.pendingCoinDrop = 0 // Reset after triggering
                }
            }
            
            // Refill Timer - Only show when no Muorz and no Travel Pass
            if shouldShowRefillTimer {
                Text(muorzManager.refillTimeText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(0.8)
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: shouldShowRefillTimer)
        .sheet(isPresented: $showingPurchaseSheet) {
            MuorzPurchaseSheet(muorzManager: muorzManager)
        }
    }
    
    // MARK: - Animation Functions
    
    private func triggerAttentionAnimation() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Visual attention animation - only on circle
        withAnimation(.easeInOut(duration: 0.1)) {
            attentionScale = 1.4
            showAttentionAnimation = true
        }
        
        // Return to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                attentionScale = 1.0
            }
        }
        
        // Reset animation flag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showAttentionAnimation = false
        }
    }
    
    private func startCoinDropAnimation(count: Int) {
        coinDropAnimation = true
        startingMuorzCount = muorzManager.remainingMuorz - count // Starting point before the coins
        animatedMuorzCount = startingMuorzCount
        
        // Create rapid haptic feedback and scale animations for each "coin"
        for i in 0..<count {
            let delay = Double(i) * 0.08 // 80ms between each coin
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Light haptic for each coin
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                // Increment the animated count
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    animatedMuorzCount = startingMuorzCount + i + 1
                }
                
                // Quick scale animation - more dramatic for coin drop
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    coinDropScale = 1.6 // Bigger scale to overflow capsule
                }
                
                // Return to normal quickly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        coinDropScale = 1.0
                    }
                }
            }
        }
        
        // Final strong haptic to signal completion
        let finalDelay = Double(count) * 0.08 + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + finalDelay) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // Ensure final count matches actual Muorz
            animatedMuorzCount = muorzManager.remainingMuorz
            
            // Reset animation state
            coinDropAnimation = false
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentIconName: String {
        if muorzManager.hasActiveTravelDayPass {
            return "airplane.circle.fill"
        } else if muorzManager.remainingMuorz == 0 {
            return "plus.circle.fill"
        } else if coinDropAnimation {
            // Use number circles during animation
            let currentNumber = min(animatedMuorzCount, 50) // SF Symbols go up to 50
            if currentNumber <= 50 && currentNumber > 0 {
                return "\(currentNumber).circle.fill"
            } else {
                return "star.circle.fill"
            }
        } else {
            // Use number circles for normal state too
            let currentNumber = min(muorzManager.remainingMuorz, 50)
            if currentNumber <= 50 && currentNumber > 0 {
                return "\(currentNumber).circle.fill"
            } else {
                return "star.circle.fill"
            }
        }
    }
    
    private var currentStatusText: String {
        if muorzManager.hasActiveTravelDayPass {
            return "Unlimited"
        } else if muorzManager.remainingMuorz == 0 {
            return "Get some Muorz"
        } else {
            // Just show "Muorz left" since SF Symbol shows the number
            return "Muorz"
        }
    }
    
    private var circleScaleValue: CGFloat {
        if coinDropAnimation {
            return coinDropScale
        } else if showAttentionAnimation {
            return attentionScale
        } else {
            return 1.0
        }
    }
    
    private var symbolColor: Color {
        if muorzManager.hasActiveTravelDayPass {
            return .orange
        } else if muorzManager.remainingMuorz == 0 {
            return .white
        } else {
            return .yellow // Blue numbers on white background for better contrast
        }
    }
    
    private var capsuleBackgroundColor: Color {
        if muorzManager.remainingMuorz == 0 {
            return .accentColor // Blue background for CTA
        } else {
            return .white
        }
    }
    
    private var capsuleStrokeColor: Color {
        if muorzManager.remainingMuorz == 0 {
            return .clear
        } else {
            return .accentColor
        }
    }
    
    private var textColor: Color {
        return muorzManager.remainingMuorz == 0 ? .white : .accentColor
    }
    
    private var shouldShowRefillTimer: Bool {
        return muorzManager.remainingMuorz == 0 && !muorzManager.hasActiveTravelDayPass
    }
    
    private var circleBackgroundColor: Color {
        if muorzManager.remainingMuorz == 0 {
            return .accentColor
        } else {
            return .white
        }
    }
}

// MARK: - Purchase Sheet

struct MuorzPurchaseSheet: View {
    @ObservedObject var muorzManager: MuorzManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        // Stack of circles instead of single icon
                        ZStack {
                            HStack(spacing: -4) {
                                
                                    
                                 ZStack{
                                     Text("M")
                                         .font(.system(size: 24, weight: .bold))
                                         .foregroundColor(.white)
                                     
                                         .zIndex(4)
                                     Circle()
                                         .fill(.yellow)
                                         .frame(width: 50, height: 50)
                                         .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                         .zIndex(2)
                                 }
                                
                             }
                             
                            
                          }
                        
                        Text(headerTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                        
                        Text(headerSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Purchase Options - Top row: 10 and 30 Muorz
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach([MuorzPackage.small, MuorzPackage.medium], id: \.rawValue) { package in
                            MuorzPackageCard(
                                package: package,
                                onPurchase: {
                                    handlePurchase(package)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Travel Pass - Full width
                    MuorzPackageCard(
                        package: .travelPass,
                        onPurchase: {
                            handlePurchase(.travelPass)
                        }
                    )
                    .padding(.horizontal)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Take a Bite Out of Every Menu")
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            FeatureRow(icon: "fork.knife", text: "Know what you eat")
                            FeatureRow(icon: "slider.horizontal.3", text: "Fit your diet")
                            FeatureRow(icon: "face.smiling", text: "Order with ease")
                           
                        }
                        .padding(.horizontal)
                    }
                    
                    // DEBUG: Testing Button (remove in production)
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal)
                        
                        Text("🧪 Testing Tools")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Button {
                            resetMuorzForTesting()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Reset to 0 Muorz")
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.orange.opacity(0.3), lineWidth: 1)
                                    .fill(.white)
                            )
                        }
                    }
                    .padding(.bottom, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.gray.opacity(0.1))
          
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Muorz Store")
                        .font(.system(.title2, design: .serif))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private var headerTitle: String {
        return muorzManager.remainingMuorz == 0 ? "Time for More Bites" : "Stock Up Your Appetite"
    }
    
    private var headerSubtitle: String {
        if muorzManager.remainingMuorz == 0 {
            return "Get more Muorz to continue taking bites out of amazing dishes around the world"
        } else {
            return "Keep your appetite satisfied and never miss a delicious discovery!"
        }
    }
    
    private func handlePurchase(_ package: MuorzPackage) {
        // Mock purchase for now - in real app this would integrate with StoreKit
        let muorzCount = package.muorzCount
        
        switch package {
        case .travelPass:
            muorzManager.activateTravelDayPass()
        default:
            muorzManager.addMuorz(muorzCount)
            // Set pending coin drop animation AFTER adding Muorz
            muorzManager.pendingCoinDrop = muorzCount
        }
        
        // Show initial success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
    
    private func resetMuorzForTesting() {
        muorzManager.remainingMuorz = 0
        muorzManager.hasTravelDayPass = false
        muorzManager.travelDayPassExpiryDate = nil
        
        // Save the reset state
        let defaults = UserDefaults.standard
        defaults.set(0, forKey: "remainingMuorz")
        defaults.set(false, forKey: "hasTravelDayPass")
        defaults.removeObject(forKey: "travelDayPassExpiryDate")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("🧪 Testing: Muorz reset to 0")
    }
}

// MARK: - Supporting Views

struct MuorzPackageCard: View {
    let package: MuorzPackage
    let onPurchase: () -> Void
    @State private var isPressed = false
    @State private var showSuccessAnimation = false
    
    var body: some View {
        Button {
            triggerPurchaseAnimation()
        } label: {
            VStack(spacing: 12) {
                // Title and icon/circle
                if package == .travelPass {
                    // Special design for travel pass
                    VStack(spacing: 8) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .scaleEffect(isPressed ? 1.2 : 1.0)
                            .rotationEffect(.degrees(showSuccessAnimation ? 360 : 0))
                        
                        Text(package.displayName)
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    // Regular packages with circle and Muorz in HStack
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 32, height: 32)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                            .overlay(
                                Text("\(package.muorzCount)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(isPressed ? 1.2 : 1.0)
                        
                        Text("Muorz")
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(.primary)
                    }
                }
                
                // Description
                Text(package.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Price with highlight animation
                Text(package.price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(package == .travelPass ? .accentColor : .accentColor)
                    .scaleEffect(isPressed ? 1.1 : 1.0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .stroke(strokeColor, lineWidth: package == .travelPass ? 2 : 1)
                    .shadow(color: shadowColor, radius: isPressed ? 8 : 2, x: 0, y: isPressed ? 4 : 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
        .animation(.easeInOut(duration: 0.6), value: showSuccessAnimation)
    }
    
    private func triggerPurchaseAnimation() {
        // Success animation
        withAnimation(.easeInOut(duration: 0.6)) {
            showSuccessAnimation = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Slight delay before calling onPurchase for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onPurchase()
        }
        
        // Reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showSuccessAnimation = false
        }
    }
    
    private var strokeColor: Color {
        if showSuccessAnimation {
            return .green.opacity(0.6)
        } else if package == .travelPass {
            return .accentColor
        } else {
            return .gray.opacity(0.2)
        }
    }
    
    private var shadowColor: Color {
        if showSuccessAnimation {
            return .green.opacity(0.3)
        } else if isPressed {
            return  .accentColor
        } else {
            return .black.opacity(0.1)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Normal State") {
    VStack {
        Spacer()
        
        HStack {
            Spacer()
            MuorzCounter(muorzManager: {
                let manager = MuorzManager()
                manager.remainingMuorz = 2
                return manager
            }())
        }
        .padding()
        
        Spacer()
    }
    .background(Color.black)
}

#Preview("Zero State - CTA") {
    VStack {
        Spacer()
        
        HStack {
            Spacer()
            MuorzCounter(muorzManager: {
                let manager = MuorzManager()
                manager.remainingMuorz = 0
                return manager
            }())
        }
        .padding()
        
        Spacer()
    }
    .background(Color.black)
}

#Preview("Travel Pass") {
    VStack {
        Spacer()
        
        HStack {
            Spacer()
            MuorzCounter(muorzManager: {
                let manager = MuorzManager()
                manager.activateTravelDayPass()
                return manager
            }())
        }
        .padding()
        
        Spacer()
    }
    .background(Color.black)
} 
