'use strict';

const db = require('@arangodb').db;
const joi = require('joi');
const fields = require('./model.js');
const config = require('./config.js')();
const each = require('lodash').each;
const createRouter = require('@arangodb/foxx/router');
const sessionsMiddleware = require('@arangodb/foxx/sessions');
const jwtStorage = require('@arangodb/foxx/sessions/storages/jwt');
require("@arangodb/aql/cache").properties({ mode: "on" });

const router = createRouter();

const _settings = db._collection('foxxy_settings').firstExample();

const sessions = sessionsMiddleware({
  storage: jwtStorage(_settings.jwt_secret),
  transport: 'header'
});
module.context.use(sessions);
module.context.use(router);

var fieldsToData = function(fields, req) {
  var data = {}
  _.each(fields(), function(f) {
    if(f.tr != true) {
      if(_.isArray(req.body[f.n])) {
        data[f.n] = _.map(req.body[f.n], function(v) { return unescape(v) })
      } else {
        data[f.n] = unescape(req.body[f.n])
      }
    } else {
      data[f.n] = {}
      if(_.isArray(req.body[f.n])) {
        data[f.n][req.headers['foxx-locale']] = _.map(
          req.body[f.n], function(v) { return unescape(v) }
        )
      } else {
        data[f.n][req.headers['foxx-locale']] = unescape(req.body[f.n])
      }
    }
  })
  return data
}

var schema = {}
each(fields(), function(f) {schema[f.n] = f.j })

// Comment this block if you want to avoid authorization
module.context.use(function (req, res, next) {
  if(!req.session.uid) res.throw('unauthorized')
  res.setHeader("Access-Control-Expose-Headers", "X-Session-Id")
  next();
});

// -----------------------------------------------------------------------------
router.get('/', function (req, res) {
  res.send({ fields: fields(), data: db._query(`FOR doc IN ${config.collection} RETURN doc`).toArray()[0] });
})
.header('X-Session-Id')
.description(`Returns first ${config.collection}`);
// -----------------------------------------------------------------------------
router.get('/check_form', function (req, res) {
    var errors = []
  try {
    errors = joi.validate(JSON.parse(req.queryParams.data), schema, { abortEarly: false }).error.details
  } catch(e) {}
  res.send({errors: errors });
})
.header('X-Session-Id')
.description('Check the form for live validation');
// -----------------------------------------------------------------------------
router.post('/:id', function (req, res) {
  var obj = collection.document(req.pathParams.id)
  var data = fieldsToData(fields, req)
  collection.update(obj, data)
  res.send({ success: true });
})
.body(joi.object(schema), 'data')
.header('foxx-locale')
.header('X-Session-Id')
.description(`Update ${config.collection}.`);
