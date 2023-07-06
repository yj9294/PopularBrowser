//
//  NativeADView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/14.
//

import Foundation
import Foundation
import SwiftUI
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

    init(){
        super.init(frame: UIScreen.main.bounds)
        setupUI()
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
        label.textColor = .white
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11.0)
        label.textColor = .white
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
        return label
    }()
}

extension UINativeAdView {
    func setupUI() {
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        
        addSubview(placeholderView)
        placeholderView.frame = self.bounds
        
        
        addSubview(iconImageView)
        iconImageView.frame = CGRectMake(14, 14, 44, 44)
        
        
        addSubview(titleLabel)
        let width = self.bounds.size.width - iconImageView.frame.maxX - 8 - 23 - 16
        titleLabel.frame = CGRectMake(iconImageView.frame.maxX + 8, 18, width, 15)

        
        addSubview(adView)
        adView.frame = CGRectMake(titleLabel.frame.maxX + 8, 18, 23, 14)
        
        addSubview(subTitleLabel)
        let w = self.bounds.size.width - iconImageView.frame.maxX - 8 - 16
        subTitleLabel.frame = CGRectMake(titleLabel.frame.minX, titleLabel.frame.maxY + 8, w, 14)

        
        addSubview(installLabel)
        let x = self.bounds.width - 14 - 14
        installLabel.frame = CGRectMake(14, iconImageView.frame.maxY + 10, x, 36)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupUI()
    }
    
    func refreshUI(ad: GADNativeAd? = nil) {
        self.nativeAd = ad
        placeholderView.image = UIImage(named: "ad_placeholder")
        let bgColor = UIColor(named: "#FFF1EE")
        self.backgroundColor = ad == nil ? .clear : bgColor
        self.adView.image = UIImage(named: "ad_tag")
        self.installLabel.setTitleColor(.white, for: .normal)
        self.installLabel.backgroundColor = UIColor(named: "#F953A0")
        self.subTitleLabel.textColor = UIColor(named: "#ACACAC")
        self.titleLabel.textColor = UIColor(named: "#525050")
        
        self.iconView = self.iconImageView
        self.headlineView = self.titleLabel
        self.bodyView = self.subTitleLabel
        self.callToActionView = self.installLabel
        self.installLabel.setTitle(ad?.callToAction, for: .normal)
        self.iconImageView.image = ad?.icon?.image
        self.titleLabel.text = ad?.headline
        self.subTitleLabel.text = ad?.body
        
        self.hiddenSubviews(hidden: self.nativeAd == nil)
        
        if ad == nil {
            self.placeholderView.isHidden = false
        } else {
            self.placeholderView.isHidden = true
        }
    }
    
    func hiddenSubviews(hidden: Bool) {
        self.iconImageView.isHidden = hidden
        self.titleLabel.isHidden = hidden
        self.subTitleLabel.isHidden = hidden
        self.installLabel.isHidden = hidden
        self.adView.isHidden = hidden
    }
}
