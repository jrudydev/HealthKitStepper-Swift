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


/// Constant used to create the starting date for the sample two weeks in the past excluding current day
let kDaysInSample: Int = 13

public class HealthKitHelper {
  
  public typealias StatisticResponse = (startDate: Date, steps: Double)
  
  /// Observable properties that can be used to update the UI.
  @Published public private (set) var authStatus = "Checking HealthKit authorization status..."
  
  /// Optional block that will exectute when HealthKit is not available
  public var dataNotAvailableBlock: (() -> Void)? = nil

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
  
  public func getStepHistory(completion: @escaping ([StepsStatistic], Error?) -> Void) {
    print("Retrieving step count from HealthKit...")
    
    let now = Date()
    let endDate = Calendar.current.startOfDay(for: now)
    let startDate = Calendar.current.date(byAdding: .day, value: -kDaysInSample, to: endDate)!
    let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                end: endDate,
                                                options: .strictStartDate)
    
    var interval = DateComponents()
    interval.day = 1
    let query = HKStatisticsCollectionQuery(quantityType: readStepCountType,
                                            quantitySamplePredicate: predicate,
                                            options: [.cumulativeSum],
                                            anchorDate: startDate as Date,
                                            intervalComponents:interval)
    
    query.initialResultsHandler = { _, results, error in
      guard let results = results else {
        if let error = error { completion([], error) }
        return
      }
      
      var resultsArray = [(Date, Double)]()
      results.enumerateStatistics(from: startDate, to: now) {
        statistics, stop in
        
        if let quantity = statistics.sumQuantity() {
          let steps = quantity.doubleValue(for: HKUnit.count())
          
          print("Start Date: \(statistics.startDate), Steps = \(steps)")
          
          let readStepsResponseTuple = (statistics.startDate, steps)
          resultsArray.append(readStepsResponseTuple)
        }
      }
    }
    
    self.healthStore.execute(query)
  }
  
  public func getTodaysSteps(completion: @escaping  (Double, Error?) -> Void) {
    let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
    let now = Date()
    let startOfDay = Calendar.current.startOfDay(for: now)
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay,
                                                end: now,
                                                options: .strictStartDate)
    
    let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
      guard let result = result, let sum = result.sumQuantity() else {
        if let error = error { completion(0.0, error) }
        return
      }
      completion(sum.doubleValue(for: HKUnit.count()), nil)
    }
    
    self.healthStore.execute(query)
  }
  
}
