//
//  OrderFooterView.swift
//  ShopClient
//
//  Created by Radyslav Krechet on 1/4/18.
//  Copyright © 2018 Evgeniy Antonov. All rights reserved.
//

import UIKit

protocol OrderFooterViewProtocol: class {
    func viewDidTap(_ section: Int)
}

class OrderFooterView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var itemsLabel: UILabel!
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    
    private var section: Int!
    
    weak var delegate: OrderFooterViewProtocol?
    
    init(section: Int, order: Order) {
        super.init(frame: CGRect.zero)
        
        self.section = section
        commonInit()
        populateViews(order: order)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(String(describing: OrderFooterView.self), owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupViews()
    }
    
    private func setupViews() {
        itemsLabel.text = "Label.Order.Items".localizable
        totalLabel.text = "Label.Order.TotalWithColon".localizable.uppercased()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewDidTap))
        addGestureRecognizer(tap)
    }
    
    private func populateViews(order: Order) {
        let formatter = NumberFormatter.formatter(with: order.currencyCode!)
        let totalPrice = NSDecimalNumber(decimal: order.totalPrice!)
        
        countLabel.text = order.items != nil ? String(order.items!.flatMap { $0.quantity }.reduce(0, +)) : String(0)
        priceLabel.text = formatter.string(from: totalPrice)
    }
    
    func viewDidTap(gestureRecognizer: UIGestureRecognizer) {
        delegate?.viewDidTap(section)
    }
}
