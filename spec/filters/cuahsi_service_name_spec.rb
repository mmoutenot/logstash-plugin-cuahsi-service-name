# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/cuahsi_service_name"
require "nokogiri"
require "open-uri"

describe LogStash::Filters::CUAHSI_SERVICE_NAME do
  describe 'unnested' do
    config <<-CONFIG
      filter {
        cuahsi_service_name {
          id_field => "[service_id]"
          target => "[test_target]"
        }
      }
    CONFIG

    sample("service_id" => "3555") do
      insist { subject["test_target"] } == "GLEON_Dorset"
    end
  end

  describe 'nested' do

    config <<-CONFIG
      filter {
        cuahsi_service_name {
          id_field => "[val][service_id]"
          target => "[val][test_target]"
        }
      }
    CONFIG

    sample({ val: { service_id: "3555" }}) do
      insist { subject["val"]["test_target"] } == "GLEON_Dorset"
    end
  end
end
