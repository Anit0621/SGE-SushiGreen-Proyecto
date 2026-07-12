from flask import Flask, render_template
from app.routes.clientes import cliente_bp
app = Flask(__name__)

app.register_blueprint(cliente_bp, url_prefix='/clientes')

@app.route('/')
def home():
    return 'Hello World!'

if __name__ == '__main__':
    app.run(debug=True)


