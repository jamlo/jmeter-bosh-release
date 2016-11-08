# JMeter Tornado (A JMeter BOSH Release)

## About

This project, JMeter Tornado, is a [BOSH](https://bosh.io/) release for [Apache JMeter](http://jmeter.apache.org/). It simplifies the usage of JMeter in distributed mode.

## Features

* Horizontally scale your JMeter load/stress tests with the power of BOSH.
* Deploy onto multiple IaaS offerings (wherever BOSH can be deployed: AWS, Microsoft Azure, Google Compute Engine, OpenStack, etc).
* Distribute the source traffic of your load tests across multiple regions and IaaS.
* Tune the JVM options for JMeter from your BOSH deployment manifest (no VM SSHing is needed).
* The load/stress tests results will be automatically downloaded to your local machine (optional dashboard can be generated).
* Offered in 2 modes:
  * `Storm` mode: Run your tests and get the results in a tarball downloaded onto your local machine.
  * `Tornado` mode: Run your tests to detect the behaviour of your application under heavy traffic. Scale up and down the number of traffic source's VMs on the fly.

## License

Apache License, Version 2.0. See the [LICENSE](LICENSE) and [NOTICE](NOTICE) files for more information.
