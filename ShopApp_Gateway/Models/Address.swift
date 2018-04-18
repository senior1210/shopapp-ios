//
//  Address.swift
//  ShopApp_Gateway
//
//  Created by Evgeniy Antonov on 11/24/17.
//  Copyright © 2017 Evgeniy Antonov. All rights reserved.
//

import Foundation

public class Address {
    public var id = ""
    public var firstName: String?
    public var lastName: String?
    public var address: String?
    public var secondAddress: String?
    public var city: String?
    public var country: Country?
    public var state: State?
    public var zip: String?
    public var phone: String?

    public init() {}
}
