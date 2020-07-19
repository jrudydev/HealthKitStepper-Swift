//
//  StepsTableViewCell.swift
//  HealthKitStepper
//
//  Created by Rudy Gomez on 7/18/20.
//  Copyright © 2020 JRudyGaming. All rights reserved.
//

import UIKit


let kStepCellHeight: CGFloat = 100.0

class StepsTableViewCell: UITableViewCell {
  
  let dowContainer: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  let dowBGView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .gray
    view.clipsToBounds = true
    view.layer.cornerRadius = 30.0
    return view
  }()
  
  let dowLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.textColor = .white
    label.text = "Sun"
    return label
  }()
  
  let stepsLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = label.font.withSize(50.0)
    label.textColor = AppConstants.Colors.green
    label.text = "99999"
    return label
  }()
  
  let dateLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
//    label.font = label.font.withSize(60.0)
    label.text = "Jan 1"
    return label
  }()
  
  let padding: CGFloat = 20.0

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    self.setupViews()
    self.setupConstraints()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupViews() {
    self.addSubview(self.dowContainer)
    self.dowContainer.addSubview(self.dowBGView)
    self.dowBGView.addSubview(self.dowLabel)
    self.addSubview(self.stepsLabel)
    self.addSubview(self.dateLabel)
  }
  
  private func setupConstraints() {
    var contstraints = [NSLayoutConstraint]()
    
    contstraints += self.dowContainerConstraints()
    contstraints += self.dowBGConstraints()
    contstraints += self.dowLabelConstraints()
    contstraints += self.stepsLabelConstratints()
    contstraints += self.dateLabelConstratints()
    
    NSLayoutConstraint.activate(contstraints)
  }
  
  private func dowContainerConstraints() -> [NSLayoutConstraint] {
    let leading = dowContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
    let top = dowContainer.topAnchor.constraint(equalTo: contentView.topAnchor)
    let width = dowContainer.widthAnchor.constraint(equalToConstant: kStepCellHeight)
    let height = dowContainer.heightAnchor.constraint(equalToConstant: kStepCellHeight)

    return [leading, top, width, height]
  }
  
  private func dowBGConstraints() -> [NSLayoutConstraint] {
    let padding: CGFloat = 20.0
    
    let leading = dowBGView.leadingAnchor.constraint(
      equalTo: dowContainer.leadingAnchor, constant: padding)
    let top = dowBGView.topAnchor.constraint(
      equalTo: dowContainer.topAnchor, constant: padding)
    let bottom = dowBGView.bottomAnchor.constraint(
      equalTo: dowContainer.bottomAnchor, constant: -padding)
    let trailing = dowBGView.trailingAnchor.constraint(
      equalTo: dowContainer.trailingAnchor, constant: -padding)
    
    return [leading, top, bottom, trailing]
  }
  
  private func dowLabelConstraints() -> [NSLayoutConstraint] {
    let padding: CGFloat = 12.0
    
    let leading = dowLabel.leadingAnchor.constraint(
      equalTo: dowBGView.leadingAnchor, constant: padding)
    let top = dowLabel.topAnchor.constraint(
      equalTo: dowBGView.topAnchor, constant: padding)
    let bottom = dowLabel.bottomAnchor.constraint(
      equalTo: dowBGView.bottomAnchor, constant: -padding)
    let trailing = dowLabel.trailingAnchor.constraint(
      equalTo: dowBGView.trailingAnchor, constant: -padding)
    
    return [leading, top, bottom, trailing]
  }
  
  private func stepsLabelConstratints() -> [NSLayoutConstraint] {
    let screenSize = UIScreen.main.bounds
    let labelWidth = screenSize.width - kStepCellHeight*2 - padding
    
    let leading = stepsLabel.leadingAnchor.constraint(
      equalTo: dowContainer.trailingAnchor, constant: padding)
    let centerY = stepsLabel.centerYAnchor.constraint(equalTo: dowContainer.centerYAnchor)
    let width = stepsLabel.widthAnchor.constraint(equalToConstant: labelWidth)
    return [leading, width, centerY]
  }
  
  private func dateLabelConstratints() -> [NSLayoutConstraint] {
    let centerY = dateLabel.centerYAnchor.constraint(equalTo: dowContainer.centerYAnchor)
    let centerX = dateLabel.centerXAnchor.constraint(
      equalTo: stepsLabel.trailingAnchor, constant: kStepCellHeight/2)

    return [centerX, centerY]
  }
  
}

extension StepsTableViewCell {
  public func setData(statistic: StepsStatistic) {
    self.dowLabel.text = statistic.dayOfWeekLabel
    self.stepsLabel.text = "\(statistic.steps)"
    self.dateLabel.text = statistic.startDateLabel
  }
}
