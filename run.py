from flask import Flask, render_template, Blueprint, request, url_for, redirect
from app.routes.productos import producto_bp
app = Flask(__name__)


app.register_blueprint(producto_bp, url_prefix='/productos')

@app.route('/',methods=["GET"])
def home():
    return render_template("inicio.html")


if __name__ == '__main__':
    app.run(debug=True)


