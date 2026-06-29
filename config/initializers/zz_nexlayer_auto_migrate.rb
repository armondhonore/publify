# Nexlayer: ensure the database schema exists on boot.
#
# The Nexlayer pipeline may generate a Dockerfile whose CMD starts the web
# server directly (no `rake db:prepare`). To guarantee the app boots against a
# ready schema, we load/migrate the schema once during initialization in
# production. This is idempotent and safe to run on every boot.
if Rails.env.production? && ENV["NEXLAYER_SKIP_AUTO_MIGRATE"].nil?
  Rails.application.config.after_initialize do
    begin
      conn = ActiveRecord::Base.connection
      needs_setup =
        begin
          !conn.data_source_exists?("schema_migrations") ||
            ActiveRecord::Base.connection.migration_context.needs_migration?
        rescue StandardError
          true
        end

      if needs_setup
        Rails.logger.info("[nexlayer] preparing database (load_schema_if_pending / migrate)")
        if conn.tables.empty? && File.exist?(Rails.root.join("db", "schema.rb"))
          load Rails.root.join("db", "schema.rb")
        end
        ActiveRecord::Tasks::DatabaseTasks.migrate
      end
    rescue StandardError => e
      # Never let migration issues prevent the process from booting; log and
      # continue so the platform health probe can still reach the app.
      Rails.logger.error("[nexlayer] auto-migrate failed: #{e.class}: #{e.message}")
    end
  end
end
