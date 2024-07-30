module RackEntraIdAuth
  class Configuration
    include ActiveSupport::Configurable

    config_accessor :login_path, default: '/login'
    config_accessor :login_relay_state_url
    config_accessor :logout_path, default: '/logout'
    config_accessor :logout_relay_state_url
    # mock_server must be set in `config/application.rb` or an
    # environment-specific configuration file. I.e. it must happen before
    # initializers as it's used in the initializer created in the Railtie.
    config_accessor :mock_server, default: true
    config_accessor :mock_attributes, default: {}
    config_accessor :session_key, default: :entra_id
    config_accessor :session_value_proc, default: Proc.new { |attributes|
      attributes.inject({}) do |memo, (key, value)|
        key = key.split('/').last
        value = value.first if value.kind_of?(Array) and value.length.eql?(1) and !key.eql?('groups')
        memo[key] = value
        memo
      end
    }
    config_accessor :skip_single_logout, default: true

    # Ruby SAML ID Provider Settings
    config_accessor :idp_entity_id
    config_accessor :idp_sso_service_url
    config_accessor :idp_slo_service_url
    config_accessor :idp_slo_response_service_url
    config_accessor :idp_cert
    config_accessor :idp_cert_fingerprint
    config_accessor :idp_cert_fingerprint_algorithm
    config_accessor :idp_cert_multi
    config_accessor :idp_attribute_names
    config_accessor :idp_name_qualifier
    config_accessor :valid_until

    # Ruby SAML Service Provider Settings
    config_accessor :sp_entity_id
    config_accessor :assertion_consumer_service_url
    config_accessor :single_logout_service_url
    config_accessor :sp_name_qualifier
    config_accessor :name_identifier_format
    config_accessor :name_identifier_value
    config_accessor :name_identifier_value_requested
    config_accessor :sessionindex
    config_accessor :compress_request
    config_accessor :compress_response
    config_accessor :double_quote_xml_attribute_values
    config_accessor :message_max_bytesize
    config_accessor :passive
    config_accessor :attributes_index
    config_accessor :force_authn
    config_accessor :certificate
    config_accessor :private_key
    config_accessor :sp_cert_multi
    config_accessor :authn_context
    config_accessor :authn_context_comparison
    config_accessor :authn_context_decl_ref

    # Ruby SAML workflow Settings
    config_accessor :security
    config_accessor :soft

    def ruby_saml_settings
      config.to_h.except(
        :login_path,
        :login_relay_state_url,
        :logout_path,
        :logout_relay_state_url,
        :mock_server,
        :mock_attributes,
        :session_key,
        :session_value_proc,
        :skip_single_logout)
    end
  end
end
