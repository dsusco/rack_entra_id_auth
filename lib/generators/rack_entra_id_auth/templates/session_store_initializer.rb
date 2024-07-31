require 'rack_entra_id_auth/session/entra_id_active_record_store'

Rails.application.config.session_store RackEntraIdAuth::Session::EntraIdActiveRecordStore, :key => "_#{File.basename(Rails.root)}_session"
