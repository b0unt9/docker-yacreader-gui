@echo off
docker build --build-arg YACREADER_VERSION=%1 -t yacreader .
pause