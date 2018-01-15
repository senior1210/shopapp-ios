//
//  OrderHeaderView.swift
//  ShopClient
//
//  Created by Radyslav Krechet on 1/4/18.
//  Copyright © 2018 Evgeniy Antonov. All rights reserved.
//

import UIKit

protocol OrderHeaderViewProtocol: class {
    func viewDidTap(_ section: Int)
}

class OrderHeaderView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    private var section: Int!
    
    weak var delegate: OrderHeaderViewProtocol?

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
        Bundle.main.loadNibNamed(String(describing: OrderHeaderView.self), owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupViews()
    }
    
    private func setupViews() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewDidTap))
        addGestureRecognizer(tap)
    }
    
    private func populateViews(order: Order) {
        let numberFormat = "Label.Order.Number".localizable.uppercased()
        numberLabel.text = String(format: numberFormat, String(order.number!))
        let dateFormat = "Label.Order.Date".localizable
        dateLabel.text = String(format: dateFormat, order.createdAt!.longDescription)
    }
    
    func viewDidTap(gestureRecognizer: UIGestureRecognizer) {
        delegate?.viewDidTap(section)
    }
}
