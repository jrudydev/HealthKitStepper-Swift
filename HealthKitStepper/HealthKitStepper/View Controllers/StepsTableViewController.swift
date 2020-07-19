//
//  ViewController.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/17/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import UIKit


class StepsTableViewController: UITableViewController {

  private let cellReuseIdentifier = "stepscell"
  private lazy var dataSource = makeDataSource()
  
  private var stepStatistics = [StepsStatistic]() {
    didSet {
      var snapshot = NSDiffableDataSourceSnapshot<Section, StepsStatistic>()
      snapshot.appendSections(Section.allCases)
      snapshot.appendItems(self.stepStatistics, toSection: .main)
print("snapshot created \(self.stepStatistics)")
      dataSource.apply(snapshot, animatingDifferences: true)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Steps"
    
    self.setupTableView()
    self.setupObservers()
    
    self.fetchSteps()
  }
  
}

extension StepsTableViewController {
  internal enum Section: CaseIterable {
    case main
  }
  
  private class StepsTableViewDiffableDataSource: UITableViewDiffableDataSource<Section, StepsStatistic> {
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
      return snapshot().sectionIdentifiers[section].title.uppercased()
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return kStepCellHeight
  }
  
  private func makeDataSource() -> StepsTableViewDiffableDataSource {
    let cellId = cellReuseIdentifier
    return StepsTableViewDiffableDataSource(
      tableView: self.tableView,
      cellProvider: {  tableView, indexPath, statistic in
        let cell = self.tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        guard let stepsCell = cell as? StepsTableViewCell else { return cell }
        
        stepsCell.setData(statistic: statistic)
        return stepsCell
    })
  }
}

extension StepsTableViewController {
  private func setupObservers() {
    let _ = HealthKitHelper.shared.$stepHistory
      .combineLatest(HealthKitHelper.shared.$stepsForToday)
      .subscribe(on: DispatchQueue.global())
      .receive(on: DispatchQueue.main)
      .sink { stats, today in
        self.tableView.reloadData() // Done to reload the section header

        let statsForToday = StepsStatistic(startDate: Date(), steps: Int(today))
        let stepHistory = stats.map { StepsStatistic(startDate: $0.startDate, steps: Int($0.steps)) }
        self.stepStatistics = HealthKitHelper.shared.isChronological ?
          [statsForToday] + stepHistory : stepHistory + [statsForToday]
        self.refreshControl?.endRefreshing()
    }
    
    let _ = HealthKitHelper.shared.$error
      .compactMap { $0 }
      .subscribe(on: DispatchQueue.global())
      .receive(on: DispatchQueue.main)
      .sink { error in
        let alertController = UIAlertController(
          title: "Health Data Unavailable",
          message: "Unable to access health data. Check device capabilities. Error: \(error)",
          preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .default)
        
        alertController.addAction(action)
        
        self.present(alertController, animated: true)
      }
  }
  
  private func setupTableView() {
    let orderButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(StepsTableViewController.orderButtonTapped))
    self.navigationItem.rightBarButtonItem  = orderButton
    self.navigationController?.navigationBar.prefersLargeTitles = true
    
    self.tableView.register(StepsTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    self.tableView.dataSource = dataSource
    self.tableView.allowsSelection = false
    
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
    self.refreshControl = refreshControl
  }
  
  private func fetchSteps() {
    HealthKitHelper.shared.getTodaysSteps()
    HealthKitHelper.shared.getStepHistory()
  }
}

extension StepsTableViewController {
  @objc func orderButtonTapped() {
    HealthKitHelper.shared.toggleOrder()
  }
  
  @objc func refresh(_ sender: AnyObject) {
    self.fetchSteps()
  }
}

extension StepsTableViewController.Section {
  var title: String {
    return HealthKitHelper.shared.isChronological ? "Today" : "Two weeks ago"
  }
}
