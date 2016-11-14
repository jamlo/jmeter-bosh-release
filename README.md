# JMeter Tornado (A JMeter BOSH Release)

JMeter Tornado, is a [BOSH](https://bosh.io/) release for [Apache JMeter](http://jmeter.apache.org/). It simplifies the usage of JMeter in distributed mode.

## Features

* Horizontally scale your JMeter load/stress tests with the power of BOSH.
* Deploy onto multiple IaaS offerings (wherever BOSH can be deployed: AWS, Microsoft Azure, Google Compute Engine, OpenStack, etc).
* Distribute the source traffic of your load tests across multiple regions and IaaS.
* Tune the JVM options for JMeter from your BOSH deployment manifest (no VM SSHing is needed).
* The load/stress tests results will be automatically downloaded to your local machine (optional dashboard can be generated).
* Offered in 2 modes: [`Storm`](#1--storm) and [`Tornado`](#2--tornado) modes.

## Modes:

### 1- Storm:
This mode is used when the collection of the results for JMeter plan execution is necessary. It works by spinning `n` number of VMs that will act as JMeter workers. Those VMs will run JMeter in server mode, and wait for an execution plan to be delivered to them. When all the workers are up, a BOSH errand can be manually triggered where it will send the execution plan to the workers, waits for them to finish execution, collect the results, and download these results to the users local machine.

Two Jobs from the release are used here: `jmeter_worker` and `jmeter_storm` (errand).

>**Note**: All the workers VMs and the Errand VM should be in the same subnet. Also, the JMeter jmx plan should have a definite number of loops and should not be set to loop forever; else the errand execution will never end.

An snippet of a deployment manifest for this mode can be found [here](docs/storm-mode/sample-deployment-manifests-snippets.yml).

### 2- Tornado:
This mode is more suitable in the scenario where the simulation of large number of active users is more important than collecting the results logs; for example, detecting the behaviour of an application under continuous heavy traffic. An `n` number of VMs will start, each provided the same execution plan, where they will loop indefinitely. You can tune the number of working VMs directly through BOSH.

One job from the release is used in this mode: `jmeter_tornado`.

>**Note**: The JMeter execution plan should set the `loop indefinitely` flag to true.

An snippet of a deployment manifest for this mode can be found [here](docs/tornado-mode/sample-deployment-manifests-snippets.yml).

## Getting Started - AWS Example

### Prerequisites
1. Deploy [BOSH to AWS](http://bosh.io/docs/init-aws.html)
2. Upload the latest [Ubuntu AWS stemcell](https://bosh.io/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent)
3. Upload a [Cloud Config](https://bosh.io/docs/cloud-config.html).

### Preparing the Test

1. **Build a Test Plan:** Using JMeter GUI, create a test plan. An example how-to can be found [here](http://jmeter.apache.org/usermanual/build-web-test-plan.html). Save the plan, it should be in a `.jmx` file (xml).

2. **Choosing a Mode:** Choose a [mode](#modes) that suites your objective. Then build a bosh deployment manifest accordingly. You will need the plan created in step 1.

3. **Run the Plan:** Using BOSH CLI, run your plan accordingly.

## Notes

1. Use a reliable DNS server in your BOSH networks settings; for example Google's `8.8.8.8` DNS server. This will limit the overhead that may occurred during DNS lookup, thus making the test results more realistic.
2. In an effort to mimic a realistic network traffic source, multiple deployments of JMeter Tornado can be located on multiple IAAS and regions.

## License

Apache License, Version 2.0. See the [LICENSE](LICENSE) and [NOTICE](NOTICE) files for more information.
