require('dotenv').load()
var async = require('async');

var OpenTok = require('opentok'),
    opentok = new OpenTok(process.env.OPENTOK_API_KEY, process.env.OPENTOK_SECRET);

exports.handler = function(event, context) {
  //Try to generate Opentok session
  async.waterfall([
    function generateSessionId(next) {
      //generate session Id
      opentok.createSession(function(err, session) {
        if (session) {
          var sessionId = session.sessionId;
          //console.log('sessionId: ' + sessionId);
          next(null, sessionId);
        } else {
          next('Could not create session id. error: ' + err);
        }
      });
    },
    function generateToken(sessionId, next) {
      //generate token with sessionId
      //A broadcast owner gets a role of publisher
      var token = opentok.generateToken(sessionId, { "role" : "publisher" });
      var apiKey = process.env.OPENTOK_API_KEY
      if (token) {
        var sessionData = { "token" : token, "sessionId" : sessionId, "apiKey" : apiKey };
        //console.log('token: ' + token);
        next(null, sessionData);
      } else {
        next('Could not generate token for sessionId: ' + sessionId);
      }
    }
  ], function(err, sessionData) {
      if (err) {
        context.fail(err);
      } else {
        context.succeed(sessionData);
      }
  });
};

