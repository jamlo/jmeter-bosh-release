require 'ruby-jmeter'
require 'rubygems'
require 'json'

module JMeterTornado

  class InputParser
    def parse(settings_file_path)
      JSON.parse(File.read(settings_file_path))
    end
  end

  class PlanGenerator

    def generate(settings, jmx_plan_path)
      thread_count = settings['configuration']['users']
      ramp_time = settings['configuration']['ramp_time']
      continue_forever = settings['configuration']['continue_forever']
      duration = settings['configuration']['duration']
      simple_delay = settings['configuration']['simple_delay']
      gaussian_deviation = settings['configuration']['gaussian_deviation']
      gaussian_constant_delay_offset = settings['configuration']['gaussian_constant_delay_offset']

      test do
        threads count: thread_count,
                continue_forever: continue_forever,
                rampup: ramp_time,
                duration: duration do

          if simple_delay != -1
            think_time simple_delay
          elsif gaussian_deviation != -1 && gaussian_constant_delay_offset != -1
            think_time gaussian_constant_delay_offset, gaussian_deviation
          end

          targets = settings['targets']

          targets.each do |target|

            case target['http_method'].upcase
              when 'GET'
                get name: target['name'], url: target['url'] do
                  with_xhr if target['with_xhr']
                  header target['headers'] unless target['headers'].empty?
                end

              when 'PUT'
                request_body = target['options'].nil? ? '' : target['options'].fetch('request_body', '')

                put name: target['name'], url: target['url'], raw_body: request_body do
                  with_xhr if target['with_xhr']
                  header target['headers'] unless target['headers'].empty?
                end

              when 'POST'
                request_body = target['options'].nil? ? '' : target['options'].fetch('request_body', '')

                post name: target['name'], url: target['url'], raw_body: request_body do
                  with_xhr if target['with_xhr']
                  header target['headers'] unless target['headers'].empty?
                end

              when 'DELETE'
                delete name: target['name'], url: target['url'] do
                  with_xhr if target['with_xhr']
                  header target['headers'] unless target['headers'].empty?
                end

              else
                raise "Unspported HTTP method: '#{target['http_method']}'"
            end
          end

        end
      end.jmx(file: jmx_plan_path)
    end
  end
end

settings_path=ARGV[0]
jmx_plan_path=ARGV[1]

settings = JMeterTornado::InputParser.new.parse(settings_path)
JMeterTornado::PlanGenerator.new.generate(settings, jmx_plan_path)
