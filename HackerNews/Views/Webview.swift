//
//  Webview.swift
//  HackerNews
//
//  Created by Mohammad Azam on 10/23/19.
//  Copyright © 2019 Mohammad Azam. All rights reserved.
//

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
