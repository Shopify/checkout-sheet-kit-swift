//
//  SelectableCell.swift
//  Storefront
//
//  Created by Shopify.
//  Copyright (c) 2017 Shopify Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

protocol Selectable: AnyObject {
    
    var highlightView: UIView { get }
}

extension Selectable {
    
    func applyHighlightIn(view: UIView) {
        self.highlightView.frame           = view.bounds
        self.highlightView.backgroundColor = view.tintColor.withAlphaComponent(0.04)
        view.addSubview(self.highlightView)
    }
    
    func removeHighlight() {
        self.highlightView.removeFromSuperview()
    }
}

class SelectableCollectionCell: UICollectionViewCell, Selectable {
    
    lazy var highlightView = UIView()
    
    override var isHighlighted: Bool {
        willSet(highlighted) {
            
            if highlighted {
                self.applyHighlightIn(view: self.contentView)
            } else {
                self.removeHighlight()
            }
        }
    }
}

class SelectableTableCell: UITableViewCell, Selectable {
    
    lazy var highlightView = UIView()
    
    override var isHighlighted: Bool {
        willSet(highlighted) {
            
            if highlighted {
                self.applyHighlightIn(view: self.contentView)
            } else {
                self.removeHighlight()
            }
        }
    }
}
