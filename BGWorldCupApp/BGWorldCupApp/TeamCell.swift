//
//  TeamCell.swift
//  BGWorldCupApp
//
//  Created by bhavesh on 20/06/21.
//  Copyright © 2021 Bhavesh. All rights reserved.
//

import UIKit

class TeamCell: UITableViewCell {

  // MARK: - IBOutlets
  @IBOutlet weak var teamLabel: UILabel!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var flagImageView: UIImageView!

  // MARK: - View Life Cycle
  override func prepareForReuse() {
    super.prepareForReuse()

    teamLabel.text = nil
    scoreLabel.text = nil
    flagImageView.image = nil
  }
}
