#!/usr/bin/env python3
"""Exporta CIE-11 MMS 2026-01 en español a un JSON local para Flutter.

Requiere:
  export WHO_ICD_CLIENT_ID="..."
  export WHO_ICD_CLIENT_SECRET="..."
  python3 -m pip install requests
"""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path
from typing import Any

import requests

TOKEN_URL = "https://icdaccessmanagement.who.int/connect/token"
ROOT_URL = "https://id.who.int/icd/release/11/2026-01/mms"
OUTPUT = Path(
    "assets/data/icd11_es_2026_01.json"
)

CLIENT_ID = os.environ.get("WHO_ICD_CLIENT_ID", "").strip()
CLIENT_SECRET = os.environ.get("WHO_ICD_CLIENT_SECRET", "").strip()

if not CLIENT_ID or not CLIENT_SECRET:
    raise SystemExit(
        "Faltan WHO_ICD_CLIENT_ID y WHO_ICD_CLIENT_SECRET."
    )


def get_token() -> str:
    response = requests.post(
        TOKEN_URL,
        data={
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "scope": "icdapi_access",
            "grant_type": "client_credentials",
        },
        timeout=60,
    )
    response.raise_for_status()
    return response.json()["access_token"]


token = get_token()
session = requests.Session()
session.headers.update(
    {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Accept-Language": "es",
        "API-Version": "v2",
    }
)


def api_url(uri: str) -> str:
    if uri.startswith("http://id.who.int/"):
        return "https://" + uri[len("http://") :]
    return uri


def localized_text(value: Any) -> str:
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, dict):
        raw = value.get("@value") or value.get("label") or ""
        return str(raw).strip()
    return ""


def request_json(uri: str) -> dict[str, Any]:
    global token

    url = api_url(uri)

    for attempt in range(5):
        response = session.get(url, timeout=60)

        if response.status_code == 401:
            token = get_token()
            session.headers["Authorization"] = f"Bearer {token}"
            continue

        if response.status_code == 429:
            time.sleep(2 ** attempt)
            continue

        response.raise_for_status()
        return response.json()

    raise RuntimeError(f"No se pudo consultar {url}")


visited: set[str] = set()
entries: list[dict[str, Any]] = []
pending: list[str] = [ROOT_URL]

while pending:
    uri = pending.pop()

    if uri in visited:
        continue

    visited.add(uri)
    entity = request_json(uri)

    children = entity.get("child") or []
    if isinstance(children, str):
        children = [children]

    for child in children:
        if isinstance(child, str) and child not in visited:
            pending.append(child)

    code = str(entity.get("code") or "").strip()
    title = localized_text(entity.get("title"))

    if code and title:
        entity_id = str(entity.get("@id") or uri)
        entries.append(
            {
                "id": entity_id,
                "primarySystem": "icd11",
                "primaryCode": code,
                "description": title,
                "icd10Code": "",
                "snomedCtCode": "",
                "icpc2Code": "",
                "terminologyVersion": "CIE-11 MMS 2026-01",
                "status": "active",
                "origin": "selfRecord",
                "diagnosisDate": None,
                "notes": "",
            }
        )

    if len(visited) % 500 == 0:
        print(
            f"Procesados: {len(visited)} | "
            f"Códigos: {len(entries)}",
            flush=True,
        )

entries.sort(key=lambda item: item["primaryCode"])

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text(
    json.dumps(
        {
            "source": "WHO ICD-11 MMS",
            "release": "2026-01",
            "language": "es",
            "generated": True,
            "entries": entries,
        },
        ensure_ascii=False,
        separators=(",", ":"),
    ),
    encoding="utf-8",
)

print(f"Catálogo creado: {OUTPUT}")
print(f"Diagnósticos exportados: {len(entries)}")
