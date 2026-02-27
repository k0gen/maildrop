import os
from flask import Flask
from .routes import pages, api

# Absoluth paths – required in Nuitka onefile (unpacking to /tmp)
_base = os.path.dirname(os.path.abspath(__file__))
_template_dir = os.path.normpath(os.path.join(_base, "..", "frontend", "templates"))
_static_dir = os.path.normpath(os.path.join(_base, "..", "frontend", "static"))

app = Flask(__name__, template_folder=_template_dir, static_folder=_static_dir)

app.register_blueprint(pages.bp) # load the blueprint for the all of the main web page routes
app.register_blueprint(api.bp) # load the blueprint for the all of the api routes

# Runs the main flask app
def run_flask_server(host, port):
    app.run(host=host, port=port, debug=False)