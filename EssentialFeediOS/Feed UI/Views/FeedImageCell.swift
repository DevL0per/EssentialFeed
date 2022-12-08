//
//  FeedImageCell.swift
//  EssentialFeediOS
//
//  Created by x.one on 6.12.22.
//

import UIKit

final public class FeedImageCell: UITableViewCell {
    public let descriptionLabel = UILabel()
    public let locationLabel = UILabel()
    public let feedImageView = UIImageView()
    public let feedImageContainer = UIView()
    private(set) public lazy var retryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    var onRetry: (()->Void)?
    
    @objc private func retryButtonTapped() {
        onRetry?()
    }
    
}
