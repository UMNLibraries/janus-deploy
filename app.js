'use strict';
const path = require('path');
const config = require('config');
const uriPathPrefix = (config.has('uriPathPrefix')) ? config.get('uriPathPrefix') : '/';
const host = (config.has('node.host')) ? config.get('node.host') : '127.0.0.1';
const port = (config.has('node.port')) ? config.get('node.port') : 1337;
const errorLogFile = (config.has('log.error')) ? config.get('log.error') : path.resolve(__dirname, 'log/error.json');
const redirectLogFile = (config.has('log.redirect')) ? config.get('log.redirect') : path.resolve(__dirname, 'log/redirect.json');

const uriFactoryPlugins = require('@nihiliad/janus-uri-factory-plugins');
const janus = require('@nihiliad/janus').methods({
  redirectLogEvent (ctx, defaultEvent) {
    if (ctx.request.header['umnrole']) {
      defaultEvent.request['umnRole'] = ctx.request.header['umnrole'].split(';').filter(function(i) {
        return i.length > 0;
      });
    }
    return defaultEvent;
  },
});

const app = janus({
  uriFactoryPlugins: uriFactoryPlugins,
  errorLog: {
    name: 'error',
    streams: [{
      level: 'info',
      path: errorLogFile,
    }],
  },
  redirectLog: {
    name: 'redirect',
    streams: [{
      level: 'info',
      path: redirectLogFile,
    }],
  },
  uriPathPrefix: uriPathPrefix,
});
app.listen(port);
