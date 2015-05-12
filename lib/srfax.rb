require 'RestClient'
require 'active_support'

# This class serves as the integration component between the application and the SRFax cloud service.
# API DOX available @ https://www.srfax.com/srf/media/SRFax-REST-API-Documentation.pdf.  
#
# This module currently Implements the following POST commands from the API:
#  Get_Usage – Retrieves the account usage
#  Update_Viewed_Status – Mark a inbound or outbound fax as read or unread.
#  Queue_Fax - Schedules a fax to be sent with or without cover page.
#  Get_Fax_Inbox - Returns a list of faxes received for a specified period of time
#  Get_Fax_Outbox - Returns a list of faxes sent for a specified period of time
#  Retrieve_Fax – Returns a specified sent or received fax file in PDF or TIFF format
#  Delete_Fax - Deletes specified received or sent faxes
#
#  Unimplemented:
#  Get_FaxStatus – Determines the status of a fax that has been scheduled for delivery.
#  Get_MultiFaxStatus – Determines the status of a multiple faxes that hav been
#     scheduled for delivery.
#  Delete_Pending_Fax - Deletes a specified queued fax which has not been processed
#  Stop_Fax - Removes a scheduled fax from the queue
module SrFax
  VERSION = '0.3.0pre'

  # Base URL for accessing SRFax API
  BASE_URI = "https://www.srfax.com/SRF_SecWebSvc.php"

  mattr_accessor :defaults
  # Default values hash to use with all #execute commands
  @@defaults = {
    access_id: '1234',
    access_pwd: 'password',
    sFaxFormat: 'PDF', # Default format, PDF or TIF
    sResponseFormat: 'JSON' # XML or JSON
  }

  mattr_accessor :logger
  # Logger object for use in standalone modeo or with Rails
  @@logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)

  class << self
    # Allow configuring Srfax with a block, these will be the methods default values for passing to 
    # each function and will be overridden by any methods locally posted variables (ex: :action)
    #
    # @yield Accepts a block of valid configuration options to set or override default values
    #
    # Example:
    #   Srfax.setup do |config|
    #     config.defaults[:access_id] = '1234'
    #     config.defaults[:access_pwd] = 'password'
    #   end
    def setup(&block)
      yield self
    end
  
    # Views the remote inbox.  By default this call does NOT update the viewed
    # or read status of the fax unless specified in options.
    #
    # @param status [String] Specify the status of the message you are listing (UNREAD, ALL, READ)
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sPeriod Specify the period to query.  Accepts 'ALL' or 'RANGE'
    # @option options [String] :sStatDate Used with :sPeriod and denotes the period to start at.  Format is 'YYYYMMDD'
    # @option options [String] :sEndDate Used with :sPeriod and denotes the period to endd at.  Format is 'YYYYMMDD'
    # @option options [String] :sIncludeSubUsers Include subuser accounts ('Y' or 'N')
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    #
    # Example Payload for Return: 
    #   {"Status"=>"Success", "Result"=>[{"FileName"=>"20150430124505-6104-19_1|20360095", "ReceiveStatus"=>"Ok", 
    #   "Date"=>"Apr 30/15 02:45 PM", "EpochTime"=>1430423105, "CallerID"=>"9056193547", "RemoteID"=>"", "Pages"=>"1", 
    #   "Size"=>"5000", "ViewedStatus"=>"N"} ]}
    def view_inbox(status = 'UNREAD', options = {})
      logger.info("Checking fax inbox from cloud service")
      postVariables = { 
        :action => "Get_Fax_Inbox", 
        :sViewedStatus => status.upcase
      }.merge!(options)
      res = execute(postVariables)
  
      if res[:Status] != "Failure"
        faxcount = res["Result"].count
        faxcount > 0 ? logger.debug("Found #{faxcount} new fax(es)") : logger.debug("No faxes found matching that criteria")
      end
  
      return res
    end
  
    # Uses post Get_Usage to fetch the current account usage statistics (for all associated accounts)
    #
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sPeriod Specify the period to query.  Accepts 'ALL' or 'RANGE'
    # @option options [String] :sStatDate Used with :sPeriod and denotes the period to start at.  Format is 'YYYYMMDD'
    # @option options [String] :sEndDate Used with :sPeriod and denotes the period to endd at.  Format is 'YYYYMMDD'
    # @option options [String] :sIncludeSubUsers Include subuser accounts ('Y' or 'N')
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    #
    # Example Payload for Return: 
    #   {"Status"=>"Success", "Result"=>[{"UserID"=>1234, "Period"=>"ALL", 
    #   "ClientName"=>nil, "SubUserID"=>0, "BillingNumber"=>"8669906402", "NumberOfFaxes"=>5, "NumberOfPages"=>8}]}
    #
    # optional variables 
    #   sPeriod: (ALL or RANGE), sStartDate: YYYYMMDD, sEndDate: YYYYMMDD
    #   sIncludeSubUsers: Y or N  (if you want to see all faxes on subaccounts as well)
    def view_usage(options = {})
      logger.info "Viewing fax usage from cloud service"
      postVariables = { :action => "Get_Fax_Usage" }
      res = execute(postVariables)
      return res
    end
  
    # Uses post Get_Fax_Outbox to retrieve the usage for the account (and all subaccounts)
    #
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sPeriod Specify the period to query.  Accepts 'ALL' or 'RANGE'
    # @option options [String] :sStatDate Used with :sPeriod and denotes the period to start at.  Format is 'YYYYMMDD'
    # @option options [String] :sEndDate Used with :sPeriod and denotes the period to endd at.  Format is 'YYYYMMDD'
    # @option options [String] :sIncludeSubUsers Include subuser accounts ('Y' or 'N')
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    def view_outbox(options = {})
      logger.info "Viewing fax outbox from cloud service"
      postVariables = { :action => "Get_Fax_Outbox" }
      res = execute(postVariables)
  
      if res[:Status] != "Failure"
        faxcount = res["Result"].count
        faxcount > 0 ? logger.debug("Found #{faxcount} new fax(es)") : logger.debug("No faxes found matching that criteria")
      end
  
      return res
    end
  
    # Uses POST Retrieve_Fax to retrieve a specified fax from the server.  Returns it in the default
    # specified format (PDF or TIFF)
    # 
    # @param descriptor [String] Specify the status of the message you are listing (UNREAD, ALL, READ)
    # @param direction [String] Either 'IN' or 'OUT' to specify the inbox or outbox
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sMarkasViewed Update the fax status to viewed (or unviewed). Accepts 'Y' or 'N'
    # @option options [String] :sFaxFormat Update the format to retrieve the file in ('PDF' or 'TIFF')
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    def get_fax(descriptor, direction, options = {}) 
      logger.info "Retrieving fax from cloud service in the direction of '#{direction}', Descriptor:'#{descriptor}'"
      faxname,faxid = descriptor.split('|')
      if (faxname.nil? or faxid.nil?)
        logger.info "Valid descriptor not provided to get_fax function call.  Descriptor:'#{descriptor}'"
        return nil
      end
  
      logger.info "Retrieving fax from cloud service"
      postVariables = {   
        :action => "Retrieve_Fax",
        :sFaxFileName => descriptor,
        :sFaxDetailsID => faxid,
        :sDirection => direction.upcase, 
        :sMarkasViewed => 'N'
      }.merge!(options)
      res = execute(postVariables)
      return res
    end
    
    # Update the status (read/unread) for a particular fax
    #
    # @param descriptor [String] Specify the status of the message you are listing (UNREAD, ALL, READ)
    # @param direction [String] Either 'IN' or 'OUT' to specify the inbox or outbox
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sMarkasViewed Update the fax status to viewed (or unviewed). Accepts 'Y' or 'N'.  Defaults to Y
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    def update_fax_status(descriptor, direction, options = {})
      logger.info "Updating a fax in the cloud service in the direction of '#{direction}', Descriptor:'#{descriptor}'"
      faxname,faxid = descriptor.split('|')
      if (faxname.nil? or faxid.nil?)
        logger.info "Valid descriptor not provided to get_fax function call.  Descriptor:'#{descriptor}'"
        return nil
      end

      postVariables = {   
        :action => "Update_Viewed_Status",
        :sFaxFileName => descriptor,
        :sFaxDetailsID => faxid,
        :sDirection => direction.upcase, 
        :sMarkasViewed => 'Y',
      }.merge!(options)
      res = execute(postVariables)
      return res
    end
    
    # Delete a particular fax from the SRFax cloud service
    #
    # @param descriptor [String] THe descriptor provided by SRFax which identifies a unique fax
    # @param direction [String] Either 'IN' or 'OUT' to specify the inbox or outbox
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    #
    # Example Payload for Return: 
    #   {"Status"=>"Success", "Result"=>[{"FileName"=>"20150430124505-6104-19_1|20360095", "ReceiveStatus"=>"Ok", 
    #   "Date"=>"Apr 30/15 02:45 PM", "EpochTime"=>1430423105, "CallerID"=>"9056193547", "RemoteID"=>"", "Pages"=>"1", 
    #   "Size"=>"5000", "ViewedStatus"=>"N"} ]}
    #  :direction is either 'IN' or 'OUT' for inbox or outbox
    #  :descriptor is what is returns from the POST Filename field from the view_inbox result
    def delete_fax(descriptor, direction)
      logger.info "Deleting a fax in the cloud service in the direction of '#{direction}', Descriptor:'#{descriptor}'"
      faxname,faxid = descriptor.split('|')
      if (faxname.nil? or faxid.nil?)
        logger.info "Valid descriptor not provided to get_fax function call.  Descriptor:'#{descriptor}'"
        return nil
      end
  
      postVariables = {   
        :action => "Delete_Fax",
        :sFaxFileName_x => descriptor,
        :sFaxDetailsID_x => faxid,
        :sDirection => direction.upcase, 
      }
      res = execute(postVariables)
      return res
    end

    private

    # Actually execute the RESTful post command to the #BASE_URI
    #
    # @param postVariables [String] The list of variables to apply in the POST body when executing the request
    # @return [Hash] The hash payload value including a proper status.  Will never return nil.
    def execute(postVariables)
      res = RestClient::Request.execute :url => BASE_URI, :method => :post, :payload => postVariables.merge(defaults).to_json, :content_type => :json, :accept => :json
      return_data = nil
      return_data = JSON.parse(res) if res

      if return_data.nil? || return_data.fetch("Status", "Failure") != "Success"
        logger.info "Execution of SR Fax command not successful" 
        return_data = { :Status => "Failure" } 
      end

      return return_data
    end
  end
end

