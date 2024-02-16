import UIKit
import MapKit
import CoreLocation

class CoffeeMapVC: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate
{
    private var mapView: MKMapView! // Карта для показа местоположения и кофеен
    private var tableView: UITableView! // Таблица для отображения списка кофеен
    private let locationManager = CLLocationManager() // Менеджер геолокации
    private var coffeeShops: [MKMapItem] = [] // Массив для найденных кофеен
    private var currentRouteOverlays: [MKOverlay] = [] // Массив для маршрутов
    
    var timer: Timer?
    var currentDestination = MKMapItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupTableView()
        requestLocationAuthorization()
    }
    
    // MARK: - Настройка карты
    private func setupMap() {
        mapView = MKMapView()
        mapView.delegate = self
        
        view.addSubview(mapView)
        mapView.pinTop(to: view)
        mapView.pinHorizontal(to: view)
        mapView.setHeight(UIScreen.main.bounds.height * Constants.mapViewHeightMult)
        mapView.showsUserLocation = true
    }
    
    // MARK: - Настройка таблицы
    private func setupTableView() {
        tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.tableReuseId)
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        tableView.pinTop(to: mapView.bottomAnchor)
        tableView.pinHorizontal(to: view)
        tableView.pinBottom(to: view)
    }
    
    // MARK: - Запрос разрешения на использование геолокации
    private func requestLocationAuthorization() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Настройка точности определения местоположения
        locationManager.requestAlwaysAuthorization() // Запрос разрешения на постоянное использование геолокации
        locationManager.startUpdatingLocation() // Начало обновления информации о местоположении
    }
    
    // MARK: - Поиск кофеен
    private func searchCoffeeShops(in region: MKCoordinateRegion) {
        // Формируем запрос
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = Constants.requestText
        request.region = region
        let search = MKLocalSearch(request: request)
        
        search.start { [weak self] (response, error) in
            guard let self = self, let response = response else {
                return
            }
            self.coffeeShops = response.mapItems // Сохранение результатов поиска
            self.tableView.reloadData() // Обновление таблицы
            
            mapView.removeAnnotations(mapView.annotations)

            // Добавление аннотаций
            for item in response.mapItems {
                let annotation = CoffeeShopAnnotation(
                    title: item.name ?? Constants.defaultText,
                    coordinate: item.placemark.coordinate,
                    info: Constants.defaultText
                )
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    // MARK: - Маршрут до выбранной кофейни
    private func routeToCoffeeShop(destination: MKMapItem) {
        // Очистка карты
        mapView.removeOverlays(currentRouteOverlays)
        currentRouteOverlays.removeAll()

        updateRoute(destination: destination)
    }
    
    private func updateRoute(destination: MKMapItem) {
        guard let sourceCoordinate = locationManager.location?.coordinate else { return }

        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destination.placemark.coordinate)

        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] (response, error) in
            guard let self = self, let response = response else {
                print("Error")
                return
            }
            
            mapView.removeOverlays(currentRouteOverlays)
            currentRouteOverlays.removeAll()
            
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            self.currentRouteOverlays.append(route.polyline)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let userLocation = location.coordinate
            let regionRadius: CLLocationDistance = Constants.searchLocationRadius
            let region = MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: regionRadius,
                longitudinalMeters: regionRadius
            )
            mapView.setRegion(region, animated: true)
            searchCoffeeShops(in: region)
         
            //locationManager.stopUpdatingLocation()
            
            updateRouteByTimer(in: region)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coffeeShops.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.tableReuseId, for: indexPath)
        let coffeeShop = coffeeShops[indexPath.row]
        cell.textLabel?.text = coffeeShop.name
        cell.textLabel?.textColor = .brown
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCoffeeShop = coffeeShops[indexPath.row]
        currentDestination = selectedCoffeeShop
        routeToCoffeeShop(destination: selectedCoffeeShop)
    }
    
    private func updateRouteByTimer(in region: MKCoordinateRegion) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) {
            [weak self] _ in
            self?.updateRoute(destination: self?.currentDestination ?? MKMapItem()
            )
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = Constants.mapViewRendererLineWidth
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        } else if let cluster = annotation as? MKClusterAnnotation {
            let clusterView = MKAnnotationView(annotation: annotation, reuseIdentifier: Constants.clusterReuseId)
            
            clusterView.annotation = cluster
            
            let customImage = UIImage(named: Constants.clusterImageName)
            let resizedAndRoundedImage = resizeImage(
                image: customImage!,
                targetSize: CGSize(
                    width: Constants.clusterSize,
                    height: Constants.clusterSize
                ),
                backgroundColor: .clear
            )
            clusterView.image = resizedAndRoundedImage
            
            let annotationsCountText = UILabel()
            annotationsCountText.text = cluster.memberAnnotations.count < Constants.clusterAnnotationsMax ?
            "\(cluster.memberAnnotations.count)" :
            Constants.clusterAnnotationsMaxText
            
            annotationsCountText.textColor = .brown
            
            clusterView.addSubview(annotationsCountText)
            annotationsCountText.pinCenter(to: clusterView)
            
            return clusterView
        } else {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: Constants.annotationReuseId)
            
            annotationView.annotation = annotation
            
            let customImage = UIImage(named: Constants.annotationImageName)
            let resizedAndRoundedImage = resizeImage(
                image: customImage!,
                targetSize: CGSize(
                    width: Constants.annotationSize,
                    height: Constants.annotationSize
                ),
                backgroundColor: .clear
            )
            annotationView.image = resizedAndRoundedImage
            
            annotationView.clusteringIdentifier = Constants.annotationClusteringId
            
            return annotationView
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize, backgroundColor: UIColor) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        let rect = CGRect(
            x: Constants.defaultImageRectSize,
            y: Constants.defaultImageRectSize,
            width: newSize.width,
            height: newSize.height
        )

        UIGraphicsBeginImageContextWithOptions(newSize, false, Constants.defaultImageRectSize)
        let context = UIGraphicsGetCurrentContext()!
        context.addEllipse(in: rect)
        context.clip()
        
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
        image.draw(in: rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}
