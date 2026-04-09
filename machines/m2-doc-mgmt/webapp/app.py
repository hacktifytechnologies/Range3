#!/usr/bin/env python3
"""
AETHON Defense Systems — Internal Document Management System
Machine 2: aethon-docs
Vulnerability: Server-Side Template Injection (SSTI) in Jinja2
"""

from flask import Flask, render_template, render_template_string, request, session, redirect, url_for, jsonify
import os
import hashlib
import datetime

app = Flask(__name__)
app.secret_key = os.urandom(32)

# Hardcoded credentials for the internal system
USERS = {
    "admin": "Aethon@D0cs#2024",
    "docreader": "R3aderP@ss!"
}

DOCUMENTS = [
    {"id": "DOC-001", "title": "F-INSAS Exoskeleton — Maintenance Manual Rev.4", "classification": "RESTRICTED", "owner": "engineering", "date": "2024-08-12"},
    {"id": "DOC-002", "title": "PGM-7 Terminal Guidance Algorithm — Design Spec", "classification": "SECRET", "owner": "r_and_d", "date": "2024-09-01"},
    {"id": "DOC-003", "title": "BMS-X Encryption Key Management Procedure", "classification": "TOP SECRET", "owner": "cybersec", "date": "2024-07-22"},
    {"id": "DOC-004", "title": "Q3 Supply Chain Audit Report — AETHON", "classification": "CONFIDENTIAL", "owner": "procurement", "date": "2024-10-05"},
    {"id": "DOC-005", "title": "F-INSAS Biometric Subsystem Integration Guide", "classification": "RESTRICTED", "owner": "engineering", "date": "2024-09-18"},
    {"id": "DOC-006", "title": "Procurement Vendor Onboarding SOP v2.1", "classification": "INTERNAL", "owner": "procurement", "date": "2024-06-30"},
    {"id": "DOC-007", "title": "PGM-7 Test Range Data — Lot 2024-C", "classification": "SECRET", "owner": "r_and_d", "date": "2024-10-11"},
    {"id": "DOC-008", "title": "AETHON Network Architecture Diagram — DMZ + Private", "classification": "CONFIDENTIAL", "owner": "it_infra", "date": "2024-08-28"},
]


def login_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get('logged_in'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated


@app.route('/', methods=['GET'])
@login_required
def index():
    return render_template('index.html', docs=DOCUMENTS, user=session.get('username'))


@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        username = request.form.get('username', '')
        password = request.form.get('password', '')
        if username in USERS and USERS[username] == password:
            session['logged_in'] = True
            session['username'] = username
            return redirect(url_for('index'))
        else:
            error = "Invalid credentials. Access denied."
    return render_template('login.html', error=error)


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


@app.route('/search')
@login_required
def search():
    # VULNERABILITY: user-controlled input passed directly to render_template_string
    query = request.args.get('q', '')
    docs = [d for d in DOCUMENTS if query.lower() in d['title'].lower()] if query else []

    # This is the SSTI sink — the query is rendered as a Jinja2 template
    # An attacker can inject: {{ ''.__class__.__mro__[1].__subclasses__() }}
    # or: {{ self._TemplateReference__context.cycler.__init__.__globals__.os.popen('id').read() }}
    result_header = render_template_string(
        "<p class='search-info'>Searching documents for: <strong>" + query + "</strong></p>"
    )

    return render_template('search.html',
                           query=query,
                           docs=docs,
                           result_header=result_header,
                           user=session.get('username'))


@app.route('/api/doc/<doc_id>')
@login_required
def get_doc(doc_id):
    doc = next((d for d in DOCUMENTS if d['id'] == doc_id), None)
    if not doc:
        return jsonify({"error": "Document not found"}), 404
    return jsonify(doc)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
