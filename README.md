# gamepads_web

Experimental web implementation of the gamepads package for Flutter. This project is currently on hold. See: https://github.com/flame-engine/gamepads/issues/32. 

## Getting Started

This plugin is structured to assume the presence of a web worker (as below). The web worker file should be present at the root of your project's web folder. The web worker thread cannot access input APIs, so here it is used only to create a messaging loop. 

```
const millisBetweenChecks = 17;
var checkForInput = true;

addEventListener("message", (event) => {
    switch (event.data) {
        case "STOP":
            stop();
            break;
        case "START":
            start();
            break;
        default:
            break;
    }
});

function callback() {
    if (checkForInput) {
        postMessage("PING");
        setTimeout(callback, millisBetweenChecks);
    }
}

function start() {
    callback();
}

function stop() {
    checkForInput = false;
}
```
