//
//  StatsViewController.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/20/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import UIKit
import Combine

class StatsViewController: UIViewController, UITableViewDelegate {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var stepsLabel: UILabel!
  @IBOutlet weak var historyLabel: UILabel!
  @IBOutlet weak var metricLabel: UILabel!
  @IBOutlet weak var metricBGView: UIView!
  
  private let cellReuseIdentifier = "stepscell"
  private lazy var dataSource = makeDataSource()
  
  private var refreshControl = UIRefreshControl()
  
  private var stepStatistics = [StepsStatistic]() {
    didSet {
      var snapshot = NSDiffableDataSourceSnapshot<Section, StepsStatistic>()
      snapshot.appendSections(Section.allCases)
      snapshot.appendItems(self.stepStatistics, toSection: .main)
      print("snapshot created \(self.stepStatistics)")
      dataSource.apply(snapshot, animatingDifferences: true)
    }
  }
  
  private let viewModel = StatsViewModel()
  private var fetchAndCleanUp: () -> Void {
    return {
      if !self.viewModel.fetchStats() {
        self.refreshControl.endRefreshing()
      }
    }
  }
  
  private var subscriptions = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupBlurEffect()
    self.setupTableView()
    self.setupObservers()
    
    self.fetchAndCleanUp()
  }
  
}

extension StatsViewController {
  internal enum Section: CaseIterable {
    case main
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return kStepCellHeight
  }
  
  private func makeDataSource() -> UITableViewDiffableDataSource<Section, StepsStatistic> {
    let cellId = cellReuseIdentifier
    return UITableViewDiffableDataSource(
      tableView: self.tableView,
      cellProvider: {  tableView, indexPath, statistic in
        let cell = self.tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        guard let stepsCell = cell as? StepsTableViewCell else { return cell }
        
        stepsCell.setData(statistic: statistic)
        return stepsCell
    })
  }
}

extension StatsViewController {
  private func setupBlurEffect() {
    guard let bounds = self.metricBGView?.bounds else { return }
    
    let blurEffect = UIBlurEffect(style: .systemChromeMaterialDark)
    let blurEffectView = UIVisualEffectView(effect: blurEffect)
    blurEffectView.frame = bounds
    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.metricBGView?.insertSubview(blurEffectView, at: 0)
  }
  
  private func setupObservers() {
    let _ = viewModel.$stepHistory
      .combineLatest(viewModel.$stepsForToday)
      .subscribe(on: DispatchQueue.global())
      .receive(on: DispatchQueue.main)
      .sink { stats, today in
        let historyTitle = self.viewModel.isChronological ? "Yesterday" : "Two weeks ago"
        self.historyLabel?.text = historyTitle
        self.metricLabel?.text = "Average: \(self.viewModel.dailyAvg.shortString)"
        
        self.stepsLabel?.text = "\(today.shortString)"
        self.stepStatistics = stats
        
        self.refreshControl.endRefreshing()
      }
      .store(in: &subscriptions)
    
    let _ = viewModel.$error
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
      .store(in: &subscriptions)
  }
  
  private func setupTableView() {
    self.tableView.delegate = self
    
    let insets = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
    self.tableView.contentInset = insets
    
    let orderButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(StatsViewController.orderButtonTapped))
    self.navigationItem.rightBarButtonItem  = orderButton
    self.navigationController?.navigationBar.prefersLargeTitles = true
    
    self.tableView.register(StepsTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    self.tableView.dataSource = dataSource
    self.tableView.allowsSelection = false
    
    self.refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
    self.tableView.refreshControl = self.refreshControl
  }
}

extension StatsViewController {
  @objc func orderButtonTapped() {
    self.viewModel.toggleOrder()
  }
  
  @objc func refresh(_ sender: AnyObject) {
    self.fetchAndCleanUp()
  }
}

