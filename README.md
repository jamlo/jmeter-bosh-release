# Tornado for Apache JMeter&trade; - A BOSH Release for Apache JMeter&trade;

**Tornado for Apache JMeter&trade;**, is a [BOSH](https://bosh.io/) release for [Apache JMeter&trade;](http://jmeter.apache.org/). It simplifies the usage of JMeter&trade; in distributed mode.

## Features

* Horizontally scale your JMeter&trade; load/stress tests with the power of BOSH.
* Deploy onto multiple IaaS offerings (wherever BOSH can be deployed: AWS, Microsoft Azure, Google Compute Engine, OpenStack, etc).
* Distribute the source traffic of your load tests across multiple regions and IaaS.
* Easily create JMeter&trade; tests plans, or supply a pre-built test plan.
* Tune the JVM options for JMeter&trade; from your BOSH deployment manifest (no VM SSHing is needed).
* Download test results directly to your local machine (optional dashboard can be generated).
* Offered in 2 modes: [`Storm`](#1--storm) and [`Tornado`](#2--tornado) modes.

## Modes:

### 1- Storm:
This mode is used when the collection of the results for JMeter&trade; plan execution is necessary. It works by spinning `n` number of VMs that will act as JMeter&trade; workers. Those VMs will run JMeter&trade; in server mode, and wait for an execution plan to be delivered to them. When all the workers are up, a BOSH errand can be manually triggered where it will send the execution plan to the workers, waits for them to finish execution, collect the results, and download these results to the users local machine.

Release jobs used in this mode: `jmeter_storm_worker` and `jmeter_storm`.

>**Note**: The worker VMs and the Errand VM should be in the same subnet. Also, if you're supplying a pre-built JMeter&trade; jmx plan, it should have a definite number of loops and should not be set to loop forever, else the errand execution will never end.

A snippet of a deployment manifest for this mode can be found [here](docs/storm-mode/sample-deployment-manifests-snippets.yml).

### 2- Tornado:
This mode is more suitable in the scenario where the simulation of large number of active users is more important than collecting the results logs; for example, detecting the behaviour of an application under continuous heavy traffic. An `n` number of VMs will start, each provided the same execution plan, where they will loop indefinitely. You can tune the number of working VMs directly through BOSH.

Release jobs used in this mode: `jmeter_tornado`.

>**Note**: If you are supplying a pre-built JMeter&trade; jmx plan, it should set the `loop indefinitely` flag to true.

A snippet of a deployment manifest for this mode can be found [here](docs/tornado-mode/sample-deployment-manifests-snippets.yml).

## Getting Started
### 1- Prerequisites
1. Deploy BOSH on your preffered IAAS. Detailed instructions can be found [here](https://github.com/cloudfoundry/bosh-deployment).
2. Consult [BOSH offical website](https://bosh.io) for more details.

### 2- Choose a Mode
Choose a [mode](#modes) that suites your objective.

### 3- Create a Test Plan
To create a test plan, you have 2 options:
1. **Using the Wizard** : Through YAML, a test plan can be supplied to the running job. Internally, this YAML representation will be transformed to a **JMX** plan. Check the [examples](#examples) for sample job properties.
2. **Pre-Built JMX Plan**: Using JMeter GUI, create a test plan. An example how-to can be found [here](http://jmeter.apache.org/usermanual/build-web-test-plan.html). Save the plan, it should be in a `.jmx` file (xml). This JMX XML plan will be supplied as a property of your job.

### 4- Run your test
Dependending on the mode you chose, deploy the manifest and run accordingly.

## Notes

1. Use a reliable DNS server in your BOSH networks settings; for example Google's `8.8.8.8` DNS server. This will limit the overhead that may occurred during DNS lookup, thus making the test results more realistic.
2. In an effort to mimic a realistic network traffic source, multiple deployments of **Tornado for Apache&trade; JMeter&trade;** can be located on multiple IAAS and regions.

## Examples

### Storm Mode - Supported HTTP Methods _'GET'_, _'PUT'_, _'POST'_, _'DELETE'_
```yaml
name: jmeter_storm
release: jmeter-tornado
properties:
  generate_dashboard: true
  wizard:
    configuration:
      users: 50 # Number of users per VM
      ramp_time: 20 # In seconds
      duration: 600 # Test duration in seconds
    targets:
    - name: GET with Headers
      url: "http://api.example.com:8080/greeting/get/"
      http_method: GET
      headers:
      - name: "Authorization"
        value: "Basic Y2F0Om1lb3c="
```

```yaml
name: jmeter_storm
release: jmeter-tornado
properties:
  generate_dashboard: true
  wizard:
    configuration:
      users: 100
      ramp_time: 30
      duration: 300
    targets:
    - name: POST with Headers and Body
      url: "http://api.example.com:8080/greeting/post/"
      http_method: POST
      headers:
      - name: "Authorization"
        value: "Basic Y2F0Om1lb3c="
      options:
        request_body: |
         {"name" : "i am a post", "age" : 425}
```

### Tornado Mode - Supported HTTP Methods _'GET'_, _'PUT'_, _'POST'_, _'DELETE'_

```yaml
name: jmeter_tornado
release: jmeter-tornado
properties:
  wizard:
    configuration:
      users: 50
      ramp_time: 30
    targets:
    - name: GET with Headers
      url: "http://api.example.com:8080/greeting/get/"
      http_method: GET
      headers:
      - name: "Authorization"
        value: "Basic Y2F0Om1lb3c="
```

```yaml
name: jmeter_tornado
release: jmeter-tornado
properties:
  wizard:
    configuration:
      users: 70
      ramp_time: 20
    targets:
    - name: PUT with Headers and Body
      url: "http://api.example.com:8080/greeting/put/"
      http_method: PUT
      headers:
      - name: "Authorization"
        value: "Basic Y2F0Om1lb3c="
      options:
        request_body: |
         {"name" : "i am a put", "age" : 525}
```

## License

Apache&trade; License, Version 2.0. See the [LICENSE](LICENSE) and [NOTICE](NOTICE) files for more information.

## Foot Notes:
Apache, Apache JMeter, and JMeter are trademarks of the Apache Software Foundation(ASF)
