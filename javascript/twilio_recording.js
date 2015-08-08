angular.module('RecordedMessages')
  .service('messageRecorder', ['$http', '$q', '$log', '$timeout', function($http, $q, $log, $timeout) {
    var tokenPromise = null;
    var devicePromise = null;
    var currentCall = null;

    function loadToken() {
      var deferred = $q.defer();

      $http.get('/recording_token.json').then(
        function(response) {
          var token = response.data.recording_token;
          if (token) {
            deferred.resolve(token);
          } else {
            deferred.reject(new Error('failed setting up recording'));
          }
        },
        function(error) {
          deferred.reject(error);
        }
      );

      return deferred.promise;
    }

    function initializeDevice(token) {
      var deferred = $q.defer();

      Twilio.Device.setup(token);

      Twilio.Device.connect(function(connection) {
        $timeout(function() {
          $log.info('recording: connected');
          if (currentCall) {
            currentCall.connection = connection;
            currentCall.callbacks.connect();
          }
        });
      });

      Twilio.Device.disconnect(function() {
        $timeout(function() {
          $log.info('recording: disconnected');
          if (currentCall) {
            currentCall.callbacks.complete();
            currentCall = null;
          }
        });
      });

      Twilio.Device.error(function(error) {
        $timeout(function() {
          failRecording(error);
        });
      });

      deferred.resolve(true);

      return deferred.promise;
    }

    function failRecording(error) {
      if (currentCall) {
        $log.error('recording failed: ', error);
        currentCall.callbacks.error(error);
        currentCall = null;
      } else {
        $log.error('unexpected Twilio error: ', error);
      }
    }

    function createCallObject(connectCallback, completeCallback, errorCallback) {
      return {
        end: function() {
          if (currentCall) {
            if (currentCall.connection) {
              currentCall.connection.sendDigits('#');
            } else {
              Twilio.Device.disconnect();
              currentCall.callbacks.complete();
              currentCall = null;
            }
          }
        },
        connection: null,
        callbacks: {
          connect: connectCallback,
          complete: completeCallback,
          error: errorCallback
        }
      };
    }

    function getTokenPromise() {
      if (tokenPromise === null) {
        tokenPromise = loadToken();
      } else {
        return tokenPromise;
      }
    }

    function getDevicePromise(token) {
      if (devicePromise === null) {
        devicePromise = initializeDevice(token);
      } else {
        return devicePromise;
      }
    }

    this.beginRecording = function(messageModel, connectCallback, completeCallback, errorCallback) {
      if (currentCall) {
        throw new Error('cannon begin recording: another recording already in progress');
      }

      currentCall = createCallObject(connectCallback, completeCallback, errorCallback);

      getTokenPromise().then(function(token) {
        getDevicePromise(token).then(function() {
          Twilio.Device.connect({
            message_id: messageModel.id
          });

        }, failRecording);
      }, failRecording);

      return currentCall;
    };
  }]);
