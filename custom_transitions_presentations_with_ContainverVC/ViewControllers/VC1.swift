//
//  VC1.swift
//  custom_vc_transitions
//
//  Created by Mikael Hanna on 2022-11-08.
//

import UIKit

class VC1: UIViewController {
    
    var lbl: UILabel!
    var backgroundColor: UIColor
    
    init(title: String, color: UIColor) {
        self.backgroundColor = color
        
        super.init(nibName: nil, bundle: nil)

        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        //super.loadView()
        self.view = .init(frame: .zero)
        lbl = UILabel()
        self.view.addSubview(lbl)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = self.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        
        lbl.font = UIFont(name: "Thonburi-Bold", size: 25)
        lbl.text = self.title
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setupConstraints()
    }
    
    private func setupConstraints() -> Void {

        lbl.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        lbl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    }
    
    deinit {
        print("\(String(describing: VC1.self)) deallocated")
    }
}
