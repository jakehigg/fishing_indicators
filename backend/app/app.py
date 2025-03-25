from flask import Flask, request
from flask_cors import CORS
from lambda_app import lambda_handler


app = Flask(__name__)
CORS(app)


@app.after_request
def add_header(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    return response


@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def catch_all(path):
    lambda_path = f"/{path.split('/')[-1]}"
    if lambda_path != "/favicon.ico":
        print(f"Path: {lambda_path}")
        print(f"Request: {request.query_string}")
        event = {
            "path": lambda_path,
            "httpMethod": request.method,
            "queryStringParameters": request.args.to_dict(),
        }
        retval = lambda_handler(event, "here")
        return retval["body"], retval["statusCode"]

    return "Not Found", 404
