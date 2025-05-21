'use strict';
import path from 'path';
import config from 'config';
import { fileURLToPath, pathToFileURL } from "url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const uriPathPrefix = (config.has('uriPathPrefix')) ? config.get('uriPathPrefix') : '/';
const port = (config.has('node.port')) ? config.get('node.port') : 1337;
const errorLogFile = (config.has('log.error')) ? config.get('log.error') : path.resolve(__dirname, 'log/error.json');
const redirectLogFile = (config.has('log.redirect')) ? config.get('log.redirect') : path.resolve(__dirname, 'log/redirect.json');

import uriFactoryPlugins from 'janus-uri-factory-plugins';
import janus from 'janus';

janus.methods({
  redirectLogEvent (ctx, defaultEvent) {
    ['umnLibAccess', 'umnRole'].map(key => {
      const lcKey = key.toLowerCase();
      defaultEvent.user[key] = (ctx.request.header[lcKey])
        ? ctx.request.header[lcKey].split(';').filter((i) => i.length > 0)
        : [];
    });
    return defaultEvent;
  }
});

const app = janus({
  uriFactoryPlugins: uriFactoryPlugins,
  errorLog: {
    name: 'error',
    streams: [{
      level: 'info',
      path: errorLogFile,
      type: 'rotating-file',
      period: '1d',
      count: 14
    }]
  },
  redirectLog: {
    name: 'redirect',
    streams: [{
      level: 'info',
      path: redirectLogFile,
      type: 'rotating-file',
      period: '1d',
      // keep a lot of these in case the proxy-stats log collector fails
      // to retrieve them for a while.
      count: 30
    }]
  },
  uriPathPrefix: uriPathPrefix
});
app.listen(port);
