require 'restclient'
require 'active_support'
require 'active_support/core_ext/hash'
require 'version'

# This class serves as the integration component between the application and the SRFax cloud service.
# API DOX available @ https://www.srfax.com/srf/media/SRFax-REST-API-Documentation.pdf.
#
# This module currently Implements the following POST commands from the API:
#  Get_Usage – Retrieves the account usage.
#  Update_Viewed_Status – Mark a inbound or outbound fax as read or unread.
#  Queue_Fax - Schedules a fax to be sent with or without cover page.
#  Get_Fax_Inbox - Returns a list of faxes received for a specified period of time.
#  Get_Fax_Outbox - Returns a list of faxes sent for a specified period of time.
#  Retrieve_Fax – Returns a specified sent or received fax file in PDF or TIFF format.
#  Delete_Fax - Deletes specified received or sent faxes.
#  Get_FaxStatus – Determines the status of a fax that has been scheduled for delivery.
#  Get_MultiFaxStatus – Determines the status of a multiple faxes that have been
#     scheduled for delivery.
#  Stop_Fax - Removes a scheduled fax from the queue.
# Unimplemented methods:
#  Delete_Pending_Fax - THIS DOESN'T EXIST - but is documented to exist.
module SrFax
  # Base URL for accessing SRFax API
  BASE_URL = 'https://www.srfax.com/SRF_SecWebSvc.php'.freeze

  mattr_accessor :defaults
  # Default values hash to use with all #execute commands
  @@defaults = {
    access_id: '1234',
    access_pwd: 'password',
    sFaxFormat: 'PDF', # Default format, PDF or TIF
    sCallerID: '5555555555', # MUST be 10 digits
    sResponseFormat: 'JSON' # XML or JSON
  }

  mattr_accessor :connection_defaults
  # Default values to use with the RestClient connection
  @@connection_defaults = {
    timeout: 180
  }

  mattr_accessor :logger
  # Logger object for use in standalone mode or with Rails
  if defined?(Rails)
    @@logger = Rails.logger
  else
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO
  end

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
    #     config.defaults[:sCallerID] = '5555555555'
    #   end
    def setup
      yield self
    end

    # Views the remote inbox. By default this call does NOT update the viewed
    # or read status of the fax unless specified in options.
    #
    # @param status [String] Specify the status of the message you are listing (UNREAD, ALL, READ)
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sPeriod Specify the period to query. Accepts 'ALL' or 'RANGE'
    # @option options [String] :sStatDate Used with :sPeriod and denotes the period to start at. Format is 'YYYYMMDD'
    # @option options [String] :sEndDate Used with :sPeriod and denotes the period to endd at. Format is 'YYYYMMDD'
    # @option options [String] :sIncludeSubUsers Include subuser accounts ('Y' or 'N')
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    #
    # Example Payload for Return:
    #   {"Status"=>"Success", "Result"=>[{"FileName"=>"20150430124505-6104-19_1|20360095", "ReceiveStatus"=>"Ok",
    #   "Date"=>"Apr 30/15 02:45 PM", "EpochTime"=>1430423105, "CallerID"=>"5555555555", "RemoteID"=>"", "Pages"=>"1",
    #   "Size"=>"5000", "ViewedStatus"=>"N"} ]}
    def view_inbox(status = 'UNREAD', options = {})
      logger.debug 'Checking fax inbox from cloud service'
      postVariables = {
        action: 'Get_Fax_Inbox',
        sViewedStatus: status.upcase
      }.merge!(options)
      res = execute(postVariables)

      if res[:Status] != 'Failure'
        faxcount = res['Result'].count
        faxcount > 0 ? logger.debug("Found #{faxcount} new fax(es)") : logger.debug('No faxes found matching that criteria')
      end

      res
    end

    # Uses post Get_Usage to fetch the current account usage statistics (for all associated accounts)
    #
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sPeriod Specify the period to query. Accepts 'ALL' or 'RANGE'
    # @option options [String] :sStatDate Used with :sPeriod and denotes the period to start at. Format is 'YYYYMMDD'
    # @option options [String] :sEndDate Used with :sPeriod and denotes the period to endd at. Format is 'YYYYMMDD'
    # @option options [String] :sIncludeSubUsers Include subuser accounts ('Y' or 'N')
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    #
    # Example Payload for Return:
    #   {"Status"=>"Success", "Result"=>[{"UserID"=>1234, "Period"=>"ALL",
    #   "ClientName"=>nil, "SubUserID"=>0, "BillingNumber"=>"8888888888", "NumberOfFaxes"=>5, "NumberOfPages"=>8}]}
    def view_usage(_options = {})
      logger.debug 'Viewing fax usage from cloud service'
      postVariables = { action: 'Get_Fax_Usage' }
      res = execute(postVariables)
      res
    end

    # Uses post Get_Fax_Outbox to retrieve the usage for the account (and all subaccounts)
    #
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sPeriod Specify the period to query. Accepts 'ALL' or 'RANGE'
    # @option options [String] :sStatDate Used with :sPeriod and denotes the period to start at. Format is 'YYYYMMDD'
    # @option options [String] :sEndDate Used with :sPeriod and denotes the period to endd at. Format is 'YYYYMMDD'
    # @option options [String] :sIncludeSubUsers Include subuser accounts ('Y' or 'N')
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    def view_outbox(_options = {})
      logger.debug 'Viewing fax outbox from cloud service'
      postVariables = { action: 'Get_Fax_Outbox' }
      res = execute(postVariables)

      if res[:Status] != 'Failure'
        faxcount = res['Result'].count
        faxcount > 0 ? logger.debug("Found #{faxcount} new fax(es)") : logger.debug('No faxes found matching that criteria')
      end

      res
    end

    # Uses POST Retrieve_Fax to retrieve a specified fax from the server. Returns it in the default
    # specified format (PDF or TIFF)
    #
    # @param descriptor [String] Specify the status of the message you are listing (UNREAD, ALL, READ)
    # @param direction [String] Either 'IN' or 'OUT' to specify the inbox or outbox
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sMarkasViewed Update the fax status to viewed (or unviewed). Accepts 'Y' or 'N'
    # @option options [String] :sFaxFormat Update the format to retrieve the file in ('PDF' or 'TIFF')
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    def get_fax(descriptor, direction, options = {})
      logger.debug "Retrieving fax from cloud service in the direction of '#{direction}', Descriptor: '#{descriptor}'"
      faxname, faxid = descriptor.split('|')
      if faxname.nil? || faxid.nil?
        logger.debug "Valid descriptor not provided to get_fax function call. Descriptor: '#{descriptor}'"
        return nil
      end

      logger.debug 'Retrieving fax from cloud service'
      postVariables = {
        action: 'Retrieve_Fax',
        sFaxFileName: descriptor,
        sFaxDetailsID: faxid,
        sDirection: direction.upcase,
        sMarkasViewed: 'N'
      }.merge!(options)
      res = execute(postVariables)
      res
    end

    # Update the status (read/unread) for a particular fax
    #
    # @param descriptor [String] Specify the status of the message you are listing (UNREAD, ALL, READ)
    # @param direction [String] Either 'IN' or 'OUT' to specify the inbox or outbox
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sMarkasViewed Update the fax status to viewed (or unviewed). Accepts 'Y' or 'N'. Defaults to Y
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    def update_fax_status(descriptor, direction, options = {})
      logger.debug "Updating a fax in the cloud service in the direction of '#{direction}', Descriptor: '#{descriptor}'"
      faxname, faxid = descriptor.split('|')
      if faxname.nil? || faxid.nil?
        logger.debug "Valid descriptor not provided to get_fax function call. Descriptor: '#{descriptor}'"
        return nil
      end

      postVariables = {
        action: 'Update_Viewed_Status',
        sFaxFileName: descriptor,
        sFaxDetailsID: faxid,
        sDirection: direction.upcase,
        sMarkasViewed: 'Y'
      }.merge!(options)
      res = execute(postVariables)
      res
    end

    # Schedules a fax to be sent with or without cover page
    #
    # @param faxids [String, Array] Get the state of 'id' as given by the #queue_fax call
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sResponseFormat The output response format for
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    def get_fax_status(faxids, options = {})
      logger.debug "Gathering fax status information for id(s): '#{faxids}'"

      if faxids.is_a? String
        action = 'Get_FaxStatus'
      elsif faxids.is_a? Array
        action = 'Get_MultiFaxStatus'
        faxids = faxids.join('|')
      else
        logger.warn "Error wth fax ids parameter id(s): '#{faxid}'"
        return { Status: 'Failure' }
      end

      postVariables = {
        action: action,
        sFaxDetailsID: faxids
      }.merge!(options)
      res = execute(postVariables)
      res
    end

    # Determines the state of a fax that has been scheduled for delivery. Use queue fax to schedule a fax
    # for delivery. Note: no validation is done on the fields prior to sending.
    #
    # @param senderEmail [String] Email address of the sender
    # @param receiverNumber [String, Array] Single 11 digit fax number or up to 50 x 11 fax numbers
    # @param faxType [String] 'SINGLE' or 'BROADCAST'
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID)
    # @option options [String] :sResponseFormat The output response format for
    # @option options [String] :sAccountCode Internal reference number (Max of 20 Characters)
    # @option options [String] :sRetries Number of times the system is to retry a number if busy or an error is encountered – number from 0 to 6.
    # @option options [String] :sCoverPage If you want to use one of the cover pages on file, specify the cover page you wish to use “Basic”, “Standard” , “Company” or “Personal”. If a cover page is not provided then all cover page variable will be ignored. NOTE: If the default cover page on the account is set to “Attachments ONLY” the cover page will NOT be created irrespective of this variable.
    # @option options [String] :sFaxFromHeader From: On the Fax Header Line (max 30 Char)
    # @option options [String] :sCPFromName Sender’s name on the Cover Page
    # @option options [String] :sCPToName Recipient’s name on the Cover Page
    # @option options [String] :sCPOrganization Organization on the Cover Page
    # @option options [String] :sCPSubject Subject line on the Cover Page**
    # @option options [String] :sCPComments Comments placed in the body of the Cover Page
    # @option options [String] :sFileName_x (See supported file types @  https://www.srfax.com/faqs)
    # @option options [String] :sFileContent_x Base64 encoding of file contents.
    # @option options [String] :sNotifyURL Provide an absolute URL (beginning with http:// or https://) and the SRFax system will POST back the fax status record when the fax completes. See the ‘NOTIFY URL POST’ section below for details of what is posted.
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    #
    # Example code (this will send a fax with 'Sample Fax' as the fileContent field):
    #   SrFax.queue_fax "yourname@yourdomain.com", "SINGLE", "18888888888", {sFileName_1: "file1.txt", sFileContent_1: Base64.encode64("Sample Fax")}
    def queue_fax(senderEmail, receiverNumber, faxType, options = {})
      logger.debug 'Attempting to queue fax'
      receiverNumber = receiverNumber.join('|') if receiverNumber.is_a? Array

      postVariables = {
        action: 'Queue_Fax',
        sSenderEmail: senderEmail,
        sFaxType: faxType,
        sToFaxNumber: receiverNumber
      }.merge!(options)
      res = execute(postVariables)
      res
    end

    # Attempt to stop a fax from being delivered. See the result payload for possible conditions in fax status
    #
    # @param faxid [String] Stop fax with 'id' as given by the #queue_fax call.
    # @param options [Hash] An optional hash paramter to ovveride any default values (ie., Account ID).
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    def stop_fax(faxid, options = {})
      action = nil
      logger.debug "Sending stop fax command for id: '#{faxid}'"

      postVariables = {
        action: 'Stop_Fax',
        sFaxDetailsID: faxid
      }.merge!(options)
      res = execute(postVariables)
      res
    end

    # Delete a particular fax from the SRFax cloud service
    #
    # @param descriptor [String] THe descriptor provided by SRFax which identifies a unique fax
    # @param direction [String] Either 'IN' or 'OUT' to specify the inbox or outbox
    # @return [Hash] A hash containing the return value (Success/Failure) and the payload where applicable
    #
    # Example Payload for Return:
    #   {"Status"=>"Success", "Result"=>[{"FileName"=>"20150430124505-6104-19_1|20360095", "ReceiveStatus"=>"Ok",
    #   "Date"=>"Apr 30/15 02:45 PM", "EpochTime"=>1430423105, "CallerID"=>"5555555555", "RemoteID"=>"", "Pages"=>"1",
    #   "Size"=>"5000", "ViewedStatus"=>"N"} ]}
    def delete_fax(descriptor, direction)
      logger.debug "Deleting a fax in the cloud service in the direction of '#{direction}', Descriptor: '#{descriptor}'"
      faxname, faxid = descriptor.split('|')
      if faxname.nil? || faxid.nil?
        logger.debug "Valid descriptor not provided to get_fax function call. Descriptor: '#{descriptor}'"
        return nil
      end

      postVariables = {
        action: 'Delete_Fax',
        sFaxFileName_x: descriptor,
        sFaxDetailsID_x: faxid,
        sDirection: direction.upcase
      }
      res = execute(postVariables)
      res
    end

    private

    # Actually execute the RESTful post command to the #BASE_URL
    #
    # @param postVariables [String] The list of variables to apply in the POST body when executing the request.
    # @return [Hash] The hash payload value including a proper status. Will never return nil.
    def execute(postVariables)
      logger.debug postVariables.merge(defaults)
      # Redirect where necessary.
      res = RestClient::Request.execute(
        method: :post, url: BASE_URL,
        payload: postVariables.merge(defaults).to_json,
        timeout: connection_defaults[:timeout],
        open_timeout: connection_defaults[:timeout],
        headers: { accept: :json }
      ) do |response, request, result, &block|
        if [301, 302, 307].include? response.code
          response.follow_redirection(request, result, &block)
        elsif [200].include? response.code
          # default behaviour for OK requests
          response.return!(request, result, &block)
        else
          # suppress the throw's by RestClient
          response = Oj.dump({ 'Status' => 'Failure', 'Result' => response.to_s }, mode: :compat)
        end
      end

      return_data = nil
      return_data = !res.nil? ? JSON.parse(res) : nil

      if return_data.nil? || return_data.fetch('Status', 'Failure') != 'Success'
        logger.debug 'Execution of SR Fax command not successful'
        return_data = { Status: 'Failure', Result: return_data.fetch('Result', '') }
      end

      return_data.with_indifferent_access
    end
  end
end
