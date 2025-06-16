//
//  ContentView.swift
//  Force Graph
//
//  Created by Clément Maubon on 15/06/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        GraphView(store: .sample())
    }
}

#Preview {
    ContentView()
}
