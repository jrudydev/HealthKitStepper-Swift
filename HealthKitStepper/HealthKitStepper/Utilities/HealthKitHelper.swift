//
//  HealthKitHelper.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/17/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import Foundation
import HealthKit
import Combine
import UIKit


public class HealthKitHelper {
  
  public typealias StatisticResponse = (startDate: Date, steps: Double)
  
  /// Observable properties that can be used to updated the UI.
  @Published public private (set) var authStatus = "Checking HealthKit authorization status..."
  @Published public private (set) var stepsResponse = [StatisticResponse]()
  
  /// Optional block that will exectute when HealthKit is not available
  public var dataNotAvailableBlock: (() -> Void)? = nil
  
  public private (set) var isChronological = true {
    didSet {
      self.stepsResponse.reverse()
    }
  }
  
  private let healthStore = HKHealthStore()
  
  /// The HealthKit data type we will request to read.
  private let readStepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!

  private var hasRequestedData = false
  
  public static var shared = HealthKitHelper()
  
  private init() {}
  
  // MARK: - Public API
  
  public func getAuthorizationStatus() {
    guard HKHealthStore.isHealthDataAvailable() else { self.dataNotAvailableBlock?(); return }
    
    healthStore.getRequestStatusForAuthorization(toShare: [], read: [readStepCountType]) { (authorizationRequestStatus, error) in
      
      var status: String = ""
      if let error = error {
        status = "HealthKit Authorization Error: \(error.localizedDescription)"
      } else {
        switch authorizationRequestStatus {
        case .shouldRequest:
          self.hasRequestedData = false
          
          status = "The application has not yet requested authorization for all of the specified data types."
        case .unknown:
          status = "The authorization request status could not be determined because an error occurred."
        case .unnecessary:
          self.hasRequestedData = true
                
          status = "The application has already requested authorization for the specified data types. "
        default:
          break
        }
      }
        
      print(status)
      self.authStatus = status
    }
  }
  
  public func requestAuthorization(authCompletion: @escaping () -> Void) {
    print("Requesting HealthKit authorization...")
    
    guard HKHealthStore.isHealthDataAvailable() else { self.dataNotAvailableBlock?(); return }
    
    healthStore.requestAuthorization(toShare: [], read: [readStepCountType]) { (success, error) in
      var status: String = ""
      
      if let error = error {
        status = "HealthKit Authorization Error: \(error.localizedDescription)"
      } else {
        if success {
          if self.hasRequestedData {
            status = "Health data already requested."
          } else {
            status = "HealthKit authorization request was successful."
          }
          
          self.hasRequestedData = true
          
          authCompletion()
        } else {
          status = "HealthKit authorization did not complete successfully."
        }
      }
      
      print(status)
      self.authStatus = status
    }
  }
  
  public func retrieveStepCount(completion: @escaping (Error?) -> Void) {
    print("Retrieving step count from HealthKit...")
    
    let today = Date()
    let cal = Calendar(identifier: Calendar.Identifier.gregorian)
    let startDate = cal.date(byAdding: .day, value: -7, to: today)!
    
    let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                end: Date(),
                                                options: .strictStartDate)
    var interval = DateComponents()
    interval.day = 1
    let query = HKStatisticsCollectionQuery(quantityType: readStepCountType,
                                            quantitySamplePredicate: predicate,
                                            options: [.cumulativeSum],
                                            anchorDate: startDate as Date,
                                            intervalComponents:interval)
    
    query.initialResultsHandler = { query, results, error in
      if let error = error { completion(error); return }
      
      guard let results = results else { return }
      
      var resultsArray = [(Date, Double)]()
      results.enumerateStatistics(from: startDate, to: today) {
        statistics, stop in
        
        if let quantity = statistics.sumQuantity() {
          let steps = quantity.doubleValue(for: HKUnit.count())
          
          print("Start Date: \(statistics.startDate), Steps = \(steps)")
          
          let readStepsResponseTuple = (statistics.startDate, steps)
          resultsArray.append(readStepsResponseTuple)
        }
      }
      
      self.stepsResponse = resultsArray.reversed()
      completion(nil)
    }
    
    healthStore.execute(query)
  }
  
  public func toggleOrder() {
    self.isChronological.toggle()
  }
  
}
