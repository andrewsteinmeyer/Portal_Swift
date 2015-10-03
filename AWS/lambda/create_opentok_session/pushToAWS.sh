#!/bin/bash

echo `gulp --name generateOpentokSessionId clean ; gulp ; gulp --name generateOpentokSessionId zip ; gulp --name generateOpentokSessionId upload`
