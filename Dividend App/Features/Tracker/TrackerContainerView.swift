//
//  TrackerContainerView.swift
//  Dividend App
//
//  Created by Kevin Li on 12/26/19.
//  Copyright © 2019 Kevin Li. All rights reserved.
//

import SwiftUI

struct TrackerContainerView: View {
    @EnvironmentObject var store: Store<AppState, AppAction>
    
    @State private var dividendInput = ""
    @State private var showingAdd = false
    
    @Binding var show: Bool
    
    private var monthlyRecords: [Record] {
        store.state.allMonthlyRecords
    }
    
    private var monthlyDividends: [Double] {
        store.state.allMonthlyDividends
    }
    
    var body: some View {
        NavigationView {
            TrackerView(monthlyRecords: monthlyRecords, monthlyDividends: monthlyDividends)
                .navigationBarItems(
                    leading: Button(action: {
                        self.showingAdd = true
                    }) {
                        Image(systemName: "plus")
                        .resizable()
                        .frame(width: 20, height: 20)
                    },
                    trailing: Button(action: {
                        self.show = false
                    }) {
                        Image(systemName: "x.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
            )
                .sheet(isPresented: $showingAdd, onDismiss: { self.dividendInput = "" }) {
                    AddDividendView(input: self.$dividendInput, onAdd: self.addMonthlyDividend)
            }
            .navigationBarTitle(Text("Dividend Tracker"))
        }
        
    }
    
    private func addMonthlyDividend() {
        if let dividend = Double(dividendInput), dividend > 0 {
            showingAdd = false
            store.send(updateMonthlyDividends(dividend: dividend))
        }
    }
}

struct TrackerContainerView_Previews: PreviewProvider {
    static var previews: some View {
        var appState = AppState()
        appState.allMonthlyRecords = []
        appState.allMonthlyDividends = []
        
        return TrackerContainerView(show: .constant(true)).environmentObject(Store<AppState, AppAction>(initialState: appState, reducer: appReducer))
    }
}
