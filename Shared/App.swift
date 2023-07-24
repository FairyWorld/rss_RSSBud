//
//  App.swift
//  Shared
//
//  Created by Cay Zhang on 2020/7/5.
//

import SwiftUI
import BackgroundTasks

extension RSSBud {
    
    @main
    struct App: SwiftUI.App {
        
        @StateObject var contentViewModel = ContentView.ViewModel()
        
        @State var xCallbackContext: XCallbackContext = nil
        
        init() {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: RuleManager.shared.remoteRulesFetchTaskIdentifier, using: nil) { task in
                print("Running task...")
                RuleManager.shared.fetchRemoteRules(withAppRefreshTask: task as? BGAppRefreshTask)
                RuleManager.shared.scheduleRemoteRulesFetchTask()
            }
            RuleManager.shared.scheduleRemoteRulesFetchTask()
            
            RuleManager.shared.fetchRemoteRulesIfNeeded()
            
            // temp workaround for list background
            UITableView.appearance().backgroundColor = UIColor.clear
            
            #if DEBUG
            // prepare for promo asset generation
            let pageIndex = UserDefaults.standard.integer(forKey: "promo-asset-generation")
            if pageIndex != 0 {
                prepareForPromoAssetGeneration(pageIndex: pageIndex)
            }
            #endif
        }
        
        var body: some Scene {
            WindowGroup {
                ContentView(viewModel: contentViewModel)
                    .onOpenURL { url in
                        guard let url = url.components else { return }
                        print("Open url: \(url)")
                        if url.path.lowercased().starts(with: "/analyze") {
                            if let urlToAnalyze = url.queryItems?["url"].flatMap(URLComponents.init(string:)) {
                                withAnimation {
                                    xCallbackContext = url.queryItems.map(XCallbackContext.init) ?? nil
                                    contentViewModel.process(url: urlToAnalyze)
                                }
                            }
                        }
                    }.environment(\.xCallbackContext, $xCallbackContext)
                    .modifier(CustomOpenURLModifier { url in
                        UIApplication.shared.open(url)
                    })
            }
        }
    }
    
}

#if DEBUG
extension RSSBud.App {
    mutating func prepareForPromoAssetGeneration(pageIndex: Int) {
        if pageIndex == 1 {
            AppStorage<Bool?>("isOnboarding", store: RSSBud.userDefaults).wrappedValue = false
        } else if pageIndex == 2 {
            AppStorage<Bool?>("isOnboarding", store: RSSBud.userDefaults).wrappedValue = false
            Integration().wrappedValue = [.systemDefaultReader]
            
            let contentViewModel = ContentView.ViewModel()
            contentViewModel.process(url: "https://github.com/Cay-Zhang/RSSBud")
            
            self._contentViewModel = StateObject(wrappedValue: contentViewModel)
        } else if pageIndex == 3 {
            AppStorage<Bool?>("isOnboarding", store: RSSBud.userDefaults).wrappedValue = false
            Integration().wrappedValue = [.systemDefaultReader]
            
            let contentViewModel = ContentView.ViewModel(
                originalURL: "https://github.com/Cay-Zhang/RSSBud",
                rssFeeds: [
                    RSSFeed(url: "https://github.com/Cay-Zhang/RSSBud/releases.atom", title: "Repo Releases", imageURL: "", isCertain: true),
                    RSSFeed(url: "https://github.com/Cay-Zhang/RSSBud/commits.atom", title: "Repo Commits", imageURL: "", isCertain: true),
                ],
                rsshubFeeds: [
                    RSSHubFeed(title: "Repo Issues", path: "/github/issue/Cay-Zhang/RSSBud", docsURL: ""),
                    RSSHubFeed(title: "Repo Pull Requests", path: "/github/pull/Cay-Zhang/RSSBud", docsURL: "")
                ],
                queryItems: [
                    URLQueryItem(name: "filter_title", value: ""),
                    URLQueryItem(name: "mode", value: "fulltext"),
                    URLQueryItem(name: "limit", value: "10"),
                ]
            )
            contentViewModel.process(url: "https://github.com/Cay-Zhang/RSSBud")
            contentViewModel.pageFeedSectionViewModel.isExpanded = false
            contentViewModel.rsshubFeedSectionViewModel.isExpanded = false
            
            self._contentViewModel = StateObject(wrappedValue: contentViewModel)
        } else if pageIndex == 4 {
            AppStorage<Bool?>("isOnboarding", store: RSSBud.userDefaults).wrappedValue = false
            RSSHub.BaseURL().string = RSSHub.officialDemoBaseURLString
            @AppStorage<CustomOpenURLAction.Mode>("defaultOpenURLMode", store: RSSBud.userDefaults) var defaultMode = .inApp
            defaultMode = .inApp
            let _lastRemoteRulesFetchDate = AppStorage<Double?>("lastRSSHubRadarRemoteRulesFetchDate", store: RSSBud.userDefaults)
            _lastRemoteRulesFetchDate.wrappedValue = Date(timeIntervalSinceNow: -60 * 5 + 6.5).timeIntervalSinceReferenceDate
        }
    }
}
#endif
