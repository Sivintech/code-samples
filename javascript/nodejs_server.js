#!/usr/bin/env node

var express = require('express'),
    app = express();

app.server = require('http').createServer(app);

/** Load Configuration **/
app.config = require('app/config');

/** Instantiate Model **/
app.database = new (require('app/database/mysql'))(app.config);
app.sitesModel = new (require('app/model/sites'))(app);
app.usersModel = new (require('app/model/users'))(app);
app.devicesModel = new (require('app/model/devices'))(app);
app.settingsModel = new (require('app/model/settings'))(app);
app.configurationsModel = new (require('app/model/configurations'))(app);
app.historyModel = new (require('app/model/history'))(app);

/** Setup Routes **/
[
    'app/ui/middleware',
    'app/api/login',
    'app/api/socket',
    'app/api/devices',
    'app/api/configurations',
    'app/ui/login',
    'app/ui/sites',
    'app/ui/dashboard',
    'app/ui/configurations',
    'app/ui/users',
    'app/ui/settings',
    'app/ui/history'
].forEach(function (routePath) {
    require(routePath)(app);
});

/** Setup Other Middleware **/
app.use(express.static(__dirname + '/ui/static'));
app.use(require('app/errors').errorsMiddleware());
app.use(require('app/errors').notFoundMiddleware());

/** Done **/
app.server.listen(app.config.express.port, app.config.express.ip, function (error) {
    if (error) {
        app.config.log.error('Unable to listen for connections', error);
        process.exit(10);
    }
    app.config.log.info('listening on http://' + (app.config.express.ip || '[INADDR_ANY]') + ':' + app.config.express.port);
});

app.usersModel.createInitialSuperUser();
