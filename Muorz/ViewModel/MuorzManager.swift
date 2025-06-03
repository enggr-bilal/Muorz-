import Foundation
import SwiftUI

@MainActor
class MuorzManager: ObservableObject {
    // MARK: - Published Properties
    @Published var remainingMuorz: Int = 3
    @Published var lastRefillDate: Date = Date()
    @Published var hasTravelDayPass: Bool = false
    @Published var travelDayPassExpiryDate: Date?
    @Published var pendingCoinDrop: Int = 0 // For coin drop animation
    
    // MARK: - Constants
    private let weeklyMuorzAllocation = 3
    private let refillIntervalDays = 7
    
    // MARK: - UserDefaults Keys
    private let remainingMuorzKey = "remainingMuorz"
    private let lastRefillDateKey = "lastRefillDate"
    private let travelDayPassKey = "hasTravelDayPass"
    private let travelDayPassExpiryKey = "travelDayPassExpiryDate"
    
    init() {
        loadData()
        checkForWeeklyRefill()
        checkForWelcomeBonus()
    }
    
    // MARK: - Core Functionality
    
    /// Deducts one Muorz if available
    /// - Returns: True if Muorz was deducted, false if none available
    func deductMuorz() -> Bool {
        // Travel Day Pass users get unlimited scans
        if hasActiveTravelDayPass {
            return true
        }
        
        guard remainingMuorz > 0 else {
            return false
        }
        
        remainingMuorz -= 1
        saveData()
        return true
    }
    
    /// Adds Muorz from in-app purchases
    func addMuorz(_ count: Int) {
        remainingMuorz += count
        saveData()
    }
    
    /// Activates travel day pass for 24 hours
    func activateTravelDayPass() {
        hasTravelDayPass = true
        travelDayPassExpiryDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
        saveData()
    }
    
    /// Adds bonus Muorz (e.g., from referrals, welcome bonus)
    func addBonusMuorz(_ count: Int, reason: String) {
        remainingMuorz += count
        saveData()
        
        // Could add analytics or notifications here
        print("🎁 Bonus Muorz added: \(count) (\(reason))")
    }
    
    /// Handles referral bonus for both referrer and referee
    func processReferral(referralCode: String, isReferrer: Bool = false) {
        let bonusAmount = 5
        let reason = isReferrer ? "Referral bonus - friend joined" : "Welcome bonus - friend invited you"
        addBonusMuorz(bonusAmount, reason: reason)
        
        // Mark referral as processed
        UserDefaults.standard.set(true, forKey: isReferrer ? "hasReferredSomeone" : "hasUsedReferralCode")
    }
    
    // MARK: - Computed Properties
    
    var canScan: Bool {
        return hasActiveTravelDayPass || remainingMuorz > 0
    }
    
    var hasActiveTravelDayPass: Bool {
        guard hasTravelDayPass,
              let expiryDate = travelDayPassExpiryDate else {
            return false
        }
        
        if Date() > expiryDate {
            // Pass expired, clean up
            hasTravelDayPass = false
            travelDayPassExpiryDate = nil
            saveData()
            return false
        }
        
        return true
    }
    
    var daysUntilRefill: Int {
        let nextRefillDate = Calendar.current.date(byAdding: .day, value: refillIntervalDays, to: lastRefillDate) ?? Date()
        let components = Calendar.current.dateComponents([.day], from: Date(), to: nextRefillDate)
        return max(0, components.day ?? 0)
    }
    
    var hoursUntilRefill: Int {
        let nextRefillDate = Calendar.current.date(byAdding: .day, value: refillIntervalDays, to: lastRefillDate) ?? Date()
        let components = Calendar.current.dateComponents([.hour], from: Date(), to: nextRefillDate)
        return max(0, components.hour ?? 0)
    }
    
    var refillTimeText: String {
        if hasActiveTravelDayPass {
            let remainingHours = hoursUntilTravelPassExpiry
            if remainingHours > 0 {
                return "Day Pass: \(remainingHours)h left"
            } else {
                return "Day Pass expired"
            }
        }
        
        let days = daysUntilRefill
        let hours = hoursUntilRefill % 24
        
        if days > 0 {
            return "Refills in \(days)d \(hours)h"
        } else if hours > 0 {
            return "Refills in \(hours)h"
        } else {
            return "Refilling soon..."
        }
    }
    
