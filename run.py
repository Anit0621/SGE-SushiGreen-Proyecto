from flask import Flask, render_template, Blueprint, request, url_for, redirect
from app.routes.clientes import cliente_bp
from app.routes.clientes import *
app = Flask(__name__)


app.register_blueprint(cliente_bp, url_prefix='/clientes')

@app.route('/',methods=["GET"])
def home():
    return render_template("inicio.html")


if __name__ == '__main__':
    app.run(debug=True)


