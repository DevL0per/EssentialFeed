//
//  FeedImageView.swift
//  EssentialFeed
//
//  Created by x.one on 6.01.23.
//

import Foundation

public protocol FeedImageView {
    associatedtype Image
    
    func display(_ viewModel: FeedImageViewModel<Image>)
}
