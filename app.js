'use strict';
const path = require('path');
const config = require('config');
const host = (config.has('node.host')) ? config.get('node.host') : '127.0.0.1';
const port = (config.has('node.port')) ? config.get('node.port') : 1337;
const errorLogFile = (config.has('log.error')) ? config.get('log.error') : path.resolve(__dirname, 'log/error.json');
const redirectLogFile = (config.has('log.redirect')) ? config.get('log.redirect') : path.resolve(__dirname, 'log/redirect.json');

const uriFactoryPlugins = require('@nihiliad/janus-uri-factory-plugins');
const janus = require('@nihiliad/janus').methods({
  redirectLogEvent (ctx) {
    return {
      'request': {
        'method': ctx.req.method,
        'url': ctx.req.url,
        'referer': ctx.req.headers['referer'],
        'userAgent': ctx.req.headers['user-agent'],
        'umnRole': ctx.req.headers['umnrole'],
      },
      'target': ctx.request.query.target,
      'search': ctx.request.query.search,
      'scope': ctx.request.query.scope,
      'field': ctx.request.query.field,
    };
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
});
app.listen(port);
