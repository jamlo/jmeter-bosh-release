This folder contains ruby-jmeter gem (version 3.0.13) and all of its gem dependencies.

To get the list of gem in this folder:

1- Create a file called `Gemfile`.
2- In that file add these lines:
  ```
  source "http://rubygems.org"
  gem 'ruby-jmeter', '3.0.13'
  ```

3- Run `bundle package`.
4- A new `vendor/cache` folder will be created and populated with `ruby-jmeter` gem and its dependencies.

Gemfile.lock
```
GEM
  remote: http://rubygems.org/
  specs:
    domain_name (0.5.20170404)
      unf (>= 0.0.5, < 1.0.0)
    http-cookie (1.0.3)
      domain_name (~> 0.5)
    mime-types (3.1)
      mime-types-data (~> 3.2015)
    mime-types-data (3.2016.0521)
    mini_portile2 (2.1.0)
    netrc (0.11.0)
    nokogiri (1.7.1)
      mini_portile2 (~> 2.1.0)
    rest-client (2.0.1)
      http-cookie (>= 1.0.2, < 2.0)
      mime-types (>= 1.16, < 4.0)
      netrc (~> 0.8)
    ruby-jmeter (3.0.13)
      nokogiri
      rest-client
    unf (0.1.4)
      unf_ext
    unf_ext (0.0.7.3)

PLATFORMS
  ruby

DEPENDENCIES
  ruby-jmeter (= 3.0.13)

BUNDLED WITH
   1.13.2

```
