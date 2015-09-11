require('dotenv').load()

var Firebase = require('firebase'),
    ref = new Firebase(process.env.FIREBASE_AUTH_URL);

var FirebaseTokenGenerator = require('firebase-token-generator'),
    tokenGenerator = new FirebaseTokenGenerator(process.env.FIREBASE_SECRET);

exports.handler = function(event, context) {
  //Try to generate Firebase token
  //console.log(event);

  var token = tokenGenerator.createToken({uid: event.identity, provider: 'aws'});

  if (token) {
    context.succeed(token);
    //console.log("token: ", token);
  } else {
    context.fail()
  }
};

