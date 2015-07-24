# jupyter-kernel-launcher

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
