#!/bin/bash
cp * ../../dummy/codebot/ -R
chmod 755 ../../dummy/codebot/* -R
sed -i 's/localhost/efnet.xs4all.nl/g' ../../dummy/codebot/main.rb
sed -i 's/#testcodebot/#dreamincode/g' ../../dummy/codebot/main.rb
