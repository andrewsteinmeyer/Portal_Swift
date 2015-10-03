require('dotenv').load()

var OpenTok = require('opentok'),
    opentok = new OpenTok(process.env.OPENTOK_API_KEY, process.env.OPENTOK_SECRET);

exports.handler = function(event, context) {
  //generate token from sessionId
  //A broadcast listener gets a role of subscriber

  var token = opentok.generateToken(event.sessionId, { "role" : "subscriber" });
  var apiKey = process.env.OPENTOK_API_KEY

  if (token) {
    var sessionData = { "token" : token, "apiKey" : apiKey };
    console.log('token: ' + token);
    context.succeed(sessionData);
  } else {
    context.fail()
  }
};

