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
#         id_field => "[query_params][n]"
#         target => "[query_params][service_names]"
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

    updateNameHash()
  end

  public
  def filter(event)
    return if resolve(event).nil?
    filter_matched(event)
  end

  public
  def updateNameHash
    # short circuit if we updated less than a minute ago
    return false if @lastUpdated && @lastUpdated > Time.now - 60

    xml = Nokogiri::XML(open('http://hiscentral.cuahsi.org/webservices/hiscentral.asmx/GetWaterOneFlowServiceInfo'))
    @lastUpdated = Time.now()
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

    return true
  end

  private

  def resolve(event)
    rawIds = event[@id_field]
    return if rawIds == nil

    ids = rawIds.split(',')
    names = ids.map do |id|
      name = @service_names_by_id[id]

      # repoll service info if we have an id not in the local cache
      if !name
        updateNameHash()
        name = @service_names_by_id[id]
      end

      name
    end

    event[@target] = names
  end

end
