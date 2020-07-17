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
  
  /// Observable property that can be used to updated the UI.
  @Published public var authStatus = "Checking HealthKit authorization status..."
  
  /// Optional block that will exectute when HealthKit is not available
  public var dataNotAvailableBlock: (() -> Void)? = nil
  
  private let healthStore = HKHealthStore()
  
  /// The HealthKit data types we will request to read.
  private let readTypes = Set([HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!])

  private var hasRequestedData = false
  
  public static var shared = HealthKitHelper()
  
  private init() {}
  
  // MARK: - Public API
  
  public func getAuthorizationStatus() {
    guard HKHealthStore.isHealthDataAvailable() else { self.dataNotAvailableBlock?(); return }
    
    healthStore.getRequestStatusForAuthorization(toShare: [], read: readTypes) { (authorizationRequestStatus, error) in
      
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
    
    healthStore.requestAuthorization(toShare: [], read: readTypes) { (success, error) in
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
  
}
