//
//  Constants.swift
//  CoffeeMap
//
//  Created by Данила Рахманов on 15.02.2024.
//

import Foundation

enum Constants {
    
    // MARK: - MapView constants
    static let mapViewHeightMult: CGFloat = 0.7
    static let mapViewRendererLineWidth: CGFloat = 4.0
    
    static let searchLocationRadius: CGFloat = 1000
    
    // MARK: - Annotations/Clusters constants
    static let clusterReuseId: String = "clusterView"
    static let clusterImageName: String = "cluster"
    static let clusterSize: CGFloat = 50
    static let clusterAnnotationsMax: Int = 100
    static let clusterAnnotationsMaxText: String = "99+"
    
    static let annotationReuseId: String = "annotationView"
    static let annotationImageName: String = "cup"
    static let annotationSize: CGFloat = 35
    
    static let annotationClusteringId: String = "mapItemClustered"
    
    static let defaultImageRectSize: CGFloat = 0
    
    // MARK: - Map request constants
    static let requestText: String = "coffee"
    static let defaultText: String = ""
    
    static let defaultRequestIndex: Int = 0
    
    // MARK: - TableView constants
    static let tableReuseId: String = "cell"
}
