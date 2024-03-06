//
//  NativeADView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/14.
//

import Foundation
import Foundation
import SwiftUI
import SnapKit
import GoogleMobileAds

class NativeViewModel: NSObject {
    let ad: NativeADModel?
    let view: UINativeAdView
    init(ad: NativeADModel? = nil, view: UINativeAdView) {
        self.ad = ad
        self.view = view
        self.view.refreshUI(ad: ad?.nativeAd)
    }
    
    static var None:NativeViewModel {
        NativeViewModel(view: UINativeAdView())
    }
    
    static var BigNone: NativeViewModel {
        NativeViewModel(view: UINativeAdView(.big))
    }
}


struct NativeADView: UIViewRepresentable {
    let model: NativeViewModel
    func makeUIView(context: UIViewRepresentableContext<NativeADView>) -> UIView {
        return model.view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<NativeADView>) {
        if let uiView = uiView as? UINativeAdView {
            uiView.refreshUI(ad: model.ad?.nativeAd)
        }
    }
}

class UINativeAdView: GADNativeAdView {
    
    enum Style {
        case small, big
    }

    init(_ style: Style = .small){
        super.init(frame: UIScreen.main.bounds)
        setupUI(style)
        refreshUI(ad: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 暫未圖
    lazy var placeholderView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    lazy var adView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "ad_tag"))
        return image
    }()
    
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .gray
        imageView.layer.cornerRadius = 2
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = UIColor(named: "#525050")
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11.0)
        label.textColor = UIColor(named: "#ACACAC")
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    lazy var installLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.setTitleColor(UIColor.white, for: .normal)
        label.layer.cornerRadius = 20
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor(named: "#F953A0")
        return label
    }()
    
    lazy var bigView: GADMediaView = {
        let bigView = GADMediaView()
        return bigView
    }()
}

extension UINativeAdView {
    func setupUI(_ style: Style) {
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        
        if style == .small {
            placeholderView.image = UIImage(named: "ad_placeholder")
            addSubview(placeholderView)
            placeholderView.snp.makeConstraints { make in
                make.top.left.right.bottom.equalToSuperview()
            }
            
            
            addSubview(iconImageView)
            iconImageView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(14)
                make.left.equalToSuperview().offset(14)
                make.width.height.equalTo(44)
            }
            
            
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(18)
                make.left.equalTo(iconImageView.snp.right).offset(10)
            }

            
            addSubview(adView)
            adView.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.left.equalTo(titleLabel.snp.right).offset(8)
                make.right.equalToSuperview().offset(-14)
                make.width.equalTo(23)
                make.height.equalTo(14)
            }
            
            addSubview(subTitleLabel)
            subTitleLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(8)
                make.left.equalTo(titleLabel)
                make.right.equalToSuperview().offset(-14)
            }

            
            addSubview(installLabel)
            installLabel.snp.makeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(10)
                make.left.equalToSuperview().offset(14)
                make.right.equalToSuperview().offset(-14)
                make.height.equalTo(36)
            }
        } else {
            placeholderView.image = UIImage(named: "ad_placeholder_1")
            addSubview(placeholderView)
            placeholderView.snp.makeConstraints { make in
                make.top.left.right.bottom.equalToSuperview()
            }
            
            addSubview(bigView)
            bigView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(12)
                make.left.equalToSuperview().offset(12)
                make.right.equalToSuperview().offset(-12)
                make.height.equalTo(156)
            }
            
            adView.image = UIImage(named: "ad_tag_1")
            addSubview(adView)
            adView.snp.makeConstraints { make in
                make.top.left.equalTo(bigView)
            }
            
            addSubview(iconImageView)
            iconImageView.snp.makeConstraints { make in
                make.top.equalTo(bigView.snp.bottom).offset(8)
                make.left.equalToSuperview().offset(12)
                make.width.height.equalTo(32)
            }
            
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(bigView.snp.bottom).offset(8)
                make.left.equalTo(iconImageView.snp.right).offset(8)
                make.right.equalToSuperview().offset(-8)
            }
            
            subTitleLabel.numberOfLines = 1
            addSubview(subTitleLabel)
            subTitleLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(3)
                make.left.right.equalTo(titleLabel)
            }
            
            addSubview(installLabel)
            installLabel.snp.makeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(8)
                make.left.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
                make.height.equalTo(36)
            }
        }
        
    }
    
    func refreshUI(ad: GADNativeAd? = nil) {
        self.nativeAd = ad
        guard let ad = self.nativeAd  else {
            self.placeholderView.isHidden = false
            self.hiddenSubviews(hidden: true)
            return
        }
        
        self.placeholderView.isHidden = true
        self.hiddenSubviews(hidden: false)
        
        self.iconView = self.iconImageView
        self.headlineView = self.titleLabel
        self.bodyView = self.subTitleLabel
        self.callToActionView = self.installLabel
        self.mediaView = self.bigView
        
        self.installLabel.setTitle(ad.callToAction, for: .normal)
        self.iconImageView.image = ad.icon?.image
        self.titleLabel.text = ad.headline
        self.subTitleLabel.text = ad.body
        self.bigView.mediaContent = ad.mediaContent
        
    }
    
    func hiddenSubviews(hidden: Bool) {
        self.iconImageView.isHidden = hidden
        self.titleLabel.isHidden = hidden
        self.subTitleLabel.isHidden = hidden
        self.installLabel.isHidden = hidden
        self.adView.isHidden = hidden
    }
}
