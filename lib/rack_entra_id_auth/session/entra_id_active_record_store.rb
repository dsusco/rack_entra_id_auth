require 'active_record/session_store'

module RackEntraIdAuth
  module Session
    class EntraIdActiveRecordStore < ActionDispatch::Session::ActiveRecordStore
      private

        def write_session(request, sid, session_data, options)
          entra_id_request = EntraIdRequest.new(request)

          logger.silence do
            record, sid = get_session_model(request, sid)
            record.data = session_data

            if entra_id_request.login_response?
              # store the sessionindex for IdP initiated single logout requests
              auth_response = entra_id_request.saml_auth_response()

              record.sessionindex = auth_response.sessionindex
            end

            return false unless record.save

            session_data = record.data
            if session_data && session_data.respond_to?(:each_value)
              session_data.each_value do |obj|
                obj.clear_association_cache if obj.respond_to?(:clear_association_cache)
              end
            end

            sid
          end
        end

        def delete_session(request, session_id, options)
          entra_id_request = EntraIdRequest.new(request)

          logger.silence do
            if entra_id_request.logout_request?
              # delete all the sessions with sessionindexes declared in the IdP
              # initiated single logout request
              logout_request = entra_id_request.saml_logout_request()
              sessions = session_class.where(sessionindex: logout_request.session_indexes)
              data = sessions.last.data rescue ''
              sessions.destroy_all
            elsif sid = current_session_id(request)
              if model = get_session_with_fallback(sid)
                data = model.data
                model.destroy
              end
            end

            request.env[SESSION_RECORD_KEY] = nil

            unless options[:drop]
              new_sid = generate_sid

              if options[:renew]
                new_model = session_class.new(:session_id => new_sid.private_id, :data => data)
                new_model.save
                request.env[SESSION_RECORD_KEY] = new_model
              end
              new_sid
            end
          end
        end

    end
  end
end
