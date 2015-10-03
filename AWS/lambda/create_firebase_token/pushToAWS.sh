#!/bin/bash

echo `gulp --name generateFirebaseToken clean ; gulp ; gulp --name generateFirebaseToken zip ; gulp --name generateFirebaseToken upload`
