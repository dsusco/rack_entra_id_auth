module RackEntraIdAuth
  class MockMiddleware
    def initialize (app)
      @app = app
    end

    def call (env)
      @app.call(env)
    end
  end
end
