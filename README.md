Overview

Pigation is an app designed to allow you to control external lighting and irrigation systems from a mobile device.

The Pigation server runs on a raspbery PI and the app can be
compiled as a mobile app (android and iOS) or a web app.

The app allows you to configure Pins on the Pi to control various devices such as lights and values for an irrigation system.

In theory the app can be used to control any device attached to a Pi but it has specific interfaces that are fashioned around 
configuring irrigation and lighting systems.


The full documentation is now available on gitbooks:

https://bsutton.gitbook.io/pigation/



Contributes to this project are strongly encouraged so post your patches.


# Debugging
You can run both the pig_app and the pig_server on the same dev
system.

To run the server local you will need to modify the config/config.yaml to use a port higher than 1024, we recommend 1080.

Now configure the pig_app to match the pig_server's settings
environment variable SERVER_URL set to 'http://localhost:1080.



Example vs code configuration:

```json
  "configurations": [
        {
            "name": "pig_app",
            "cwd": "pig_app",
            "request": "launch",
            "type": "dart",
            "env": {
                "SERVER_URL": "http://localhost:1080"
            }
        },
```       


