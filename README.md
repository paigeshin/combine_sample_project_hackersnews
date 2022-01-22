### Model

```swift
import Foundation

struct Story: Codable {

    let id: Int
    let title: String
    let url: String

}

extension Story {

    static func placeholder() -> Story {
        return Story(id: 0, title: "N/A", url: "")
    }

}
```

### Webservice

```swift
import Foundation
import Combine

class Webservice {

    func getStoryById(storyId: Int) -> AnyPublisher<Story, Error> {

        guard let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(storyId).json?print=pretty") else {
            fatalError("Invalid URL")
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .receive(on: RunLoop.main)
            .map(\.data)
            .decode(type: Story.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    private func mergeStories(ids storyIds: [Int]) -> AnyPublisher<Story, Error> {

        let storyIds = Array(storyIds.prefix(50))

        let initialPublisher = getStoryById(storyId: storyIds[0])
        let remainder = Array(storyIds.dropFirst())

        return remainder.reduce(initialPublisher) { combined, id in
            return combined.merge(with: getStoryById(storyId: id))
            .eraseToAnyPublisher()
        }
    }

    func getAllTopStories() -> AnyPublisher<[Story], Error> {

        guard let url = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty") else {
                   fatalError("Invalid URL")
            }

        return URLSession.shared.dataTaskPublisher(for: url)
            .receive(on: RunLoop.main)
            .map(\.data)
            .decode(type: [Int].self, decoder: JSONDecoder())
            .flatMap { storyIds in
                return self.mergeStories(ids: storyIds)
        }.scan([]) { stories, story -> [Story] in
            return stories + [story]
        }
            .eraseToAnyPublisher()
    }
}
```

### ViewModels

- StoryListViewModel

```swift
import Foundation
import Combine

class StoryListViewModel: ObservableObject {

    @Published var stories = [StoryViewModel]()
    private var cancellable: AnyCancellable?

    init() {
        fetchTopStories()
    }

    private func fetchTopStories() {

        self.cancellable = Webservice().getAllTopStories().map { stories in
            stories.map { StoryViewModel(story: $0) }
        }.sink(receiveCompletion: { _ in }, receiveValue: { storyViewModels in
            self.stories = storyViewModels
        })

    }


}

struct StoryViewModel {

    let story: Story

    var id: Int {
        return self.story.id
    }

    var title: String {
        return self.story.title
    }

    var url: String {
        return self.story.url
    }

}
```

- StoryDetailViewModel

```swift
import Foundation
import Combine

class StoryDetailViewModel: ObservableObject {

    private var cancellable: AnyCancellable?

    @Published private var story = Story.placeholder()

    func fetchStoryDetails(storyId: Int) {
        print("about to make a network request")
        self.cancellable = Webservice().getStoryById(storyId: storyId)
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
```

### WebView

```swift
import Foundation
import SwiftUI
import WebKit

struct Webview: UIViewRepresentable {

    var url: String

    func makeUIView(context: Context) -> WKWebView {
        guard let url = URL(string: self.url) else {
            return WKWebView.pageNotFoundView()
        }

        let request = URLRequest(url: url)

        let wkWebView = WKWebView()
        wkWebView.load(request)
        return wkWebView
    }

    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<Webview>) {

        guard let url = URL(string: self.url) else {
            return
        }

        let request = URLRequest(url: url)
        uiView.load(request)

    }

}
```

### Views

- StoryListView

```swift
import SwiftUI

struct StoryListView: View {

    @ObservedObject private var storyListVM = StoryListViewModel()

    var body: some View {
        NavigationView {

            List(self.storyListVM.stories, id: \.id) { storyVM in
                NavigationLink(destination: StoryDetailView(storyId: storyVM.id)) {
                    Text("\(storyVM.title)")
                }
            }

        .navigationBarTitle("Hacker News")
        }
    }
}

struct StoryListView_Previews: PreviewProvider {
    static var previews: some View {
        StoryListView()
    }
}
```

- StoryDetailView

```swift
import SwiftUI

struct StoryDetailView: View {

    @ObservedObject private var storyDetailVM: StoryDetailViewModel
    var storyId: Int

    init(storyId: Int) {
        self.storyId = storyId
        self.storyDetailVM = StoryDetailViewModel()
    }

    var body: some View {
        VStack {
            Text(self.storyDetailVM.title)
            Webview(url: self.storyDetailVM.url)
        }.onAppear {
            self.storyDetailVM.fetchStoryDetails(storyId: self.storyId)
        }
    }
}

struct StoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        StoryDetailView(storyId: 8863)
    }
}
```
