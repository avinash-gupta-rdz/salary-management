# Serves the React app shell for any non-API page (e.g. /employees/42), so
# client-side routes survive a page refresh.
#
# Deliberately not an ApplicationController: the shell (with its login screen)
# must load before the user has signed in. It contains no data.
class FrontendController < ActionController::API
  INDEX_PATH = Rails.root.join("public/app.html")

  def index
    return render(plain: "Frontend not built. Run bin/build-frontend.", status: :not_found) unless INDEX_PATH.exist?

    # The shell must never be cached, or browsers keep loading old asset
    # filenames after a deploy. The hashed files in /assets are cached long-term.
    response.headers["Cache-Control"] = "no-cache"
    send_file INDEX_PATH, type: "text/html", disposition: "inline"
  end
end