    var muorzStatusText: String {
        if hasActiveTravelDayPass {
            return "Unlimited"
        } else if remainingMuorz == 1 {
            return "1 Muorz left"
        } else {
            return "\(remainingMuorz) Muorz left"
        }
    }
    
    private var hoursUntilTravelPassExpiry: Int {
        guard let expiryDate = travelDayPassExpiryDate else { return 0 }
        let components = Calendar.current.dateComponents([.hour], from: Date(), to: expiryDate)
        return max(0, components.hour ?? 0)
    }
    
    // MARK: - Weekly Refill Logic
    
    private func checkForWeeklyRefill() {
        let calendar = Calendar.current
        let daysSinceLastRefill = calendar.dateComponents([.day], from: lastRefillDate, to: Date()).day ?? 0
        
        if daysSinceLastRefill >= refillIntervalDays {
            // Refill Muorz
            remainingMuorz = weeklyMuorzAllocation
            lastRefillDate = Date()
            saveData()
            
            print("🔄 Weekly Muorz refill: \(weeklyMuorzAllocation) Muorz added")
        }
    }
    
    /// Checks if user is eligible for welcome bonus and grants it
    private func checkForWelcomeBonus() {
        let hasReceivedWelcomeBonus = UserDefaults.standard.bool(forKey: "hasReceivedWelcomeBonus")
        
        if !hasReceivedWelcomeBonus {
            // Give welcome bonus
            addBonusMuorz(2, reason: "Welcome to Muorz!")
            UserDefaults.standard.set(true, forKey: "hasReceivedWelcomeBonus")
            print("🎉 Welcome bonus granted: 2 extra Muorz")
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        let defaults = UserDefaults.standard
        
        remainingMuorz = defaults.object(forKey: remainingMuorzKey) as? Int ?? weeklyMuorzAllocation
        lastRefillDate = defaults.object(forKey: lastRefillDateKey) as? Date ?? Date()
        hasTravelDayPass = defaults.bool(forKey: travelDayPassKey)
        travelDayPassExpiryDate = defaults.object(forKey: travelDayPassExpiryKey) as? Date
    }
    
    private func saveData() {
        let defaults = UserDefaults.standard
        
        defaults.set(remainingMuorz, forKey: remainingMuorzKey)
        defaults.set(lastRefillDate, forKey: lastRefillDateKey)
        defaults.set(hasTravelDayPass, forKey: travelDayPassKey)
        defaults.set(travelDayPassExpiryDate, forKey: travelDayPassExpiryKey)
    }
}

// MARK: - In-App Purchase Models

enum MuorzPackage: String, CaseIterable {
    case small = "muorz_10_pack"
    case medium = "muorz_20_pack"
    case large = "muorz_30_pack"
    case travelPass = "travel_day_pass"
    
    var muorzCount: Int {
        switch self {
        case .small: return 10
        case .medium: return 20
        case .large: return 30
        case .travelPass: return 0 // Unlimited for 24h
        }
    }
    
    var displayName: String {
        switch self {
        case .small: return "10 Muorz"
        case .medium: return "20 Muorz"
        case .large: return "30 Muorz"
        case .travelPass: return "Travel Day Pass"
        }
    }
    
    var price: String {
        switch self {
        case .small: return "€1.49"
        case .medium: return "€2.49"
        case .large: return "€3.49"
        case .travelPass: return "€1.99"
        }
    }
    
    var description: String {
        switch self {
        case .small, .medium, .large:
            return "\(muorzCount) menu scans"
        case .travelPass:
            return "Unlimited scans for 24h"
        }
    }
    
    var icon: String {
        switch self {
        case .small: return "star.fill"
        case .medium: return "star.circle.fill"
        case .large: return "crown.fill"
        case .travelPass: return "airplane"
        }
    }
} 