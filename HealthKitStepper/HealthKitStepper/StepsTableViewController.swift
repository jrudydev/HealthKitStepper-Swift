//
//  ViewController.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/17/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import UIKit

class StepsTableViewController: UITableViewController {
  
  private enum Section: CaseIterable {
      case main
  }
  
  private let cellReuseIdentifier = "stepscell"
  private lazy var dataSource = makeDataSource()
  
  private var stepStatistics = [StepsStatistic]() {
    didSet {
      var snapshot = NSDiffableDataSourceSnapshot<Section, StepsStatistic>()
      snapshot.appendSections(Section.allCases)
      snapshot.appendItems(self.stepStatistics, toSection: .main)

      dataSource.apply(snapshot, animatingDifferences: true)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Steps"
    
    let orderButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"),
                                      style: .plain,
                                      target: self,
                                      action:#selector(StepsTableViewController.orderButtonTapped))
    self.navigationItem.rightBarButtonItem  = orderButton
    self.navigationController?.navigationBar.prefersLargeTitles = true
    
    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    self.tableView.dataSource = dataSource
    
    let _ = HealthKitHelper.shared.$stepsResponse
      .subscribe(on: DispatchQueue.main)
      .receive(on: DispatchQueue.main)
      .map { $0.map { StepsStatistic(startDate: $0.startDate, steps: Int($0.steps)) } }
      .sink { statistics in
        self.stepStatistics = statistics
      }
    
    HealthKitHelper.shared.retrieveStepCount() { error in
      // show alert
    }
  }

  private func makeDataSource() -> UITableViewDiffableDataSource<Section, StepsStatistic> {
    let cellId = cellReuseIdentifier
    return UITableViewDiffableDataSource(
      tableView: self.tableView,
      cellProvider: {  tableView, indexPath, statistic in
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
      
        cell.textLabel?.text = "\(statistic.steps)"
        cell.detailTextLabel?.text = statistic.dayOfWeekLabel
        let label = UILabel(frame: .zero)
        label.text = statistic.startDateLabel
        label.sizeToFit()
        cell.accessoryView = label
        return cell
    })
  }
  
}

extension StepsTableViewController {
  @objc func orderButtonTapped() {
    HealthKitHelper.shared.toggleOrder()
  }
}
