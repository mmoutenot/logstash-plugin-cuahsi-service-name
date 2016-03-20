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
      insist { subject["test_target"] } == ["GLEON_Dorset"]
    end

    sample({}) do
      insist { subject.include?("test_target") } == false
    end
  end

  describe 'list' do
    config <<-CONFIG
      filter {
        cuahsi_service_name {
          id_field => "[service_ids]"
          target => "[test_target]"
        }
      }
    CONFIG

    sample("service_ids" => "3555,1") do
      insist { subject["test_target"] } == ["GLEON_Dorset", "NWISDV"]
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
      insist { subject["val"]["test_target"] } == ["GLEON_Dorset"]
    end
  end

  describe 'updateNameHash' do
    let(:subject) { LogStash::Filters::CUAHSI_SERVICE_NAME.new(config) }
    let(:event) { LogStash::Event.new({ service_id: "999999" }) }

    before(:each) do
      subject.register()
    end

    context 'one event' do
      let(:config) { { "id_field" => "[service_id]", "target" => "[service_names]" } }

      it "should request a new service name hash" do
        expect(subject).to receive(:updateNameHash).once
        subject.filter(event)
      end
    end

    context 'two events' do
      let(:config) { { "id_field" => "[service_id]", "target" => "[service_names]" } }

      it "should not request a new service name hash too often" do
        # because the register calls the update, it should return false
        allow(subject).to receive(:updateNameHash).and_call_original
        expect(subject.updateNameHash()).to eq(false)
      end
    end
  end
end
