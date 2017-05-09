//
//  ShopDetailViewController.swift
//  GourmetSearch
//
//  Created by 前川 幸広 on 2017/03/29.
//  Copyright © 2017年 Yukihiro Maekawa. All rights reserved.
//

import UIKit
import MapKit

class ShopDetailViewController: UIViewController ,UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var nameHeight: NSLayoutConstraint!
    @IBOutlet weak var tel: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var addressContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var favoritelcon: UIImageView!
    @IBOutlet weak var favoriteLabel: UILabel!
    
    var shop = Shop()
    
    @IBAction func telTapped(_ sender: UIButton) {
    }

    @IBAction func addressTapped(_ sender: UIButton) {
    }
    
    @IBAction func favoriteTapped(_ sender: UIButton) {
        guard let gid = shop.gid else{return}
        
        Favorite.toggle(gid)
        updateFavoriteButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateFavoriteButton()
        
        //写真
        if let url = shop.photoUrl{
            photo.sd_setImage(with: URL(string:url), placeholderImage: UIImage(named:"loading"))
        }else{
            photo.image = UIImage(named:"loading")
        }
        
        //店舗名
        name.text = shop.name
        //電話番号
        tel.text = shop.tel
        //住所
        address.text = shop.address
        // Do any additional setup after loading the view.
    }
    
    func updateFavoriteButton(){
        guard let gid = shop.gid else{return}
        
        if Favorite.inFavorites(gid){
            favoritelcon.image = UIImage(named:"star-on")
            //favoritelcon.image = UIImage(named:"#imageLiteral(resourceName: "stat-on")")
            favoriteLabel.text = "お気に入りから外す"
        }else{
            favoritelcon.image = UIImage(named:"star-off")
            favoriteLabel.text = "お気に入りに入れる"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        let nameFrame = name.sizeThatFits(CGSize(width:name.frame.size.width,height:CGFloat.greatestFiniteMagnitude))
        nameHeight.constant = nameFrame.height
        
        let addressFrame = address.sizeThatFits(CGSize(width:address.frame.size.width,height:CGFloat.greatestFiniteMagnitude))
        addressContainerHeight.constant = addressFrame.height
        
        view.layoutIfNeeded()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.scrollView.delegate = self
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.scrollView.delegate = nil
        super.viewWillDisappear(animated)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y+scrollView.contentInset.top
        if scrollOffset <= 0{
            photo.frame.origin.y = scrollOffset
            photo.frame.size.height = 200 - scrollOffset
        }
    }
}
