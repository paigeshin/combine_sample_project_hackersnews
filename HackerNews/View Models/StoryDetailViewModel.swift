//
//  StoryDetailViewModel.swift
//  HackerNews
//
//  Created by Mohammad Azam on 10/23/19.
//  Copyright © 2019 Mohammad Azam. All rights reserved.
//

import Foundation
import Combine

class StoryDetailViewModel: ObservableObject {
    
    var storyId: Int
    private var cancellable: AnyCancellable?
    
    @Published private var story: Story!
    
    init(storyId: Int) {
        
        self.storyId = storyId
        
        self.cancellable = Webservice().getStoryById(storyId: self.storyId)
            .catch { _ in Just(Story.placeholder()) }
            .sink(receiveCompletion: { _ in }, receiveValue: { story in
                self.story = story
            })
    }
}

extension StoryDetailViewModel {
    
    var title: String {
        
        return self.story.title
    }
    
    var url: String {
        return self.story.url
    }
    
}
