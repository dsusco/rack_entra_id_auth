require 'active_support/core_ext/object/blank'
require 'ruby-saml'

module RackEntraIdAuth
  class Configuration
    RUBY_SAML_SETTINGS = %i(
      idp_entity_id
      idp_sso_service_url
      idp_slo_service_url
      idp_slo_response_service_url
      idp_cert
      idp_cert_fingerprint
      idp_cert_fingerprint_algorithm
      idp_cert_multi
      idp_attribute_names
      idp_name_qualifier
      valid_until
      sp_entity_id
      assertion_consumer_service_url
      single_logout_service_url
      sp_name_qualifier
      name_identifier_format
      name_identifier_value
      name_identifier_value_requested
      sessionindex
      compress_request
      compress_response
      double_quote_xml_attribute_values
      message_max_bytesize
      passive
      attributes_index
      force_authn
      certificate
      private_key
      sp_cert_multi
      authn_context
      authn_context_comparison
      authn_context_decl_ref
      security
      soft
    )

    DEFAULTS = {
      exclude_paths: [],
      login_path: '/login',
      logout_path: '/logout',
      # mock_server must be set in `config/application.rb` or an environment-
      # specific configuration file. I.e. it must happen before initializers as
      # it's used in the initializer created in the Railtie.
      mock_server: true,
      mock_attributes: {},
      session_key: :entra_id,
      session_value_proc: Proc.new { |attributes|
        attributes.inject({}) do |memo, (key, value)|
          key = key.split('/').last
          value = value.first if value.kind_of?(Array) and value.length.eql?(1) and !key.eql?('groups')
          memo[key] = value
          memo
        end
      },
      skip_single_logout: true,
    }.freeze

    attr_accessor(*RUBY_SAML_SETTINGS, *DEFAULTS.keys, :login_relay_state_url, :logout_relay_state_url)
    attr_reader :metadata_url

    def initialize
      DEFAULTS.each { |key, value| public_send("#{key}=", value.dup) }
    end

    def configuration_options (configuration_options = {})
      configuration_options.slice(:metadata_url, *RUBY_SAML_SETTINGS).each do |key, value|
        self.send("#{key}=", value) unless value.nil?
      end
    end

    def metadata_url= (metadata_url)
      @metadata_url = metadata_url

      OneLogin::RubySaml::IdpMetadataParser.new.parse_remote_to_hash(metadata_url)
        .slice(*RUBY_SAML_SETTINGS).each do |key, value|
          self.send("#{key}=", value) unless value.nil?
        end

      @metadata_url
    end

    def ruby_saml_settings
      RUBY_SAML_SETTINGS.to_h { |key| [key, public_send(key)] }.compact
    end
  end
end
