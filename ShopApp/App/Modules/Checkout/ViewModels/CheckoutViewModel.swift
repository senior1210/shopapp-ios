//
//  CheckoutViewModel.swift
//  ShopApp
//
//  Created by Evgeniy Antonov on 12/20/17.
//  Copyright © 2017 Evgeniy Antonov. All rights reserved.
//

import PassKit

import RxSwift
import ShopApp_Gateway

enum CheckoutSection: Int {
    case cart
    case customerEmail
    case shippingAddress
    case payment
    case shippingOptions
    
    static let allValues = [cart, customerEmail, shippingAddress, payment, shippingOptions]
    static let valuesWithoutShippingOptions = [cart, customerEmail, shippingAddress, payment]
}

enum PaymentType: Int {
    case creditCard
    case applePay
    
    static let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex]
    static let allValues = PKPaymentAuthorizationController.canMakePayments() && PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) ? [creditCard, applePay] : [creditCard]
}

class CheckoutViewModel: BaseViewModel {
    private let checkoutUseCase: CheckoutUseCase
    private let cartProductListUseCase: CartProductListUseCase
    private let deleteCartProductsUseCase: DeleteCartProductsUseCase
    private let customerUseCase: CustomerUseCase
    private let loginUseCase: LoginUseCase
    
    var checkout = Variable<Checkout?>(nil)
    var creditCard = Variable<CreditCard?>(nil)
    var billingAddress = Variable<Address?>(nil)
    var selectedType = Variable<PaymentType?>(nil)
    var cartItems = Variable<[CartProduct]>([])
    var customerLogged = Variable<Bool>(false)
    var checkoutSucceeded = PublishSubject<Bool>()
    var customerHasEmail = PublishSubject<Bool>()
    var customerEmail = Variable<String>("")
    var order: Order?
    var selectedProductVariant: ProductVariant!
    
    var placeOrderPressed: AnyObserver<Void> {
        return AnyObserver { [weak self] event in
            switch event {
            case .next:
                guard let strongSelf = self else {
                    return
                }
                strongSelf.placeOrderAction()
            default:
                break
            }
        }
    }
    var isCheckoutValid: Observable<Bool> {
        return Observable.combineLatest(selectedType.asObservable(), checkout.asObservable(), creditCard.asObservable(), billingAddress.asObservable(), customerEmail.asObservable()) { (type, checkout, card, address, customerEmail) in
            let applePayCondition = type == .applePay && customerEmail.isValidAsEmail()
            let creditCardCondition = type == .creditCard && checkout != nil && card != nil && address != nil && checkout?.shippingLine != nil && customerEmail.isValidAsEmail()
            return applePayCondition || creditCardCondition
        }
    }

    init(checkoutUseCase: CheckoutUseCase, cartProductListUseCase: CartProductListUseCase, deleteCartProductsUseCase: DeleteCartProductsUseCase, customerUseCase: CustomerUseCase, loginUseCase: LoginUseCase) {
        self.checkoutUseCase = checkoutUseCase
        self.cartProductListUseCase = cartProductListUseCase
        self.deleteCartProductsUseCase = deleteCartProductsUseCase
        self.customerUseCase = customerUseCase
        self.loginUseCase = loginUseCase
    }
    
    func loadData() {
        state.onNext(ViewState.make.loading())
        loginUseCase.getLoginStatus { [weak self] (isLogged) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.customerLogged.value = isLogged
            strongSelf.getCartItems()
        }
    }
    
    func getCheckout() {
        guard let checkoutId = checkout.value?.id else {
            return
        }
        state.onNext(ViewState.make.loading(isTranslucent: true))
        checkoutUseCase.getCheckout(with: checkoutId) { [weak self] (result, error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                strongSelf.state.onNext(.error(error: error))
            } else if let checkout = result {
                strongSelf.checkout.value = checkout
                strongSelf.state.onNext(.content)
            }
        }
    }
    
