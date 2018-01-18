//
//  SearchViewModel.swift
//  ShopClient
//
//  Created by Evgeniy Antonov on 11/3/17.
//  Copyright © 2017 Evgeniy Antonov. All rights reserved.
//

import RxSwift

class SearchViewModel: GridCollectionViewModel {
    var searchPhrase = Variable<String>("")
    var categories = Variable<[Category]>([Category]())
    
    private let categoryListUseCase = CategoryListUseCase()
    private let productListUseCase = ProductListUseCase()
    
    public func reloadData() {
        paginationValue = nil
        loadRemoteData()
    }
    
    public func loadNextPage() {
        paginationValue = products.value.last?.paginationValue
        loadRemoteData()
    }
    
    public func loadCategories() {
        state.onNext(.loading(showHud: true))
        categoryListUseCase.getCategoryList { [weak self] (catogories, error) in
            if let error = error {
                self?.state.onNext(.error(error: error))
            }
            if let categories = catogories {
                self?.categories.value = categories
                self?.state.onNext(.content)
            }
        }
    }
    
    public func clearResult() {
        products.value.removeAll()
    }
    
    public func categoriesCount() -> Int {
        return categories.value.count
    }
    
    public func category(at index: Int) -> Category {
        return categories.value[index]
    }
    
    // MARK: - private
    private func loadRemoteData() {
        guard !searchPhrase.value.isEmpty else {
            updateProducts(products: [Product]())
            
            return
        }
        
        let showHud = products.value.isEmpty
        state.onNext(.loading(showHud: showHud))
        productListUseCase.getProductList(with: paginationValue, searchPhrase: searchPhrase.value) { [weak self] (products, error) in
            if let error = error {
                self?.state.onNext(.error(error: error))
            }
            if let productsArray = products {
                self?.updateProducts(products: productsArray)
                self?.state.onNext(.content)
            }
            self?.canLoadMore = products?.count ?? 0 == kItemsPerPage
        }
    }
}