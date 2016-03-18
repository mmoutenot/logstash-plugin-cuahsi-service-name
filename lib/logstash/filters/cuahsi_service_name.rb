# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "lru_redux"
require "pry"


# The CUAHSI Service Name filter performs a lookup of the service info
# and maps ids to service names
#
# The config should look like this:
# [source,ruby]
#     filter {
#       cuahsi_service_name {
#         id_field => ['query_params']['n']
#         target => ['query_params']['service_name']
#       }
#     }
#
class LogStash::Filters::CUAHSI_SERVICE_NAME < LogStash::Filters::Base
  config_name "cuahsi_service_name"

  config :id_field, :validate => :string, :required => true
  config :target, :validate => :string, :required => true

  public
  def register
    require 'open-uri'
    require 'nokogiri'

    xml = Nokogiri::XML(open('http://hiscentral.cuahsi.org/webservices/hiscentral.asmx/GetWaterOneFlowServiceInfo'))
    @service_names_by_id = {}
    xml.css('ServiceInfo').map do |info|
      service_id = info.at('ServiceID').text
      network_name = info.at('NetworkName').text
      if service_id && network_name
        @service_names_by_id[service_id] = network_name
      else
        @logger.warn("CUAHSI_SERVICE_NAME: invalid pair received from network request")
      end

    end
  end # def register

  public
  def filter(event)
    return if resolve(event).nil?
    filter_matched(event)
  end

  private
  def resolve(event)
    id = event[@id_field]
    name = @service_names_by_id[id]
    event[@target] = name
  end

end