    func updateCheckoutShippingAddress(with address: Address) {
        state.onNext(ViewState.make.loading())
        let checkoutId = checkout.value?.id ?? ""
        checkoutUseCase.updateCheckoutShippingAddress(with: checkoutId, address: address) { [weak self] (success, error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                strongSelf.state.onNext(.error(error: error))
            } else if let success = success, success == true {
                strongSelf.getCheckout()
            } else {
                strongSelf.state.onNext(.error(error: RepoError()))
            }
        }
    }
    
    func productVariant(with productVariantId: String) -> ProductVariant? {
        var variant: ProductVariant?
        
        cartItems.value.forEach {
            if let productVariant = $0.productVariant, productVariant.id == productVariantId {
                variant = productVariant
            }
        }
        
        return variant
    }
    
    func updateShippingRate(with rate: ShippingRate) {
        if let checkoutId = checkout.value?.id {
            state.onNext(ViewState.make.loading(isTranslucent: true))
            checkoutUseCase.updateShippingRate(with: checkoutId, rate: rate, callback: { [weak self] (result, error) in
                guard let strongSelf = self else {
                    return
                }
                if let error = error {
                    strongSelf.state.onNext(.error(error: error))
                } else if let checkout = result {
                    strongSelf.checkout.value = checkout
                    strongSelf.state.onNext(.content)
                }
            })
        }
    }
    
    func placeOrderAction() {
        switch selectedType.value! {
        case PaymentType.creditCard:
            payByCreditCard()
        case PaymentType.applePay:
            payByApplePay()
        }
    }
    
    private func getCartItems() {
        cartProductListUseCase.getCartProductList({ [weak self] (result, error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                strongSelf.state.onNext(.error(error: error))
            } else if let cartItems = result {
                strongSelf.cartItems.value = cartItems
                strongSelf.createCheckout(cartItems: cartItems)
            }
        })
    }
    
    private func createCheckout(cartItems: [CartProduct]) {
        checkoutUseCase.createCheckout(cartProducts: cartItems, callback: { [weak self] (checkout, error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                strongSelf.state.onNext(.error(error: error))
            } else if let checkout = checkout {
                strongSelf.checkout.value = checkout
                strongSelf.getCustomer()
            }
        })
    }
    
    private func getCustomer() {
        customerUseCase.getCustomer { [weak self] (customer, _) in
            guard let strongSelf = self else {
                return
            }
            if let email = customer?.email {
                strongSelf.customerHasEmail.onNext(true)
                strongSelf.customerEmail.value = email
            }
            if let address = customer?.defaultAddress {
                strongSelf.updateCheckoutShippingAddress(with: address)
            } else {
                strongSelf.state.onNext(.content)
            }
        }
    }
    
    private func payByCreditCard() {
        if let checkout = checkout.value, let card = creditCard.value, let billingAddress = billingAddress.value {
            state.onNext(ViewState.make.loading(isTranslucent: true))
            checkoutUseCase.pay(with: card, checkout: checkout, billingAddress: billingAddress, customerEmail: customerEmail.value, callback: paymentCallback())
        }
    }
    
    private func payByApplePay() {
        if let checkout = checkout.value {
            state.onNext(ViewState.make.loading(isTranslucent: true))
            checkoutUseCase.setupApplePay(with: checkout, customerEmail: customerEmail.value, callback: paymentCallback())
        }
    }
    
    private func paymentCallback() -> RepoCallback<Order> {
        return { [weak self] (response, error) in
            guard let strongSelf = self else {
                return
            }
            if let order = response {
                strongSelf.clearCart(with: order)
            } else if error != nil {
                strongSelf.checkoutSucceeded.onNext(false)
                strongSelf.state.onNext(.content)
            } else {
                strongSelf.state.onNext(.content)
            }
        }
    }
    
    private func clearCart(with order: Order) {
        deleteCartProductsUseCase.clearCart { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.order = order
            strongSelf.checkoutSucceeded.onNext(true)
            strongSelf.state.onNext(.content)
        }
    }
}
