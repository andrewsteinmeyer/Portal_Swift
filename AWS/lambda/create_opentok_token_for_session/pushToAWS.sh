#!/bin/bash

echo `gulp --name generateOpentokTokenForSessionId clean ; gulp ; gulp --name generateOpentokTokenForSessionId zip ; gulp --name generateOpentokTokenForSessionId upload`
