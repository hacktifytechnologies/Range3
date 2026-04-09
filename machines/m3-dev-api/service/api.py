#!/usr/bin/env python3
"""
AETHON Defense Systems — R&D Field Analyst API
Machine 3: aethon-dev
Vulnerability: Python Pickle Deserialization (Insecure Deserialization)
Port: 8080
"""

from flask import Flask, request, jsonify
import pickle
import base64
import os
import json
import hashlib
import datetime

app = Flask(__name__)

# Analyst profiles stored in memory (in production would use DB)
ANALYST_PROFILES = {
    "analyst01": {"name": "Capt. Arjun Mehta", "clearance": "SECRET", "division": "F-INSAS"},
    "analyst02": {"name": "Maj. Priya Sharma", "clearance": "TOP SECRET", "division": "PGM"},
    "sysadmin":  {"name": "DevOps Engineer", "clearance": "INTERNAL", "division": "IT"},
}

# API key check (weak — easily bypassable but provides a layer)
API_KEYS = {
    "dev-internal-2024-xK9mP": "analyst01",
    "rd-access-2024-nV3qR": "analyst02",
}


def verify_api_key(req):
    key = req.headers.get('X-API-Key', '')
    return key in API_KEYS


@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "service": "AETHON R&D Field Analyst API",
        "version": "1.3.2",
        "status": "operational",
        "endpoints": [
            "GET  /api/health",
            "GET  /api/analysts",
            "POST /api/load-profile   (X-API-Key required)",
            "GET  /api/telemetry      (X-API-Key required)"
        ]
    })


@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "timestamp": str(datetime.datetime.utcnow())})


@app.route('/api/analysts', methods=['GET'])
def list_analysts():
    if not verify_api_key(request):
        return jsonify({"error": "Unauthorized — X-API-Key header required"}), 401
    return jsonify({"analysts": list(ANALYST_PROFILES.keys())})


@app.route('/api/load-profile', methods=['POST'])
def load_profile():
    """
    Load analyst profile from serialized data.
    Accepts JSON: {"profile": "<base64-encoded-pickle>"}
    VULNERABILITY: directly deserializes pickle without sanitization
    """
    if not verify_api_key(request):
        return jsonify({"error": "Unauthorized — X-API-Key required"}), 401

    data = request.get_json(silent=True)
    if not data or 'profile' not in data:
        return jsonify({"error": "Missing 'profile' field in JSON body"}), 400

    try:
        # VULNERABLE: deserializing attacker-controlled pickle data
        serialized = base64.b64decode(data['profile'])
        profile_obj = pickle.loads(serialized)
        return jsonify({"status": "loaded", "data": str(profile_obj)})
    except Exception as e:
        return jsonify({"error": f"Failed to load profile: {str(e)}"}), 500


@app.route('/api/telemetry', methods=['GET'])
def telemetry():
    if not verify_api_key(request):
        return jsonify({"error": "Unauthorized"}), 401
    return jsonify({
        "uptime_seconds": int((datetime.datetime.utcnow() - datetime.datetime(2024, 1, 1)).total_seconds()),
        "api_calls_today": 142,
        "active_analysts": 2,
        "cache_backend": "redis",
        "cache_host": os.environ.get("REDIS_HOST", "aethon-cache"),
        "cache_port": int(os.environ.get("REDIS_PORT", "6379")),
        "note": "Cache host read from environment — see /opt/aethon-api/config.ini"
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
