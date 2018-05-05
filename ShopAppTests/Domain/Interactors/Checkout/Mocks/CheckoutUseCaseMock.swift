//
//  CheckoutUseCaseMock.swift
//  ShopAppTests
//
//  Created by Evgeniy Antonov on 5/4/18.
//  Copyright © 2018 RubyGarage. All rights reserved.
//

import ShopApp_Gateway

@testable import ShopApp

class CheckoutUseCaseMock: CheckoutUseCase {
    var isNeedToReturnError = false
    
    override func getCheckout(with checkoutId: String, callback: @escaping RepoCallback<Checkout>) {
        // TODO:
    }
    
    override func updateCheckoutShippingAddress(with checkoutId: String, address: Address, callback: @escaping RepoCallback<Bool>) {
        isNeedToReturnError ? callback(false, RepoError()) : callback(true, nil)
    }
    
    override func createCheckout(cartProducts: [CartProduct], callback: @escaping RepoCallback<Checkout>) {
        // TODO:
    }
    
    override func pay(with card: CreditCard, checkout: Checkout, billingAddress: Address, customerEmail: String, callback: @escaping RepoCallback<Order>) {
        // TODO:
    }
    
    override func setupApplePay(with checkout: Checkout, customerEmail: String, callback: @escaping RepoCallback<Order>) {
        // TODO:
    }
    
    override func updateShippingRate(with checkoutId: String, rate: ShippingRate, callback: @escaping RepoCallback<Checkout>) {
        // TODO:
    }
}
