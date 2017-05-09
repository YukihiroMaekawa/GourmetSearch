//
//  ViewController.swift
//  GourmetSearch
//
//  Created by 前川 幸広 on 2017/03/18.
//  Copyright © 2017年 Yukihiro Maekawa. All rights reserved.
//

import UIKit

class ShopListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    var yls:YahooLocalSearch = YahooLocalSearch()
    var loadDataObserver : NSObjectProtocol?
    var refreshObserver: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //pull to Refreshコントロール初期化
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ShopListViewController.onRefresh(_:)), for: .valueChanged)
        self.tableView.addSubview(refreshControl)
        
        /*
        var qc = QueryCondition()
        qc.query = "和民"
        yls = YahooLocalSearch(condition:qc)
        */
        
        //読み込み完了通知を受信した時の処理
        loadDataObserver = NotificationCenter.default.addObserver(forName: .apiLoadComplete
            , object: nil
            , queue: nil
            , using: { (Notification) in
                
                if self.yls.condition.gid != nil{
                    self.yls.sortByGid()
                }
                
                self.tableView.reloadData()
                
                if Notification.userInfo != nil{
                    if let userInfo = Notification.userInfo as? [String:String?]{
                        if userInfo["error"] != nil{
                            let alertView = UIAlertController(title: "通信エラー", message: "通信エラーが発生しました。", preferredStyle: .alert)
                            
                            alertView.addAction(UIAlertAction(title:"OK",style:.default){
                                action in return
                            })
                            self.present(alertView,animated:true,completion: nil)
                        }
                    }
                }
        })
        
        if yls.shops.count == 0{
            if self.navigationController is FavoriteNavigationController{
                loadFavorites()
                
                self.navigationItem.title = "お気に入り"
            }else{
                yls.loadData(reset: true)
                self.navigationItem.title = "店舗一覧"
            }
        }
    }
    
    func loadFavorites(){
        Favorite.load()
        if Favorite.favorites.count > 0{
            var condition = QueryCondition()
            condition.gid = Favorite.favorites.joined(separator: ",")
            
            yls.condition = condition
            yls.loadData(reset: true)
        }else{
            NotificationCenter.default.post(name:.apiLoadComplete,object:nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self.loadDataObserver!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !(self.navigationController is FavoriteNavigationController){
            self.navigationItem.rightBarButtonItem = nil
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onRefresh(_ refreshContlol : UIRefreshControl){
        //UIRefreshControlを読み込み中状態へ
        refreshContlol.beginRefreshing()
        //終了通知を受信したらUIRefleshControlを受信する
        refreshObserver = NotificationCenter.default.addObserver(forName: .apiLoadComplete, object: nil, queue: nil, using: {
            Notification in
            //通知の待受を終了
            NotificationCenter.default.removeObserver(self.refreshObserver!)
            //UITefreshControlを停止する
            refreshContlol.endRefreshing()
        })
        
        if self.navigationController is FavoriteNavigationController{
            loadFavorites()
        }else{
            // 再取得
            yls.loadData(reset: true)
        }
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //セルの選択状態を解除する
        tableView.deselectRow(at: indexPath, animated: true)
        //Sequeを実]]行
        performSegue(withIdentifier:"PushShopDetail",sender:indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue ,sender: Any?){
        if segue.identifier == "PushShopDetail"{
            let vc = segue.destination as! ShopDetailViewController
            if let indexPath = sender as? IndexPath{
                vc.shop = yls.shops[indexPath.row]
            }
        }
    }

    //MARK: --UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            //セルの数は店舗数
            return yls.shops.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0{
            if indexPath.row < yls.shops.count{
                //rowが店舗数以下なら店舗セルを返す
                let cell = tableView.dequeueReusableCell(withIdentifier: "ShopListItem") as!ShopListItemTableViewCell
                cell.shop = yls.shops[indexPath.row]
                
                //残りがあり、現在の列の下の店舗数が３以下になったら追加取得
                if yls.shops.count < yls.total{
                    if yls.shops.count - indexPath.row <= 4 {
                        yls.loadData()
                    }
                }
                
                return cell
                
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.navigationController is FavoriteNavigationController
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        //削除
        if editingStyle == .delete{
            guard let gid = yls.shops[indexPath.row].gid else{return}
            Favorite.remove(gid)
            yls.shops.remove(at:indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return self.navigationController is FavoriteNavigationController
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath == destinationIndexPath { return}
        
        let source = yls.shops[sourceIndexPath.row]
        yls.shops.remove(at:sourceIndexPath.row)
        yls.shops.insert(source,at:destinationIndexPath.row)
        
        Favorite.move(sourceIndexPath.row,to:destinationIndexPath.row)
        
    }
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if tableView.isEditing{
            tableView.setEditing(false, animated: true)
            sender.title = "編集"
        }else{
            tableView.setEditing(true, animated: true)
            sender.title = "完了"
        }
    }
}

