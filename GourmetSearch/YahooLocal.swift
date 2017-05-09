//
//  YahooLocal.swift
//  GourmetSearch
//
//  Created by 前川 幸広 on 2017/03/18.
//  Copyright © 2017年 Yukihiro Maekawa. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public extension Notification.Name{
    //読み込み開始
    public static let apiLoadStart = Notification.Name("ApiLoadStart")
    //読み込み完了
    public static let apiLoadComplete = Notification.Name("ApiLoadComplete")
    
}

public struct Shop: CustomStringConvertible{
    public var gid:String? = nil
    public var name:String? = nil
    public var photoUrl:String? = nil
    public var yomi:String? = nil
    public var tel:String? = nil
    public var address:String? = nil
    public var lat:Double? = nil
    public var lon:Double? = nil
    public var catchCopy:String? = nil
    public var hasCoupon:Bool = false
    public var station:String? = nil
    public var description: String{
        get{
            var string = "\nGid: \(gid)\n"
            string += "Name: \(name)\n"
            string += "PhotoUrl: \(photoUrl)\n"
            string += "Yomi: \(yomi)\n"
            string += "Tel: \(tel)\n"
            string += "Address: \(address)\n"
            string += "Lat & Lon: (\(lat), \(lon)) \n"
            string += "CatchCopy: \(catchCopy)\n"
            string += "HasCoupon: \(hasCoupon)\n"
            string += "Station: \(station)\n"
            return string
        }
    }
}

public struct QueryCondition{
    // キーワード
    public var query: String? = nil
    // 店舗ID
    public var gid: String? = nil
    // ソート順
    public enum Sort: String{
        case score = "score"
        case geo = "geo"
    }
    
    public var sort: Sort = .score
    //緯度
    public var lat: Double? = nil
    //経度
    public var lon: Double? = nil
    //距離
    public var dist: Double? = nil
    
    //検索パラメタディクショナリ
    public var queryParams: [String:String]{
        get{
            var params = [String:String]()
            
            //キーワード
            if let unwrapped = query{
                params["query"] = unwrapped
            }
            //店舗ID
            if let unwrapped = gid{
                params["gid"] = unwrapped
            }
            //ソート順
            switch sort{
            case .score:
                params["sort"] = "score"
            case .geo:
                params["sort"] = "geo"
            }
            //経度
            if let unwrapped = lat{
                params["lat"] = "\(unwrapped)"
            }
            //緯度
            if let unwrapped = lon{
                params["lon"] = "\(unwrapped)"
            }
            //距離
            if let unwrapped = dist{
                params["dist"] = "\(unwrapped)"
            }
            
            //デバイス
            params["device"] = "mobile"
            //グルーピング
            params["group"] = "gid"
            //画像があるデータのみ検索する
            params["image"] = "true"
            // 業種コード
            params["gc"] = "01"
            
            return params
        }
    }
}

    public class YahooLocalSearch{
        //Yahoo!ローカルサーチAPIのアプリケーションID
        let apiId = "dj0zaiZpPUpvc01JT0QxdXBVOSZzPWNvbnN1bWVyc2VjcmV0Jng9NDQ-"
        
        //APIのベースURL
        let apiUrl = "http://search.olp.yahooapis.jp/OpenLocalPlatform/V1/localSearch"
        
        //1ページのレコード数
        let perPage = 10
        
        //読み込み済みの店舗
        public var shops = [Shop]()
        
        //trueだと読み込み中
        var loading = false
        
        //全何件
        public var total = 0
        
        //検索条件
        var condition:QueryCondition = QueryCondition(){
            //プロパティオブザーバ：新しい値がセットされた後に読み込み済みの店舗を捨てる
            didSet {
                shops = []
                total = 0
            }
        }
        
        // パラメタなしのイニシャライザ
        public init(){}
        
        // 検索条件をパラメタとして持つイニシャライザ
        public init(condition:QueryCondition){self.condition = condition}
        
        func sortByGid(){
            var newShops = [Shop]()
            
            if let gids = self.condition.gid?.components(separatedBy: ","){
                for gid in gids{
                    let filterd = shops.filter{$0.gid == gid}
                    if filterd.count > 0{
                        newShops.append(filterd[0])
                    }
                }
            }
            
            shops = newShops
        }
        
        // APIからデータを読み込む
        public func loadData(reset:Bool = false){
            //読み込み中の場合は処理しない
            if loading { return }
            
            if reset {
                shops = []
                total = 0
            }
            
            //API実行中
            loading = true
            
            //条件ディクショナリを取得
            var params = condition.queryParams
            
            params["appid"] = apiId
            params["output"] = "json"
            params["start"] = String(shops.count + 1)
            params["results"] = String(perPage)
            
            // API実行開始を通知する
            NotificationCenter.default.post(name:.apiLoadStart,object:nil)
            
            // APIリクエスト
            Alamofire.request(apiUrl , method: .get, parameters: params).response{
                response in
                var json = JSON.null
                
                if response.error == nil && response.data != nil{
                    json = SwiftyJSON.JSON(data :response.data!)
                }
                
                if response.error != nil{
                    //API実行中フラグをOFF
                    self.loading = false
                    var message = "unknown error."
                    if let error = response.error{
                        message = "\(error)"
                    }
                    NotificationCenter.default.post(name:.apiLoadComplete
                        ,object:nil
                        ,userInfo:["error":message]
                    )
                    
                    return
                }
                
                for (_ ,item) in json["Feature"]{
                    var shop = Shop()
                    //店舗ID
                    shop.gid = item["Gid"].string
                    //店舗名
                    shop.name = item["Name"].string?.replacingOccurrences(of: "&#39;", with: "'")
                    //読み
                    shop.yomi = item["Property"]["Yomi"].string
                    //電話
                    shop.tel = item["Property"]["Tel1"].string
                    //住所
                    shop.address = item["Property"]["Address"].string
                    //経度緯度
                    if let geometry = item["Geometry"]["Coordinates"].string{
                        let components = geometry.components(separatedBy: ",")
                        //緯度
                        shop.lat = (components[1] as NSString).doubleValue
                        shop.lon = (components[0] as NSString).doubleValue
                    }
                    
                    //キャッチコピー
                    shop.catchCopy = item["Property"]["CatchCopy"].string
                    //店舗写真
                    shop.photoUrl = item["Property"]["LeadImage"].string
                    //クーポン有無
                    if item["Property"]["CouponFlag"].string == "true"{
                        shop.hasCoupon = true
                    }
                    //駅
                    if let stations  = item["Property"]["Station"].array{
                        //路線名
                        var line = ""
                        if let linestring = stations[0]["Railway"].string{
                            let lines = linestring.components(separatedBy: "/")
                            line = lines[0]
                        }
                        if let station = stations[0]["Name"].string{
                            //駅名と路線名があれば両方入れる
                            shop.station = "\(line)\(station)"
                        }else{
                            shop.station = "\(line)"
                        }
                    }
                    print(shop)
                    
                    self.shops.append(shop)
                }
                
                //総件数
                if let total = json["ResultInfo"]["Total"].int{
                    self.total = total
                }else{
                    self.total = 0
                }
                //API実行中フラグをOFF
                self.loading = false

                //API終了を通知する
                NotificationCenter.default.post(name:.apiLoadComplete,object:nil
                )

            }
        }
        
    }
