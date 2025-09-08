from flask import Flask, jsonify, request
import random

app = Flask(__name__)

# 假資料的 barcode 列表
barcodes = ["MD0625000003", "MD0625000004", "MD0625000005"]

# 控制每個 barcode 是否上傳
barcode_status = {code: True for code in barcodes}

@app.route("/data/<barcode>")
def get_data_barcode(barcode):
    if barcode not in barcodes:
        return jsonify({"error": "Barcode not found"}), 404
    if not barcode_status.get(barcode, False):
        return jsonify({"error": "Barcode offline"}), 403

    chg_status = random.choice(["CHG", "DISCHG"])
    
    data = {
        "voltage": round(random.uniform(50, 60), 2),
        "current": round(random.uniform(0, 10), 2),
        "temp": round(random.uniform(20, 40), 1),
        "chgday": round(random.uniform(0, 100), 1),
        "dsgday": round(random.uniform(0, 100), 1),
        "chgmounth": round(random.uniform(0, 500), 1),
        "dsgmounth": round(random.uniform(0, 500), 1),
        "status": chg_status
    }
    return jsonify({barcode: data})

# 控制單個 barcode 上傳狀態
@app.route("/control_barcode", methods=["POST"])
def control_barcode():
    payload = request.json
    code = payload.get("barcode")
    status = payload.get("online")
    if code in barcodes and isinstance(status, bool):
        barcode_status[code] = status
        return jsonify({"message": f"Barcode {code} online set to {status}"})
    return jsonify({"error": "Invalid payload or barcode"}), 400

@app.route("/check/<barcode>")
def check_barcode(barcode):
    if barcode in barcodes:
        return jsonify({"exists": True})
    else:
        return jsonify({"exists": False})

@app.route("/status/<barcode>")
def get_status(barcode):
    if barcode in barcodes:
        # 回傳這個 barcode 是否上線
        return jsonify({"online": barcode_status.get(barcode, False)})
    else:
        # barcode 不存在
        return jsonify({"error": "Barcode not found"}), 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
