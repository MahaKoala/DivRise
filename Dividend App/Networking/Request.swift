//
//  Portfolio.swift
//  Dividend App
//
//  Created by Kevin Li on 12/23/19.
//  Copyright © 2019 Kevin Li. All rights reserved.
//

import Foundation
import Combine

// MARK: AlphaVantage
internal let alphaVantageApiKey = "5QZFJVD3UY66K9CG"
internal let searchCompanyURL = "https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords={query}&apikey={apikey}"

// MARK: FinancialModelingPrep
internal let companyProfileURL = "https://financialmodelingprep.com/api/v3/company/profile/{company}"

struct Request {
    func fetchPortfolioStock(identifier: String, startingDividend: Double) -> AnyPublisher<PortfolioStock, Never> {
        return companyProfile(identifier: identifier)
            .map { PortfolioStock(ticker: $0.symbol, startingDividend: startingDividend, currentDividend: Double($0.profile.lastDiv)!, growth: Double($0.profile.lastDiv)! / startingDividend) }
            .eraseToAnyPublisher()
    }
    
    func getSearchedStocks(query: String) -> AnyPublisher<[SearchStock], Never> {
        Logger.info("getSearchedStocks called with query: \(query)")
        return searchStocks(query: query)
            .map { $0.bestMatches }
            .flatMap { companies -> Publishers.MergeMany<AnyPublisher<SearchStock, Never>> in
                let stocks = companies.map { company -> AnyPublisher<SearchStock, Never> in
                    let ticker = company.symbol
                    let fullName = company.name
                    return self.companyProfile(identifier: ticker)
                        .flatMap { response -> AnyPublisher<SearchStock, Never> in
                            let mktCap = (response.profile.mktCap == "") ? "$--" : Double(response.profile.mktCap)!.shortStringRepresentation
                            let dividend = response.profile.lastDiv
                            return Just(SearchStock(ticker: ticker, fullName: fullName, image: response.profile.image, marketCap: mktCap, dividend: dividend))
                                .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
                }
                return Publishers.MergeMany(stocks)
        }
        .collect()
        .eraseToAnyPublisher()
    }
    
    private func searchStocks(query: String) -> AnyPublisher<SearchStockResponse, Never> {
        let urlString = searchCompanyURL
            .replacingOccurrences(of: "{query}", with: query)
            .replacingOccurrences(of: "{apikey}", with: alphaVantageApiKey)
        
        let url = URL(string: urlString)!
        
        Logger.info(url.absoluteString)
        
        return URLSession.shared
            .dataTaskPublisher(for: URLRequest(url: url))
            .map {
                $0.data.printJSON()
                return $0.data
        }
        .decode(type: SearchStockResponse.self, decoder: Current.decoder)
        .replaceError(with: .noResponse)
        .eraseToAnyPublisher()
    }
    
    private func companyProfile(identifier: String) -> AnyPublisher<CompanyProfileResponse, Never> {
        let urlString = companyProfileURL.replacingOccurrences(of: "{company}", with: identifier)
        let url = URL(string: urlString)!
        
        return URLSession.shared
            .dataTaskPublisher(for: URLRequest(url: url))
            .map {
                $0.data.printJSON()
                return $0.data }
            .decode(type: CompanyProfileResponse.self, decoder: Current.decoder)
            .replaceError(with: .noResponse)
            .eraseToAnyPublisher()
    }
}