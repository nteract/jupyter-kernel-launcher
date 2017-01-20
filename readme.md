# jupyter-kernel-launcher

[![Greenkeeper badge](https://badges.greenkeeper.io/nteract/jupyter-kernel-launcher.svg)](https://greenkeeper.io/)

Broken out of [Hydrogen](https://github.com/willwhitney/hydrogen).

## Usage

```javascript
var KL = require('jupyter-kernel-launcher');

if (KL.languageHasKernel('python')) {
    KL.startKernel('python', function(session) {
        // returns a Jupyter Session
        // https://github.com/nteract/jupyter-session
        session.execute("print('Hello Jupyter!')");
    });
}
```
