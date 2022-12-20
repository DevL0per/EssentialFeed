//
//  FeedImageCell.swift
//  EssentialFeediOS
//
//  Created by x.one on 6.12.22.
//

import UIKit

final public class FeedImageCell: UITableViewCell {
    @IBOutlet public var descriptionLabel: UILabel!
    @IBOutlet public var locationLabel: UILabel!
    @IBOutlet public var feedImageView: UIImageView!
    @IBOutlet public var feedImageContainer: UIView!
    @IBOutlet public var retryButton: UIButton!
    var onRetry: (()->Void)?
    
    @IBAction private func retryButtonTapped() {
        onRetry?()
    }
    
}
