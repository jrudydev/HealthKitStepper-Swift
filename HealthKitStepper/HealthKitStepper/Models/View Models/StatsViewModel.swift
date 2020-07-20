//
//  StatsViewModel.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/20/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import Foundation
import Combine


/// This value is used to debounce the request to the datasouce
let kDebounceThreshold: Int = 3


/// This protocol defines a method that fetches the data, the response should be observed by the view controller
protocol StatsDataSource {
  var stepsForToday: Double { get set }
  var stepHistory: [StepsStatistic] { get set }
  var error: Error? { get set }
  
  var dailyAvg: Double { get }
  var dailyMin: Int { get }
  var dailyMax: Int { get }
  
  func fetchStats()
}


class StatsViewModel {
  
  enum StatsError: Error {
    case noPermission
    case authError
    case readError
  }
  
  /// Observable properties that can be used to update the UI.
  @Published public internal (set) var stepsForToday: Double = 0
  @Published public internal (set) var stepHistory = [StepsStatistic]()
  @Published public internal (set) var error: Error? = nil
  
  public private (set) var isChronological = true
  
  private var lastFetched: Date? = nil
  
  init() {
    HealthKitHelper.shared.dataNotAvailableBlock = { [weak self] in
      self?.error = StatsError.noPermission
    }
  }
  
  internal var fetchBlock: () -> Void {
    return {
      HealthKitHelper.shared.getTodaysSteps() { steps, error in
        guard error == nil else { self.error = error!; return }
        
        self.stepsForToday = steps
      }
      HealthKitHelper.shared.getStepHistory() { result, error in
        guard error == nil else { self.error = error!; return }
        
        self.stepHistory = result.reversed()
        self.isChronological = true
      }
    }
  }
  
  public func toggleOrder() {
    self.stepHistory.reverse()
    self.isChronological.toggle()
  }
}

extension StatsViewModel: StatsDataSource {
  public var dailyAvg: Double {
    guard self.stepHistory.count > 0 else { return 0.0 }
    
    let total: Int = self.stepHistory.reduce(0) { $0 + $1.steps }
    return Double(total) / Double(self.stepHistory.count)
  }
  
  public var dailyMin: Int {
    return self.stepHistory.min()?.steps ?? 0
  }
  
  public var dailyMax: Int {
    return self.stepHistory.max()?.steps ?? 0
  }
  
  public func authorize() {
    HealthKitHelper.shared.getAuthorizationStatus()
  }
  
  public func fetchStats() {
    self.fetchStatsIfNeeded()
  }

  private func fetchStatsIfNeeded() {
    guard let lastFetched = self.lastFetched else {
      self.fetchBlock()
      self.lastFetched = Date()
      return
    }
    
    let debounceCutoff = Calendar.current.date(byAdding: .second,
                                               value: kDebounceThreshold,
                                               to: lastFetched)!
    guard Date() > debounceCutoff else { return }
    
    self.fetchBlock()
    self.lastFetched = Date()
  }
}

extension Double {
  var shortString: String {
    guard self > 99999 else { return String(format: "%.0f", self) }
    
    let newUnitvalue = self / 1000
    return String(format: "%.2f", newUnitvalue)
  }
}

extension StepsStatistic {
  var startDateLabel: String {
    let startDate = DateFormatter()
    startDate.dateFormat = "MMM d"
    
    return startDate.string(from: self.startDate)
  }
  
  var dayOfWeekLabel: String {
    let dow = DateFormatter()
    dow.dateFormat = "E"
    
    return dow.string(from: self.startDate)
  }
}
