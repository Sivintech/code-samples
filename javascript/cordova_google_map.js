'use strict';

/* USAGE EXAMPLE:

<google-map latitude="map.currentCamera.latitude"
            longitude="map.currentCamera.longitude"
            zoom="map.currentCamera.zoom"
            locked="popus.firstPopup || popups.secondPopup"
            on-marker-clicked="showPlaceInfo(data)"
            on-view-changed="doSomething(view)">

  <google-map-marker location="map.currentLocation"
                     marker-data="null"
                     icon-url="www/img/map/gm-marker-me.png"
                     icon-size="36"></google-map-marker>

  <google-map-marker location="place.location"
                     marker-data="place"
                     icon-url="{{place.iconUrl}}"
                     icon-size="36"
                     ng-repeat="place in map.search.results"></google-map-marker>

  <google-map-near-markers type="restaurant"
                           ng-if="map.markers.near.restaurants"></google-map-near-markers>

  <google-map-near-markers type="bar"
                           ng-if="map.markers.near.bars"></google-map-near-markers>

  <google-map-near-markers keyword="attractions"
                           ng-if="map.markers.near.attractions"></google-map-near-markers>

  <button class="search button"
          ng-hide="search.searchResultsActive"
          ng-click="toggleSearchVisible(true)"><i class="icon rnc-icon-search"></i></button>

  <button class="filter button"
          ng-click="toggleFilterVisible(true)"><i class="icon rnc-icon-settings-fg"></i></button>

  <button class="locate button"
          ng-click="scrollToMyLocation()"><i class="icon rnc-icon-my-location"></i></button>
</google-map>
 */

angular.module('sivintech.googlemap')
  .directive('googleMap', ['$timeout', 'googleMapsService', function($timeout, googleMapsService) {
    function getCamera($scope) {
      return {
        latitude: $scope.latitude,
        longitude: $scope.longitude,
        zoom: $scope.zoom
      };
    }

    function setCamera($scope, camera) {
      $scope.latitude = camera.latitude;
      $scope.longitude = camera.longitude;
      $scope.zoom = camera.zoom;
    }

    return {
      restrict: 'E',
      transclude: true,
      template: '<div ng-transclude></div>',

      scope: {
        latitude: '=',
        longitude: '=',
        zoom: '=',
        locked: '=',
        enableIndoor: '=',
        onMarkerClicked: '&',
        onViewChanged: '&'
      },

      require: 'googleMap',

      controller: ['$scope', function($scope) {
        $scope.allMarkers = {};

        function moveCameraIfChangedExternally() {
          var currentCamera = $scope.currentCamera;
          var scopeCamera = getCamera($scope);

          var cameraChangedExternally = !currentCamera
            || currentCamera.latitude !== scopeCamera.latitude
            || currentCamera.longitude !== scopeCamera.longitude
            || currentCamera.zoom !== scopeCamera.zoom;

          if (cameraChangedExternally) {
            googleMapsService.moveTo(scopeCamera);
          }
        }

        this.createMarker = function(marker) {
          if (!marker.id) {
            throw new Error('marker id missing');

          } else if (!$scope.allMarkers[marker.id]) {
            googleMapsService.addMarker(marker);
            $scope.allMarkers[marker.id] = marker;
            return marker;

          } else {
            return null;
          }
        };

        this.deleteMarker = function(marker) {
          if (!marker.id) {
            throw new Error('marker id missing');

          } else if ($scope.allMarkers[marker.id]) {
            googleMapsService.clearMarker(marker);
            delete $scope.allMarkers[marker.id];
          }
        };

        this.animateCamera = function(camera) {
          googleMapsService.animateTo(Object.assign({}, getCamera($scope), camera));
        };

        this.animateCameraToLocations = function(locations) {
          googleMapsService.animateToLocations(locations);
        };

        this.setMarkerVisible = function(marker, visible) {
          if (marker.visible !== visible) {
            marker.visible = visible;
            googleMapsService.markerVisibilityChanged(marker);
          }
        };

        this.moveMarker = function(marker, location) {
          marker.location = location;
          googleMapsService.markerLocationChanged(marker);
        };

        this.onViewChanged = function(callback) {
          return googleMapsService.onViewChanged(callback);
        };

        $scope.$watch('locked', function() {
          googleMapsService.setInteractionEnabled(!$scope.locked);
        });

        $scope.$watch('enableIndoor', function() {
          googleMapsService.setIndoorEnabled($scope.enableIndoor);
        });

        $scope.$watchGroup(['latitude', 'longitude', 'zoom'], moveCameraIfChangedExternally);
      }],

      link: function($scope, $el, $attrs, mapController) {
        var cameraInitialized = false;
        var cameraChangedListener = null;
        var markerClickedListener = null;
        var viewChangedListener = null;

        function initializeMap() {
          if (!cameraInitialized) {
            cameraInitialized = true;

            // run in next $digest cycle for all bindings to settle
            $timeout(function() {
              googleMapsService.showMap(
                $el.children('div')[0],
                getCamera($scope),
                {
                  indoorEnabled: !!$scope.enableIndoor,
                  interactionEnabled: !$scope.locked
                }
              );

              Object.values($scope.allMarkers).forEach(function(marker) {
                googleMapsService.addMarker(marker);
              });

              cameraChangedListener = googleMapsService.onCameraChanged(onCameraChanged);
              markerClickedListener = googleMapsService.onMarkerClicked(onMarkerClicked);
              viewChangedListener = googleMapsService.onViewChanged(onViewChanged);
            });
          }
        }

        function tearDownMap() {
          if (cameraInitialized) {
            cameraInitialized = false;

            googleMapsService.hideMap();
            googleMapsService.clearAllMarkers(Object.values($scope.allMarkers));

            cameraChangedListener();
            markerClickedListener();
            viewChangedListener();
          }
        }

        function onCameraChanged(currentCamera) {
          $scope.currentCamera = currentCamera;
          setCamera($scope, currentCamera);
        }

        function onMarkerClicked(marker) {
          $scope.onMarkerClicked({data: marker.data});
        }

        function onViewChanged(view) {
          $scope.onViewChanged({view: view});
        }

        $scope.$on('googlemap.animateTo', function(e, camera) {
          mapController.animateCamera(camera);
        });

        $scope.$on('googlemap.animateToLocations', function(e, locations) {
          mapController.animateCameraToLocations(locations);
        });

        $scope.$on('googlemap.initialize', initializeMap);

        $scope.$on('googlemap.teardown', tearDownMap);
      }
    }
  }]);
